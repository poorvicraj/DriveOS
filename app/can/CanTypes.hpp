#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <array>

namespace driveos::can {

/**
 * @brief Standard 11-bit CAN frame identifier constants conforming to driveos.dbc.
 */
namespace CanId {
    inline constexpr uint32_t POWERTRAIN_STATUS = 0x100; // 256
    inline constexpr uint32_t BATTERY_STATUS    = 0x101; // 257
    inline constexpr uint32_t CLIMATE_STATUS    = 0x200; // 512
    inline constexpr uint32_t CLIMATE_COMMAND   = 0x201; // 513
    inline constexpr uint32_t BODY_STATUS       = 0x300; // 768
    inline constexpr uint32_t VEHICLE_CONFIG    = 0x400; // 1024
    inline constexpr uint32_t VEHICLE_COMMAND   = 0x401; // 1025
}

/**
 * @brief Canonical representation of a standard CAN 2.0B frame.
 * 
 * Holds standard 11-bit CAN ID, Data Length Code (DLC up to 8 bytes),
 * payload data, and microsecond reception timestamp.
 */
struct CanFrame {
    uint32_t canId{0};
    uint8_t dlc{8};
    std::array<uint8_t, 8> data{};
    uint64_t timestampMs{0};

    [[nodiscard]] constexpr bool isValidDlc() const noexcept {
        return dlc <= 8;
    }
};

/**
 * @brief Outcome of a frame decoding or encoding operation.
 */
struct CodecResult {
    bool success{false};
    uint32_t canId{0};
    std::string errorMessage;

    [[nodiscard]] static constexpr CodecResult ok(uint32_t id) noexcept {
        return {true, id, {}};
    }

    [[nodiscard]] static CodecResult fail(uint32_t id, std::string msg) {
        return {false, id, std::move(msg)};
    }
};

} // namespace driveos::can
