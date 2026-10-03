#pragma once

#include "can/CanTypes.hpp"
#include <functional>
#include <string>

namespace driveos::can {

/**
 * @brief Abstract CAN network transport interface.
 * 
 * Decouples frame reception and transmission from physical hardware or OS drivers.
 * Implementations include Linux SocketCanTransport (for vcan0 / physical CAN)
 * and MockCanTransport (for in-memory unit tests and simulated loopback).
 */
class ICanTransport {
public:
    using FrameReceivedCallback = std::function<void(const CanFrame&)>;

    virtual ~ICanTransport() = default;

    /**
     * @brief Opens and binds the CAN interface (e.g. "vcan0", "can0").
     * @param interfaceName Device name in Linux network subsystem.
     * @return true if interface is opened and ready, false on failure or unsupported platform.
     */
    virtual bool open(const std::string& interfaceName) = 0;

    /**
     * @brief Closes the CAN interface and terminates listener worker threads.
     */
    virtual void close() = 0;

    /**
     * @brief Checks if the transport is actively connected and operational.
     */
    [[nodiscard]] virtual bool isConnected() const = 0;

    /**
     * @brief Transmits a CAN 2.0B frame over the bus.
     * @param frame Frame to transmit.
     * @return true if successfully queued/transmitted.
     */
    virtual bool sendFrame(const CanFrame& frame) = 0;

    /**
     * @brief Registers an asynchronous frame reception listener.
     */
    virtual void registerFrameCallback(FrameReceivedCallback callback) = 0;

    /**
     * @brief Returns the bound interface name.
     */
    [[nodiscard]] virtual std::string getInterfaceName() const = 0;
};

} // namespace driveos::can
