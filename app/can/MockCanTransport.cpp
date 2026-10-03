#include "can/MockCanTransport.hpp"

namespace driveos::can {

MockCanTransport::MockCanTransport(std::string interfaceName)
    : m_interfaceName(std::move(interfaceName))
{
}

bool MockCanTransport::open(const std::string& interfaceName) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_interfaceName = interfaceName;
    m_connected = true;
    return true;
}

void MockCanTransport::close() {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_connected = false;
}

bool MockCanTransport::isConnected() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_connected;
}

bool MockCanTransport::sendFrame(const CanFrame& frame) {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_connected) {
        return false;
    }
    m_sentFrames.push_back(frame);
    return true;
}

void MockCanTransport::registerFrameCallback(FrameReceivedCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_callback = std::move(callback);
}

std::string MockCanTransport::getInterfaceName() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_interfaceName;
}

void MockCanTransport::injectFrame(const CanFrame& frame) {
    FrameReceivedCallback cb;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_connected) {
            return;
        }
        cb = m_callback;
    }
    if (cb) {
        cb(frame);
    }
}

void MockCanTransport::setConnected(bool connected) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_connected = connected;
}

std::vector<CanFrame> MockCanTransport::getSentFrames() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_sentFrames;
}

CanFrame MockCanTransport::getLastSentFrame() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_sentFrames.empty()) {
        return CanFrame{};
    }
    return m_sentFrames.back();
}

void MockCanTransport::clearSentFrames() {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_sentFrames.clear();
}

size_t MockCanTransport::getSentFrameCount() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_sentFrames.size();
}

} // namespace driveos::can
