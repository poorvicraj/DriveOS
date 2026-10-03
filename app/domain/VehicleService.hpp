#pragma once

#include "VehicleState.hpp"
#include "VehicleStateManager.hpp"
#include "SafetyPolicy.hpp"
#include "FaultModel.hpp"
#include "vehicle/VehicleDataInterface.hpp"
#include <functional>
#include <memory>
#include <string>
#include <vector>

namespace driveos::domain {

/**
 * @brief Application domain service managing powertrain state, doors, and driving dynamics.
 * 
 * Centralizes vehicle command dispatch, safety policy validation, and coordinates with
 * the canonical VehicleStateManager and VehicleDataInterface (HAL).
 */
class VehicleService {
public:
    using StateChangedCallback = std::function<void(const VehicleState&)>;
    using SafetyWarningCallback = std::function<void(const std::string& reason)>;
    using HealthCallback = std::function<void(vehicle::CommunicationHealth)>;

    VehicleService(vehicle::VehicleDataInterface* vdi,
                   SafetyPolicy* safetyPolicy,
                   VehicleStateManager* stateManager = nullptr)
        : m_vdi(vdi)
        , m_safetyPolicy(safetyPolicy)
        , m_stateManager(stateManager)
    {
        if (!m_stateManager) {
            m_ownedStateManager = std::make_unique<VehicleStateManager>(m_vdi);
            m_stateManager = m_ownedStateManager.get();
        }

        if (m_safetyPolicy && m_stateManager) {
            m_safetyPolicy->setStateManager(m_stateManager);
        }

        if (m_stateManager) {
            m_stateManager->registerStateCallback([this](const VehicleState& state) {
                notifyStateChanged(state);
            });
            m_stateManager->registerHealthCallback([this](vehicle::CommunicationHealth health) {
                notifyHealthChanged(health);
            });
        }
    }

    virtual ~VehicleService() = default;

    [[nodiscard]] virtual VehicleState getVehicleState() const {
        if (m_stateManager) {
            return m_stateManager->getVehicleState();
        }
        if (m_vdi) {
            return m_vdi->getVehicleState();
        }
        return m_fallbackState;
    }

    [[nodiscard]] virtual vehicle::CommunicationHealth getHealth() const {
        if (m_stateManager) {
            return m_stateManager->getCommunicationHealth();
        }
        if (m_vdi) {
            return m_vdi->getCommunicationHealth();
        }
        return vehicle::CommunicationHealth::DISCONNECTED;
    }

    [[nodiscard]] virtual vehicle::CommunicationHealth getCommunicationHealth() const {
        return getHealth();
    }

    [[nodiscard]] virtual bool isDegraded() const {
        if (m_stateManager) {
            return m_stateManager->isDegraded();
        }
        return getHealth() != vehicle::CommunicationHealth::HEALTHY;
    }

    [[nodiscard]] virtual bool hasFault() const {
        if (m_stateManager) {
            return m_stateManager->hasFault();
        }
        return getVehicleState().operationalState == OperationalState::FAULT;
    }

    [[nodiscard]] virtual VehicleStateManager* getStateManager() const noexcept {
        return m_stateManager;
    }

    virtual bool setDriveMode(DriveMode mode) {
        if (m_safetyPolicy) {
            if (!m_safetyPolicy->isVehicleConfigurationAllowed(getVehicleState())) {
                notifySafetyWarning("Unavailable while driving");
                return false;
            }
        }
        if (m_stateManager) {
            return m_stateManager->setDriveMode(mode);
        }
        if (m_vdi) {
            m_vdi->setDriveMode(mode);
            return true;
        }
        return false;
    }

    virtual bool setDoorLock(bool locked) {
        if (m_safetyPolicy) {
            if (!m_safetyPolicy->isVehicleConfigurationAllowed(getVehicleState())) {
                notifySafetyWarning("Unavailable while driving");
                return false;
            }
        }
        if (m_stateManager) {
            return m_stateManager->setDoorLock(locked);
        }
        if (m_vdi) {
            m_vdi->setDoorLock(locked);
            return true;
        }
        return false;
    }

    virtual bool toggleDoor(const std::string& doorName) {
        if (m_safetyPolicy) {
            if (!m_safetyPolicy->isVehicleConfigurationAllowed(getVehicleState())) {
                notifySafetyWarning("Unavailable while driving");
                return false;
            }
        }
        if (m_stateManager) {
            return m_stateManager->toggleDoor(doorName);
        }
        if (m_vdi) {
            m_vdi->toggleDoor(doorName);
            return true;
        }
        return false;
    }

    virtual bool setOperationalState(OperationalState state) {
        if (m_stateManager) {
            return m_stateManager->setOperationalState(state);
        }
        return false;
    }

    virtual bool setSpeed(float speedKmH) {
        if (m_stateManager) {
            return m_stateManager->setSpeed(speedKmH);
        }
        return false;
    }

    virtual bool setScenario(const std::string& scenario) {
        if (m_stateManager) {
            return m_stateManager->setScenario(scenario);
        }
        if (m_vdi) {
            m_vdi->setScenario(scenario);
            return true;
        }
        return false;
    }

    virtual bool setFaultMode(const std::string& faultMode) {
        if (m_stateManager) {
            return m_stateManager->setFaultMode(faultMode);
        }
        if (m_vdi) {
            m_vdi->setFaultMode(faultMode);
            return true;
        }
        return false;
    }

    virtual void registerStateCallback(StateChangedCallback callback) {
        m_stateCallbacks.push_back(std::move(callback));
    }

    virtual void registerSafetyWarningCallback(SafetyWarningCallback callback) {
        m_warningCallbacks.push_back(std::move(callback));
    }

    virtual void registerHealthCallback(HealthCallback callback) {
        m_healthCallbacks.push_back(std::move(callback));
    }

private:
    void notifyStateChanged(const VehicleState& state) {
        for (const auto& cb : m_stateCallbacks) {
            if (cb) cb(state);
        }
    }

    void notifySafetyWarning(const std::string& reason) {
        for (const auto& cb : m_warningCallbacks) {
            if (cb) cb(reason);
        }
    }

    void notifyHealthChanged(vehicle::CommunicationHealth health) {
        for (const auto& cb : m_healthCallbacks) {
            if (cb) cb(health);
        }
    }

    vehicle::VehicleDataInterface* m_vdi{nullptr};
    SafetyPolicy* m_safetyPolicy{nullptr};
    VehicleStateManager* m_stateManager{nullptr};
    std::unique_ptr<VehicleStateManager> m_ownedStateManager;

    VehicleState m_fallbackState{};
    std::vector<StateChangedCallback> m_stateCallbacks;
    std::vector<SafetyWarningCallback> m_warningCallbacks;
    std::vector<HealthCallback> m_healthCallbacks;
};

} // namespace driveos::domain
