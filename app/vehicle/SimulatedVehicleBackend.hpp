#pragma once

#include "VehicleDataInterface.hpp"
#include <QObject>
#include <QTimer>
#include <mutex>
#include <string>

namespace driveos::vehicle {

/**
 * @brief Demonstration scenarios for rapid testing and developer inspection.
 */
enum class SimulationScenario : uint8_t {
    PARKED = 0,
    DRIVING,
    REVERSE,
    CHARGING,
    FAULT
};

/**
 * @brief Controlled fault simulation modes for robustness verification.
 */
enum class FaultSimulationMode : uint8_t {
    NONE = 0,
    UNAVAILABLE_DATA, // Bus interface disconnected / backend down
    STALE_DATA,       // Telemetry frozen, timestamps cease updating
    INVALID_DATA      // DBC physical range violations and sensor corruption
};

/**
 * @brief In-process deterministic vehicle simulator.
 * 
 * Provides realistic vehicle telemetry and commands without requiring external hardware or SocketCAN.
 * Implements smooth natural slewing of kinematics, cabin temperature, and energy dynamics.
 */
class SimulatedVehicleBackend : public QObject, public VehicleDataInterface {
    Q_OBJECT
public:
    explicit SimulatedVehicleBackend(QObject* parent = nullptr);
    ~SimulatedVehicleBackend() override;

    bool initialize() override;
    void shutdown() override;

    [[nodiscard]] domain::VehicleState getVehicleState() const override;
    [[nodiscard]] CommunicationHealth getCommunicationHealth() const override;

    void setTargetTemperature(float tempCelsius) override;
    void setFanSpeed(int level) override;
    void setACActive(bool active) override;
    void setDriveMode(domain::DriveMode mode) override;
    void setDoorLock(bool locked) override;

    // Simulation hooks
    void setSpeed(float speedKmH) override;
    void setOperationalState(domain::OperationalState opState, domain::Gear gear, float speedKmH) override;
    void toggleDoor(const std::string& doorName) override;
    void setDoorOpen(const std::string& doorName, bool open);

    // Scenario and fault simulation interface
    void setScenario(SimulationScenario scenario);
    void setScenario(const std::string& scenarioName) override;
    [[nodiscard]] SimulationScenario getScenario() const;

    void setFaultMode(FaultSimulationMode faultMode);
    void setFaultMode(const std::string& faultModeName) override;
    [[nodiscard]] FaultSimulationMode getFaultMode() const;

    void injectFault(const domain::FaultRecord& fault);
    void clearFaults();
    void stepSimulation(float dtSeconds) override;

    void registerStateCallback(StateCallback callback) override;
    void registerHealthCallback(HealthCallback callback) override;
    void registerFaultCallback(FaultCallback callback) override;

private:
    void notifyStateChanged();

    mutable std::mutex m_mutex;
    domain::VehicleState m_state{};
    CommunicationHealth m_health{CommunicationHealth::HEALTHY};
    SimulationScenario m_currentScenario{SimulationScenario::PARKED};
    FaultSimulationMode m_faultMode{FaultSimulationMode::NONE};

    // Slewing targets for smooth, realistic value transitions
    float m_targetSpeed{0.0f};
    domain::OperationalState m_targetOperationalState{domain::OperationalState::PARKED};
    domain::Gear m_targetGear{domain::Gear::PARK};

    QTimer* m_timer{nullptr};

    StateCallback m_stateCallback;
    HealthCallback m_healthCallback;
    FaultCallback m_faultCallback;
};

} // namespace driveos::vehicle
