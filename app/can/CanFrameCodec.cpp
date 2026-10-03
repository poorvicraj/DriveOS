#include "can/CanFrameCodec.hpp"
#include <cmath>
#include <algorithm>

namespace driveos::can {

CodecResult CanFrameCodec::decodeFrame(const CanFrame& frame, domain::VehicleState& state) const {
    if (frame.dlc < 8) {
        return CodecResult::fail(frame.canId, "Frame DLC less than required 8 bytes");
    }

    switch (frame.canId) {
    case CanId::POWERTRAIN_STATUS:
        return decodePowertrainStatus(frame, state);
    case CanId::BATTERY_STATUS:
        return decodeBatteryStatus(frame, state);
    case CanId::CLIMATE_STATUS:
        return decodeClimateStatus(frame, state);
    case CanId::BODY_STATUS:
        return decodeBodyStatus(frame, state);
    case CanId::VEHICLE_CONFIG:
        return decodeVehicleConfig(frame, state);
    default:
        // Ignore unhandled frames or return success without state change
        return CodecResult::ok(frame.canId);
    }
}

CodecResult CanFrameCodec::decodePowertrainStatus(const CanFrame& frame, domain::VehicleState& state) const {
    const uint16_t rawSpeed = static_cast<uint16_t>(frame.data[0]) |
                              (static_cast<uint16_t>(frame.data[1]) << 8);
    const float speed = static_cast<float>(rawSpeed) * 0.1f;
    if (speed > 250.0f) {
        return CodecResult::fail(frame.canId, "Vehicle speed exceeds physical DBC limit (250 km/h)");
    }

    const uint8_t rawDriveMode = frame.data[2] & 0x03;
    if (rawDriveMode > 2) {
        return CodecResult::fail(frame.canId, "Invalid DriveMode enum value");
    }

    const uint8_t rawGear = (frame.data[2] >> 2) & 0x03;
    if (rawGear > 3) {
        return CodecResult::fail(frame.canId, "Invalid Gear enum value");
    }

    state.speed = speed;
    state.driveMode = static_cast<domain::DriveMode>(rawDriveMode);
    state.gear = static_cast<domain::Gear>(rawGear);

    if (frame.timestampMs > 0) {
        state.timestampMs = frame.timestampMs;
    }

    return CodecResult::ok(frame.canId);
}

CodecResult CanFrameCodec::decodeBatteryStatus(const CanFrame& frame, domain::VehicleState& state) const {
    const uint8_t rawSoc = frame.data[0];
    const float soc = static_cast<float>(rawSoc) * 0.5f;
    if (soc > 100.0f) {
        return CodecResult::fail(frame.canId, "Battery SOC exceeds physical DBC limit (100%)");
    }

    const uint16_t rawRange = static_cast<uint16_t>(frame.data[1]) |
                              (static_cast<uint16_t>(frame.data[2]) << 8);
    const float rangeKm = static_cast<float>(rawRange);
    if (rangeKm > 800.0f) {
        return CodecResult::fail(frame.canId, "Vehicle range exceeds physical DBC limit (800 km)");
    }

    const uint8_t rawCharging = frame.data[3] & 0x07;
    if (rawCharging > 4) {
        return CodecResult::fail(frame.canId, "Invalid ChargingState enum value");
    }

    const uint8_t rawTemp = frame.data[4];
    const float batteryTemp = static_cast<float>(rawTemp) - 40.0f;
    if (batteryTemp < -40.0f || batteryTemp > 85.0f) {
        return CodecResult::fail(frame.canId, "Battery temperature out of DBC range [-40, 85]");
    }

    state.batterySoc = soc;
    state.rangeKm = rangeKm;
    state.chargingState = static_cast<domain::ChargingState>(rawCharging);
    state.batteryTemperature = batteryTemp;

    if (frame.timestampMs > 0) {
        state.timestampMs = frame.timestampMs;
    }

    return CodecResult::ok(frame.canId);
}

CodecResult CanFrameCodec::decodeClimateStatus(const CanFrame& frame, domain::VehicleState& state) const {
    const uint8_t rawCabin = frame.data[0];
    const float cabinTemp = static_cast<float>(rawCabin) * 0.5f - 20.0f;
    if (cabinTemp < -20.0f || cabinTemp > 50.0f) {
        return CodecResult::fail(frame.canId, "Cabin temperature out of DBC range [-20, 50]");
    }

    const uint8_t rawOutside = frame.data[1];
    const float outsideTemp = static_cast<float>(rawOutside) * 0.5f - 40.0f;
    if (outsideTemp < -40.0f || outsideTemp > 60.0f) {
        return CodecResult::fail(frame.canId, "Outside temperature out of DBC range [-40, 60]");
    }

    const bool ac = (frame.data[2] & 0x01) != 0;
    const uint8_t fan = (frame.data[2] >> 1) & 0x07;
    if (fan > 5) {
        return CodecResult::fail(frame.canId, "Fan speed exceeds DBC limit (5)");
    }

    const uint8_t rawTarget = frame.data[3];
    const float targetTemp = static_cast<float>(rawTarget) * 0.5f;
    if (rawTarget > 0 && (targetTemp < 16.0f || targetTemp > 28.0f)) {
        return CodecResult::fail(frame.canId, "Target temperature out of DBC range [16, 28]");
    }

    state.cabinTemperature = cabinTemp;
    state.outsideTemperature = outsideTemp;
    state.acActive = ac;
    state.fanSpeed = static_cast<int>(fan);
    if (rawTarget > 0) {
        state.targetTemperature = targetTemp;
    }

    if (frame.timestampMs > 0) {
        state.timestampMs = frame.timestampMs;
    }

    return CodecResult::ok(frame.canId);
}

CodecResult CanFrameCodec::decodeBodyStatus(const CanFrame& frame, domain::VehicleState& state) const {
    state.doors.frontLeftOpen  = (frame.data[0] & 0x01) != 0;
    state.doors.frontRightOpen = (frame.data[0] & 0x02) != 0;
    state.doors.rearLeftOpen   = (frame.data[0] & 0x04) != 0;
    state.doors.rearRightOpen  = (frame.data[0] & 0x08) != 0;

    if (frame.timestampMs > 0) {
        state.timestampMs = frame.timestampMs;
    }

    return CodecResult::ok(frame.canId);
}

CodecResult CanFrameCodec::decodeVehicleConfig(const CanFrame& frame, domain::VehicleState& state) const {
    const uint8_t rawIgnition = frame.data[0] & 0x03;
    if (rawIgnition > 2) {
        return CodecResult::fail(frame.canId, "Invalid IgnitionState enum value");
    }

    const uint8_t rawOpState = (frame.data[0] >> 2) & 0x07;
    if (rawOpState > 4) {
        return CodecResult::fail(frame.canId, "Invalid OperationalState enum value");
    }

    state.ignitionState = static_cast<domain::IgnitionState>(rawIgnition);
    state.operationalState = static_cast<domain::OperationalState>(rawOpState);

    if (frame.timestampMs > 0) {
        state.timestampMs = frame.timestampMs;
    }

    return CodecResult::ok(frame.canId);
}

// -----------------------------------------------------------------------------
// Frame Encoders
// -----------------------------------------------------------------------------

CanFrame CanFrameCodec::encodeClimateCommand(bool acActive, int fanSpeed, float targetTemp) const {
    CanFrame frame{};
    frame.canId = CanId::CLIMATE_COMMAND;
    frame.dlc = 8;

    const uint8_t acBit = acActive ? 1 : 0;
    const uint8_t fanBits = static_cast<uint8_t>(std::clamp(fanSpeed, 0, 5)) & 0x07;
    frame.data[0] = acBit | (fanBits << 1);

    const float clampedTarget = std::clamp(targetTemp, 16.0f, 28.0f);
    frame.data[1] = static_cast<uint8_t>(std::round(clampedTarget / 0.5f));

    return frame;
}

CanFrame CanFrameCodec::encodeVehicleCommand(domain::DriveMode driveMode, bool doorLock) const {
    CanFrame frame{};
    frame.canId = CanId::VEHICLE_COMMAND;
    frame.dlc = 8;

    const uint8_t modeBits = static_cast<uint8_t>(driveMode) & 0x03;
    const uint8_t lockBit = (doorLock ? 1 : 0) << 2;
    frame.data[0] = modeBits | lockBit;

    return frame;
}

CanFrame CanFrameCodec::encodePowertrainStatus(float speedKmH, domain::DriveMode mode, domain::Gear gear) const {
    CanFrame frame{};
    frame.canId = CanId::POWERTRAIN_STATUS;
    frame.dlc = 8;

    const float clampedSpeed = std::clamp(speedKmH, 0.0f, 250.0f);
    const uint16_t rawSpeed = static_cast<uint16_t>(std::round(clampedSpeed / 0.1f));
    frame.data[0] = static_cast<uint8_t>(rawSpeed & 0xFF);
    frame.data[1] = static_cast<uint8_t>((rawSpeed >> 8) & 0xFF);

    const uint8_t modeBits = static_cast<uint8_t>(mode) & 0x03;
    const uint8_t gearBits = (static_cast<uint8_t>(gear) & 0x03) << 2;
    frame.data[2] = modeBits | gearBits;

    return frame;
}

CanFrame CanFrameCodec::encodeBatteryStatus(float soc, float rangeKm, domain::ChargingState chargingState, float batteryTemp) const {
    CanFrame frame{};
    frame.canId = CanId::BATTERY_STATUS;
    frame.dlc = 8;

    const float clampedSoc = std::clamp(soc, 0.0f, 100.0f);
    frame.data[0] = static_cast<uint8_t>(std::round(clampedSoc / 0.5f));

    const float clampedRange = std::clamp(rangeKm, 0.0f, 800.0f);
    const uint16_t rawRange = static_cast<uint16_t>(std::round(clampedRange));
    frame.data[1] = static_cast<uint8_t>(rawRange & 0xFF);
    frame.data[2] = static_cast<uint8_t>((rawRange >> 8) & 0xFF);

    frame.data[3] = static_cast<uint8_t>(chargingState) & 0x07;

    const float clampedTemp = std::clamp(batteryTemp, -40.0f, 85.0f);
    frame.data[4] = static_cast<uint8_t>(std::round(clampedTemp + 40.0f));

    return frame;
}

CanFrame CanFrameCodec::encodeClimateStatus(float cabinTemp, float outsideTemp, bool acActive, int fanSpeed, float targetTemp) const {
    CanFrame frame{};
    frame.canId = CanId::CLIMATE_STATUS;
    frame.dlc = 8;

    const float clampedCabin = std::clamp(cabinTemp, -20.0f, 50.0f);
    frame.data[0] = static_cast<uint8_t>(std::round((clampedCabin + 20.0f) / 0.5f));

    const float clampedOutside = std::clamp(outsideTemp, -40.0f, 60.0f);
    frame.data[1] = static_cast<uint8_t>(std::round((clampedOutside + 40.0f) / 0.5f));

    const uint8_t acBit = acActive ? 1 : 0;
    const uint8_t fanBits = static_cast<uint8_t>(std::clamp(fanSpeed, 0, 5)) & 0x07;
    frame.data[2] = acBit | (fanBits << 1);

    const float clampedTarget = std::clamp(targetTemp, 16.0f, 28.0f);
    frame.data[3] = static_cast<uint8_t>(std::round(clampedTarget / 0.5f));

    return frame;
}

CanFrame CanFrameCodec::encodeBodyStatus(const domain::DoorState& doors, bool locked, uint8_t exteriorLights) const {
    CanFrame frame{};
    frame.canId = CanId::BODY_STATUS;
    frame.dlc = 8;

    uint8_t b0 = 0;
    if (doors.frontLeftOpen)  b0 |= 0x01;
    if (doors.frontRightOpen) b0 |= 0x02;
    if (doors.rearLeftOpen)   b0 |= 0x04;
    if (doors.rearRightOpen)  b0 |= 0x08;
    if (locked)               b0 |= 0x10;
    b0 |= (exteriorLights & 0x03) << 5;

    frame.data[0] = b0;
    return frame;
}

CanFrame CanFrameCodec::encodeVehicleConfig(domain::IgnitionState ignition, domain::OperationalState opState) const {
    CanFrame frame{};
    frame.canId = CanId::VEHICLE_CONFIG;
    frame.dlc = 8;

    const uint8_t ignBits = static_cast<uint8_t>(ignition) & 0x03;
    const uint8_t opBits = (static_cast<uint8_t>(opState) & 0x07) << 2;
    frame.data[0] = ignBits | opBits;

    return frame;
}

} // namespace driveos::can
