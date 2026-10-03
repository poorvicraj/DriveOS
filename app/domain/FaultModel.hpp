#pragma once

#include <cstdint>
#include <string>

namespace driveos::domain {

/**
 * @brief Quality and validity status for vehicle signals.
 */
enum class SignalStatus : uint8_t {
    VALID = 0,        // Signal received within deadline and within physical range limits
    STALE,            // Periodic frame missed its reception deadline (bus timeout)
    INVALID,          // Signal value violates DBC physical range bounds or parity/CRC
    NOT_AVAILABLE     // Signal uninitialized or communication link not established
};

/**
 * @brief Categorization of system-level and sensor faults.
 */
enum class FaultType : uint8_t {
    NONE = 0,
    DATA_UNAVAILABLE,       // Vehicle backend not responding
    STALE_SIGNAL,           // Cyclic frame timeout
    INVALID_RANGE,          // Sensor reading outside physical DBC bounds
    SENSOR_FAILURE,         // Internal hardware or transducer failure simulated
    COMMUNICATION_TIMEOUT   // CAN bus communication lost entirely
};

/**
 * @brief Structured fault record for observability and diagnostic reporting.
 */
struct FaultRecord {
    FaultType type{FaultType::NONE};
    std::string subsystem;
    std::string description;
    uint64_t timestampMs{0};
    bool isRecoverable{true};
};

/**
 * @brief Generic wrapper associating a typed value with its signal validity status.
 */
template <typename T>
struct SignalValue {
    T value{};
    SignalStatus status{SignalStatus::NOT_AVAILABLE};
    uint64_t timestampMs{0};

    [[nodiscard]] bool isValid() const noexcept {
        return status == SignalStatus::VALID;
    }

    [[nodiscard]] bool isStale() const noexcept {
        return status == SignalStatus::STALE;
    }
};

} // namespace driveos::domain
