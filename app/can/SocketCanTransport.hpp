#pragma once

#include "can/ICanTransport.hpp"
#include <atomic>
#include <mutex>
#include <thread>
#include <string>

namespace driveos::can {

/**
 * @brief Production Linux SocketCAN transport implementation.
 * 
 * Supports standard virtual CAN interfaces (e.g. vcan0) and physical CAN controllers
 * via Linux PF_CAN raw sockets. Provides asynchronous non-blocking frame reception
 * via a dedicated worker thread with poll timeout for clean shutdown.
 * 
 * On non-Linux platforms (e.g. Windows host), this class gracefully handles the OS
 * limitation by reporting failure on open(), logging the environment notice,
 * and allowing the application to transparently fall back to the vehicle simulator.
 */
class SocketCanTransport : public ICanTransport {
public:
    explicit SocketCanTransport(std::string interfaceName = "vcan0");
    ~SocketCanTransport() override;

    bool open(const std::string& interfaceName) override;
    void close() override;

    [[nodiscard]] bool isConnected() const override;
    bool sendFrame(const CanFrame& frame) override;
    void registerFrameCallback(FrameReceivedCallback callback) override;
    [[nodiscard]] std::string getInterfaceName() const override;

private:
    void receiveLoop();

    std::string m_interfaceName{"vcan0"};
    std::atomic<bool> m_connected{false};
    std::atomic<bool> m_running{false};
    int m_socketDescriptor{-1};

    std::thread m_rxThread;
    mutable std::mutex m_callbackMutex;
    FrameReceivedCallback m_callback;
};

} // namespace driveos::can
