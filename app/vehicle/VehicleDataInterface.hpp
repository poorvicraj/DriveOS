#pragma once

#include "domain/VehicleState.hpp"
#include "domain/FaultModel.hpp"
#include <functional>
#include <memory>
#include <string>

namespace driveos::vehicle {

/**
 * @brief Communication bus and link health status.
 */
enum class CommunicationHealth : uint8_t {
    HEALTHY = 0,    // Normal cyclic message reception, within deadlines
    DEGRADED,       // Non-critical frame timeout or intermittent drops
    DISCONNECTED,   // Bus interface down, no incoming traffic
    BUS_OFF         // CAN controller error passive or bus-off state
};

/**
 * @brief Pure abstract Hardware Abstraction Layer (HAL) interface.
 * 
 * Decouples presentation and domain services from the underlying vehicle hardware
 * or network transport. Backed by either SimulatedVehicleBackend (for local/headless
 * simulation) or CANVehicleBackend (for Linux SocketCAN + vcan0 integration)
 * without requiring any UI modifications.
 */
class VehicleDataInterface {
public:
    using StateCallback = std::function<void(const domain::VehicleState&)>;
    using HealthCallback = std::function<void(CommunicationHealth)>;
    using FaultCallback = std::function<void(const domain::FaultRecord&)>;

    virtual ~VehicleDataInterface() = default;

    // --- Lifecycle & Initialization ---
    virtual bool initialize() = 0;
    virtual void shutdown() = 0;

    // --- State & Signal Access ---
    [[nodiscard]] virtual domain::VehicleState getVehicleState() const = 0;
    [[nodiscard]] virtual CommunicationHealth getCommunicationHealth() const = 0;

    // --- Vehicle Commands (Dispatched from UI via Services) ---
    virtual void setTargetTemperature(float tempCelsius) = 0;
    virtual void setFanSpeed(int level) = 0;
    virtual void setACActive(bool active) = 0;
    virtual void setDriveMode(domain::DriveMode mode) = 0;
    virtual void setDoorLock(bool locked) = 0;
    virtual void setOperationalState(domain::OperationalState /*opState*/, domain::Gear /*gear*/, float /*speedKmH*/) {}
    virtual void toggleDoor(const std::string& /*doorName*/) {}
    virtual void setSpeed(float /*speedKmH*/) {}

    // --- Simulation & Testing Hooks ---
    virtual void setScenario(const std::string& /*scenario*/) {}
    virtual void setFaultMode(const std::string& /*faultMode*/) {}
    virtual void stepSimulation(float /*dtSeconds*/) {}

    // --- Asynchronous Notifications & Callbacks ---
    virtual void registerStateCallback(StateCallback callback) = 0;
    virtual void registerHealthCallback(HealthCallback callback) = 0;
    virtual void registerFaultCallback(FaultCallback callback) = 0;
};

} // namespace driveos::vehicle
