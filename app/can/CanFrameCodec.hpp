#pragma once

#include "can/CanTypes.hpp"
#include "domain/VehicleState.hpp"
#include <string>

namespace driveos::can {

/**
 * @brief Isolated CAN frame encoder and decoder conforming strictly to driveos.dbc.
 * 
 * Encapsulates all bitwise extraction, linear scaling, and physical offset
 * transformations. Keeps raw CAN byte manipulations isolated from the rest of the application.
 */
class CanFrameCodec {
public:
    CanFrameCodec() = default;
    ~CanFrameCodec() = default;

    // -------------------------------------------------------------------------
    // Decoding Methods
    // -------------------------------------------------------------------------

    /**
     * @brief Decodes an incoming CAN frame into the provided VehicleState struct.
     * @param frame Raw CAN 2.0B frame.
     * @param state Reference to VehicleState to be partially updated.
     * @return CodecResult indicating success or descriptive validation failure.
     */
    [[nodiscard]] CodecResult decodeFrame(const CanFrame& frame, domain::VehicleState& state) const;

    // -------------------------------------------------------------------------
    // Encoding Methods (Commands and Telemetry)
    // -------------------------------------------------------------------------

    /**
     * @brief Encodes 0x201 Climate_Command frame.
     */
    [[nodiscard]] CanFrame encodeClimateCommand(bool acActive, int fanSpeed, float targetTemp) const;

    /**
     * @brief Encodes 0x401 Vehicle_Command frame.
     */
    [[nodiscard]] CanFrame encodeVehicleCommand(domain::DriveMode driveMode, bool doorLock) const;

    /**
     * @brief Encodes 0x100 Powertrain_Status frame.
     */
    [[nodiscard]] CanFrame encodePowertrainStatus(float speedKmH, domain::DriveMode mode, domain::Gear gear) const;

    /**
     * @brief Encodes 0x101 Battery_Status frame.
     */
    [[nodiscard]] CanFrame encodeBatteryStatus(float soc, float rangeKm, domain::ChargingState chargingState, float batteryTemp) const;

    /**
     * @brief Encodes 0x200 Climate_Status frame.
     */
    [[nodiscard]] CanFrame encodeClimateStatus(float cabinTemp, float outsideTemp, bool acActive, int fanSpeed, float targetTemp) const;

    /**
     * @brief Encodes 0x300 Body_Status frame.
     */
    [[nodiscard]] CanFrame encodeBodyStatus(const domain::DoorState& doors, bool locked, uint8_t exteriorLights = 1) const;

    /**
     * @brief Encodes 0x400 Vehicle_Config frame.
     */
    [[nodiscard]] CanFrame encodeVehicleConfig(domain::IgnitionState ignition, domain::OperationalState opState) const;

private:
    [[nodiscard]] CodecResult decodePowertrainStatus(const CanFrame& frame, domain::VehicleState& state) const;
    [[nodiscard]] CodecResult decodeBatteryStatus(const CanFrame& frame, domain::VehicleState& state) const;
    [[nodiscard]] CodecResult decodeClimateStatus(const CanFrame& frame, domain::VehicleState& state) const;
    [[nodiscard]] CodecResult decodeBodyStatus(const CanFrame& frame, domain::VehicleState& state) const;
    [[nodiscard]] CodecResult decodeVehicleConfig(const CanFrame& frame, domain::VehicleState& state) const;
};

} // namespace driveos::can
