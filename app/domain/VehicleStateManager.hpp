#pragma once

#include "VehicleState.hpp"
#include "FaultModel.hpp"
#include "vehicle/VehicleDataInterface.hpp"
#include <algorithm>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace driveos::domain {

/**
 * @brief Application domain state manager for vehicle operational lifecycle and kinematics.
 * 
 * Provides the single source of truth for:
 * - Operational states: PARKED, DRIVING, REVERSE, CHARGING, FAULT
 * - Powertrain kinematics: speed, gear, drive mode
 * - Energy and closures: battery SOC, door positions, lock status
 * - Communication health: HEALTHY, DEGRADED, DISCONNECTED, BUS_OFF
 * 
 * Manages thread-safe state transitions and multi-observer notification callbacks,
 * decoupling domain presentation from underlying hardware or simulation backends.
 */
class VehicleStateManager {
public:
    using StateChangedCallback = std::function<void(const VehicleState&)>;
    using OperationalStateCallback = std::function<void(OperationalState)>;
    using HealthCallback = std::function<void(vehicle::CommunicationHealth)>;
    using FaultCallback = std::function<void(const FaultRecord&)>;

    explicit VehicleStateManager(vehicle::VehicleDataInterface* vdi = nullptr)
        : m_vdi(vdi)
    {
        if (m_vdi) {
            m_currentState = m_vdi->getVehicleState();
            m_health = m_vdi->getCommunicationHealth();

            m_vdi->registerStateCallback([this](const VehicleState& state) {
                updateStateFromBackend(state);
            });

            m_vdi->registerHealthCallback([this](vehicle::CommunicationHealth health) {
                updateHealthFromBackend(health);
            });

            m_vdi->registerFaultCallback([this](const FaultRecord& fault) {
                recordFault(fault);
            });
        }
    }

    virtual ~VehicleStateManager() = default;

    // --- State Accessors (Single Source of Truth) ---
    [[nodiscard]] virtual VehicleState getVehicleState() const {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_vdi) {
            auto vdiState = m_vdi->getVehicleState();
            // Sync external changes (e.g. simulated clock step, mock updates)
            if (vdiState.speed != m_currentState.speed ||
                vdiState.operationalState != m_currentState.operationalState ||
                vdiState.gear != m_currentState.gear ||
                vdiState.driveMode != m_currentState.driveMode ||
                vdiState.batterySoc != m_currentState.batterySoc) {
                m_currentState = vdiState;
            }
        }
        return m_currentState;
    }

    [[nodiscard]] virtual OperationalState getOperationalState() const {
        return getVehicleState().operationalState;
    }

    [[nodiscard]] virtual DriveMode getDriveMode() const {
        return getVehicleState().driveMode;
    }

    [[nodiscard]] virtual Gear getGear() const {
        return getVehicleState().gear;
    }

    [[nodiscard]] virtual float getSpeed() const {
        return getVehicleState().speed;
    }

    [[nodiscard]] virtual float getBatterySoc() const {
        return getVehicleState().batterySoc;
    }

    [[nodiscard]] virtual float getRangeKm() const {
        return getVehicleState().rangeKm;
    }

    [[nodiscard]] virtual vehicle::CommunicationHealth getCommunicationHealth() const {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_vdi && m_health == vehicle::CommunicationHealth::HEALTHY) {
            return m_vdi->getCommunicationHealth();
        }
        return m_health;
    }

    [[nodiscard]] virtual bool isDegraded() const {
        std::lock_guard<std::mutex> lock(m_mutex);
        return m_health != vehicle::CommunicationHealth::HEALTHY ||
               m_currentState.operationalState == OperationalState::FAULT;
    }

    [[nodiscard]] virtual bool hasFault() const {
        std::lock_guard<std::mutex> lock(m_mutex);
        return m_currentState.operationalState == OperationalState::FAULT ||
               m_health == vehicle::CommunicationHealth::BUS_OFF;
    }

    // --- State Transitions & Commands ---
    virtual bool setOperationalState(OperationalState newState) {
        OperationalState op;
        Gear g;
        float spd;
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            if (m_currentState.operationalState == newState) {
                return true;
            }

            m_currentState.operationalState = newState;
            switch (newState) {
            case OperationalState::PARKED:
                m_currentState.gear = Gear::PARK;
                m_currentState.speed = 0.0f;
                m_currentState.chargingState = ChargingState::DISCONNECTED;
                break;
            case OperationalState::DRIVING:
                m_currentState.gear = Gear::DRIVE;
                if (m_currentState.speed < 0.1f) {
                    m_currentState.speed = 64.0f;
                }
                m_currentState.chargingState = ChargingState::DISCONNECTED;
                break;
            case OperationalState::REVERSE:
                m_currentState.gear = Gear::REVERSE;
                m_currentState.speed = 4.0f;
                m_currentState.chargingState = ChargingState::DISCONNECTED;
                break;
            case OperationalState::CHARGING:
                m_currentState.gear = Gear::PARK;
                m_currentState.speed = 0.0f;
                m_currentState.chargingState = ChargingState::CHARGING;
                break;
            case OperationalState::FAULT:
                m_currentState.gear = Gear::PARK;
                m_currentState.speed = 0.0f;
                break;
            }

            op = m_currentState.operationalState;
            g = m_currentState.gear;
            spd = m_currentState.speed;
        }

        if (m_vdi) {
            m_vdi->setOperationalState(op, g, spd);
        }

        notifyStateObservers();
        notifyOperationalStateObservers(newState);
        return true;
    }

    virtual bool setDriveMode(DriveMode mode) {
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            m_currentState.driveMode = mode;
        }
        if (m_vdi) {
            m_vdi->setDriveMode(mode);
        }
        notifyStateObservers();
        return true;
    }

    virtual bool setSpeed(float speedKmH) {
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            m_currentState.speed = std::clamp(speedKmH, 0.0f, 250.0f);
            if (m_currentState.speed > 0.1f) {
                m_currentState.operationalState = OperationalState::DRIVING;
                m_currentState.gear = Gear::DRIVE;
            } else if (m_currentState.operationalState == OperationalState::DRIVING) {
                m_currentState.operationalState = OperationalState::PARKED;
                m_currentState.gear = Gear::PARK;
            }
        }
        if (m_vdi) {
            m_vdi->setSpeed(speedKmH);
        }
        notifyStateObservers();
        return true;
    }

    virtual bool setDoorLock(bool locked) {
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            if (locked) {
                m_currentState.doors.frontLeftOpen = false;
                m_currentState.doors.frontRightOpen = false;
                m_currentState.doors.rearLeftOpen = false;
                m_currentState.doors.rearRightOpen = false;
            }
        }
        if (m_vdi) {
            m_vdi->setDoorLock(locked);
        }
        notifyStateObservers();
        return true;
    }

    virtual bool toggleDoor(const std::string& doorName) {
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            if (doorName == "FL" || doorName == "frontLeft") {
                m_currentState.doors.frontLeftOpen = !m_currentState.doors.frontLeftOpen;
            } else if (doorName == "FR" || doorName == "frontRight") {
                m_currentState.doors.frontRightOpen = !m_currentState.doors.frontRightOpen;
            } else if (doorName == "RL" || doorName == "rearLeft") {
                m_currentState.doors.rearLeftOpen = !m_currentState.doors.rearLeftOpen;
            } else if (doorName == "RR" || doorName == "rearRight") {
                m_currentState.doors.rearRightOpen = !m_currentState.doors.rearRightOpen;
            }
        }
        if (m_vdi) {
            m_vdi->toggleDoor(doorName);
        }
        notifyStateObservers();
        return true;
    }

    virtual void setCommunicationHealth(vehicle::CommunicationHealth health) {
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            m_health = health;
            if (health == vehicle::CommunicationHealth::BUS_OFF) {
                m_currentState.operationalState = OperationalState::FAULT;
            }
        }
        if (m_vdi && health == vehicle::CommunicationHealth::BUS_OFF) {
            m_vdi->setOperationalState(OperationalState::FAULT, Gear::PARK, 0.0f);
        }
        notifyHealthObservers(health);
        notifyStateObservers();
    }

    virtual void injectFault(const FaultRecord& fault) {
        recordFault(fault);
    }

    virtual bool setScenario(const std::string& scenario) {
        if (scenario == "PARKED") setOperationalState(OperationalState::PARKED);
        else if (scenario == "DRIVING") setOperationalState(OperationalState::DRIVING);
        else if (scenario == "REVERSE") setOperationalState(OperationalState::REVERSE);
        else if (scenario == "CHARGING") setOperationalState(OperationalState::CHARGING);
        else if (scenario == "FAULT") setOperationalState(OperationalState::FAULT);

        if (m_vdi) {
            m_vdi->setScenario(scenario);
        }
        return true;
    }

    virtual bool setFaultMode(const std::string& faultMode) {
        if (faultMode == "UNAVAILABLE" || faultMode == "UNAVAILABLE_DATA") {
            setCommunicationHealth(vehicle::CommunicationHealth::DISCONNECTED);
        } else if (faultMode == "STALE" || faultMode == "STALE_DATA") {
            setCommunicationHealth(vehicle::CommunicationHealth::DEGRADED);
        } else if (faultMode == "NONE") {
            setCommunicationHealth(vehicle::CommunicationHealth::HEALTHY);
        }

        if (m_vdi) {
            m_vdi->setFaultMode(faultMode);
        }
        return true;
    }

    // --- Multi-Observer Subscription Registration ---
    virtual void registerStateCallback(StateChangedCallback callback) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_stateCallbacks.push_back(std::move(callback));
    }

    virtual void registerOperationalStateCallback(OperationalStateCallback callback) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_opStateCallbacks.push_back(std::move(callback));
    }

    virtual void registerHealthCallback(HealthCallback callback) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_healthCallbacks.push_back(std::move(callback));
    }

    virtual void registerFaultCallback(FaultCallback callback) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_faultCallbacks.push_back(std::move(callback));
    }

private:
    void updateStateFromBackend(const VehicleState& state) {
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            m_currentState = state;
        }
        notifyStateObservers();
    }

    void updateHealthFromBackend(vehicle::CommunicationHealth health) {
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            m_health = health;
            if (health == vehicle::CommunicationHealth::BUS_OFF) {
                m_currentState.operationalState = OperationalState::FAULT;
            }
        }
        notifyHealthObservers(health);
        notifyStateObservers();
    }

    void recordFault(const FaultRecord& fault) {
        std::vector<FaultCallback> callbacksCopy;
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            m_activeFaults.push_back(fault);
            m_currentState.operationalState = OperationalState::FAULT;
            callbacksCopy = m_faultCallbacks;
        }
        if (m_vdi) {
            m_vdi->setOperationalState(OperationalState::FAULT, Gear::PARK, 0.0f);
        }
        for (const auto& cb : callbacksCopy) {
            if (cb) cb(fault);
        }
        notifyStateObservers();
    }

    void notifyStateObservers() {
        VehicleState stCopy;
        std::vector<StateChangedCallback> callbacksCopy;
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            stCopy = m_currentState;
            callbacksCopy = m_stateCallbacks;
        }
        for (const auto& cb : callbacksCopy) {
            if (cb) cb(stCopy);
        }
    }

    void notifyOperationalStateObservers(OperationalState state) {
        std::vector<OperationalStateCallback> callbacksCopy;
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            callbacksCopy = m_opStateCallbacks;
        }
        for (const auto& cb : callbacksCopy) {
            if (cb) cb(state);
        }
    }

    void notifyHealthObservers(vehicle::CommunicationHealth health) {
        std::vector<HealthCallback> callbacksCopy;
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            callbacksCopy = m_healthCallbacks;
        }
        for (const auto& cb : callbacksCopy) {
            if (cb) cb(health);
        }
    }

    mutable std::mutex m_mutex;
    vehicle::VehicleDataInterface* m_vdi{nullptr};
    mutable VehicleState m_currentState{};
    vehicle::CommunicationHealth m_health{vehicle::CommunicationHealth::HEALTHY};
    std::vector<FaultRecord> m_activeFaults;

    std::vector<StateChangedCallback> m_stateCallbacks;
    std::vector<OperationalStateCallback> m_opStateCallbacks;
    std::vector<HealthCallback> m_healthCallbacks;
    std::vector<FaultCallback> m_faultCallbacks;
};

} // namespace driveos::domain
