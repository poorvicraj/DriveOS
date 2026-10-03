#include "can/SocketCanTransport.hpp"
#include <iostream>
#include <chrono>
#include <cstring>

#if defined(__linux__)
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <unistd.h>
#include <poll.h>
#endif

namespace driveos::can {

SocketCanTransport::SocketCanTransport(std::string interfaceName)
    : m_interfaceName(std::move(interfaceName))
{
}

SocketCanTransport::~SocketCanTransport() {
    close();
}

bool SocketCanTransport::open(const std::string& interfaceName) {
    close();
    m_interfaceName = interfaceName;

#if defined(__linux__)
    m_socketDescriptor = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (m_socketDescriptor < 0) {
        std::cerr << "[SocketCanTransport] Failed to create PF_CAN raw socket: " 
                  << std::strerror(errno) << "\n";
        return false;
    }

    struct ifreq ifr{};
    std::strncpy(ifr.ifr_name, m_interfaceName.c_str(), IFNAMSIZ - 1);
    if (ioctl(m_socketDescriptor, SIOCGIFINDEX, &ifr) < 0) {
        std::cerr << "[SocketCanTransport] Interface '" << m_interfaceName << "' not found via ioctl SIOCGIFINDEX: "
                  << std::strerror(errno) << "\n";
        ::close(m_socketDescriptor);
        m_socketDescriptor = -1;
        return false;
    }

    struct sockaddr_can addr{};
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;

    if (bind(m_socketDescriptor, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) < 0) {
        std::cerr << "[SocketCanTransport] Failed to bind to interface '" << m_interfaceName << "': "
                  << std::strerror(errno) << "\n";
        ::close(m_socketDescriptor);
        m_socketDescriptor = -1;
        return false;
    }

    m_running = true;
    m_connected = true;
    m_rxThread = std::thread(&SocketCanTransport::receiveLoop, this);
    std::cout << "[SocketCanTransport] Successfully connected to SocketCAN interface '" << m_interfaceName << "'\n";
    return true;

#else
    std::cout << "[SocketCanTransport] SocketCAN (vcan0) is supported on Linux kernels (native or WSL2).\n"
              << "                      Windows host cannot open PF_CAN sockets directly.\n"
              << "                      Gracefully reporting unavailable transport to trigger fallback.\n";
    m_connected = false;
    m_socketDescriptor = -1;
    return false;
#endif
}

void SocketCanTransport::close() {
    m_connected = false;
    m_running = false;

#if defined(__linux__)
    if (m_socketDescriptor >= 0) {
        ::close(m_socketDescriptor);
        m_socketDescriptor = -1;
    }
#else
    m_socketDescriptor = -1;
#endif

    if (m_rxThread.joinable()) {
        m_rxThread.join();
    }
}

bool SocketCanTransport::isConnected() const {
    return m_connected.load();
}

bool SocketCanTransport::sendFrame(const CanFrame& frame) {
    if (!m_connected.load() || m_socketDescriptor < 0) {
        return false;
    }

#if defined(__linux__)
    struct can_frame cf{};
    cf.can_id = frame.canId;
    cf.can_dlc = frame.dlc;
    std::memcpy(cf.data, frame.data.data(), std::min<size_t>(frame.dlc, 8));

    const ssize_t bytesWritten = ::write(m_socketDescriptor, &cf, sizeof(cf));
    return (bytesWritten == static_cast<ssize_t>(sizeof(cf)));
#else
    (void)frame;
    return false;
#endif
}

void SocketCanTransport::registerFrameCallback(FrameReceivedCallback callback) {
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_callback = std::move(callback);
}

std::string SocketCanTransport::getInterfaceName() const {
    return m_interfaceName;
}

void SocketCanTransport::receiveLoop() {
#if defined(__linux__)
    struct pollfd pfd{};
    pfd.fd = m_socketDescriptor;
    pfd.events = POLLIN;

    while (m_running.load()) {
        const int ret = poll(&pfd, 1, 100); // 100ms timeout for clean cancellation check
        if (ret < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (ret == 0) {
            continue; // Poll timeout, loop to check m_running
        }

        if (pfd.revents & POLLIN) {
            struct can_frame cf{};
            const ssize_t nbytes = ::read(m_socketDescriptor, &cf, sizeof(cf));
            if (nbytes == static_cast<ssize_t>(sizeof(cf))) {
                CanFrame frame{};
                frame.canId = cf.can_id & CAN_EFF_MASK;
                frame.dlc = cf.can_dlc;
                std::memcpy(frame.data.data(), cf.data, std::min<size_t>(cf.can_dlc, 8));

                const auto now = std::chrono::steady_clock::now();
                frame.timestampMs = static_cast<uint64_t>(
                    std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count()
                );

                FrameReceivedCallback cb;
                {
                    std::lock_guard<std::mutex> lock(m_callbackMutex);
                    cb = m_callback;
                }
                if (cb) {
                    cb(frame);
                }
            } else if (nbytes < 0 && errno != EAGAIN && errno != EWOULDBLOCK) {
                std::cerr << "[SocketCanTransport] Socket read error: " << std::strerror(errno) << "\n";
                break;
            }
        }
    }

    m_connected = false;
#endif
}

} // namespace driveos::can
