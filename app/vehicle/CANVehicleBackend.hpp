#pragma once

#include "vehicle/VehicleDataInterface.hpp"
#include "can/ICanTransport.hpp"
#include "can/CanFrameCodec.hpp"
#include <memory>
#include <mutex>
#include <atomic>
#include <chrono>

namespace driveos::vehicle {

/**
 * @brief Production automotive CAN Vehicle Data Interface backend.
 * 
 * Sits directly below VehicleDataInterface, connecting DriveOS services and ViewModels
 * to a Linux SocketCAN interface (e.g. vcan0) or an injected ICanTransport.
 * Decodes cyclic CAN frames into canonical VehicleState models and encodes
 * outgoing driver actuation commands into DBC-compliant frames.
 * 
 * Provides automated bus health monitoring, frame timeout detection,
 * and physical range boundary validation.
 */
class CANVehicleBackend : public VehicleDataInterface {
public:
    /**
     * @brief Constructs CAN backend with custom or default transport.
     * @param transport Optional custom transport; if nullptr, defaults to SocketCanTransport.
     * @param interfaceName Name of CAN device (default "vcan0").
     */
    explicit CANVehicleBackend(std::unique_ptr<can::ICanTransport> transport = nullptr,
                               std::string interfaceName = "vcan0");
    ~CANVehicleBackend() override;

    // --- VehicleDataInterface Lifecycle ---
    bool initialize() override;
    void shutdown() override;

    // --- State & Health Queries ---
    [[nodiscard]] domain::VehicleState getVehicleState() const override;
    [[nodiscard]] CommunicationHealth getCommunicationHealth() const override;

    // --- Actuation Commands (Sent as CAN Frames) ---
    void setTargetTemperature(float tempCelsius) override;
    void setFanSpeed(int level) override;
    void setACActive(bool active) override;
    void setDriveMode(domain::DriveMode mode) override;
    void setDoorLock(bool locked) override;

    // --- Observers & Callbacks ---
    void registerStateCallback(StateCallback callback) override;
    void registerHealthCallback(HealthCallback callback) override;
    void registerFaultCallback(FaultCallback callback) override;

    // --- CAN Health, Timeout & Diagnostics ---
    /**
     * @brief Evaluates bus reception deadline and updates communication health.
     * @param currentTimestampMs Current monotonic millisecond timestamp.
     */
    void checkTimeout(uint64_t currentTimestampMs);

    /**
     * @brief Configures maximum allowed silence on the bus before timeout (default 500ms).
     */
    void setTimeoutThresholdMs(uint64_t thresholdMs);

    [[nodiscard]] can::ICanTransport* getTransport() const noexcept {
        return m_transport.get();
    }

private:
    void onFrameReceived(const can::CanFrame& frame);
    void updateHealth(CommunicationHealth newHealth);

    mutable std::mutex m_mutex;
    std::string m_interfaceName{"vcan0"};
    std::unique_ptr<can::ICanTransport> m_transport;
    can::CanFrameCodec m_codec;

    domain::VehicleState m_state{};
    CommunicationHealth m_health{CommunicationHealth::DISCONNECTED};

    uint64_t m_lastFrameTimestampMs{0};
    uint64_t m_timeoutThresholdMs{500}; // 500 ms deadline for cyclic telemetry

    StateCallback m_stateCallback;
    HealthCallback m_healthCallback;
    FaultCallback m_faultCallback;
};

} // namespace driveos::vehicle
