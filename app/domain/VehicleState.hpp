#pragma once

#include <cstdint>
#include <string>

namespace driveos::domain {

/**
 * @brief Discrete operational states of the vehicle powertrain and charging system.
 */
enum class OperationalState : uint8_t {
    PARKED = 0,
    DRIVING,
    REVERSE,
    CHARGING,
    FAULT
};

/**
 * @brief Selected driving dynamics mode.
 */
enum class DriveMode : uint8_t {
    ECO = 0,
    NORMAL,
    SPORT
};

/**
 * @brief Transmission gear selector position.
 */
enum class Gear : uint8_t {
    PARK = 0,
    REVERSE,
    NEUTRAL,
    DRIVE
};

/**
 * @brief Vehicle high-voltage battery charging status.
 */
enum class ChargingState : uint8_t {
    DISCONNECTED = 0,
    CONNECTING,
    CHARGING,
    COMPLETE,
    ERROR
};

/**
 * @brief Powertrain ignition / system power state.
 */
enum class IgnitionState : uint8_t {
    OFF = 0,
    ACCESSORY,
    ON
};

/**
 * @brief Individual closure / door physical position.
 */
struct DoorState {
    bool frontLeftOpen{false};
    bool frontRightOpen{false};
    bool rearLeftOpen{false};
    bool rearRightOpen{false};
};

/**
 * @brief Practical Vehicle State model.
 * 
 * Contains initial candidate signals required by implemented features.
 * Adheres to the scoping rule: signals are added or removed only when justified
 * by actual functionality. Avoids artificial vehicle complexity.
 */
struct VehicleState {
    // Kinematics and Powertrain
    float speed{0.0f};                      // Vehicle speed in km/h (0.0 - 250.0)
    OperationalState operationalState{OperationalState::PARKED};
    Gear gear{Gear::PARK};
    DriveMode driveMode{DriveMode::NORMAL};

    // Battery and Energy Storage
    float batterySoc{82.0f};                // State of Charge in % (0.0 - 100.0)
    float rangeKm{410.0f};                  // Estimated driving range in km (0.0 - 800.0)
    float batteryTemperature{24.5f};        // Battery pack temperature in °C (-40.0 - 85.0)
    ChargingState chargingState{ChargingState::DISCONNECTED};

    // HVAC & Cabin Environment
    float cabinTemperature{21.5f};          // Cabin ambient temperature in °C (-20.0 - 60.0)
    float outsideTemperature{18.0f};        // Exterior ambient temperature in °C (-40.0 - 60.0)
    float targetTemperature{22.0f};         // HVAC setpoint in °C (16.0 - 28.0)
    bool acActive{true};                    // Air conditioning compressor state
    int fanSpeed{2};                        // HVAC blower speed (0: Off, 1-5)

    // Body & Closures
    DoorState doors{};
    IgnitionState ignitionState{IgnitionState::ON};

    // Timestamp of latest update (monotonic milliseconds)
    uint64_t timestampMs{0};
};

} // namespace driveos::domain
