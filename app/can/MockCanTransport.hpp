#pragma once

#include "can/ICanTransport.hpp"
#include <vector>
#include <mutex>

namespace driveos::can {

/**
 * @brief Deterministic in-memory mock CAN transport.
 * 
 * Used for unit testing, CI validation, and headless development without
 * requiring physical CAN hardware or Linux kernel virtual CAN drivers.
 */
class MockCanTransport : public ICanTransport {
public:
    explicit MockCanTransport(std::string interfaceName = "mock_can0");
    ~MockCanTransport() override = default;

    bool open(const std::string& interfaceName) override;
    void close() override;

    [[nodiscard]] bool isConnected() const override;
    bool sendFrame(const CanFrame& frame) override;
    void registerFrameCallback(FrameReceivedCallback callback) override;
    [[nodiscard]] std::string getInterfaceName() const override;

    // --- Test Instrumentation Hooks ---
    void injectFrame(const CanFrame& frame);
    void setConnected(bool connected);
    [[nodiscard]] std::vector<CanFrame> getSentFrames() const;
    [[nodiscard]] CanFrame getLastSentFrame() const;
    void clearSentFrames();
    [[nodiscard]] size_t getSentFrameCount() const;

private:
    std::string m_interfaceName{"mock_can0"};
    bool m_connected{false};
    mutable std::mutex m_mutex;
    FrameReceivedCallback m_callback;
    std::vector<CanFrame> m_sentFrames;
};

} // namespace driveos::can
