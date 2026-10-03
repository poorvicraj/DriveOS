#include "vehicle/CANVehicleBackend.hpp"
#include "can/SocketCanTransport.hpp"
#include <iostream>

namespace driveos::vehicle {

CANVehicleBackend::CANVehicleBackend(std::unique_ptr<can::ICanTransport> transport,
                                     std::string interfaceName)
    : m_interfaceName(std::move(interfaceName))
    , m_transport(std::move(transport))
{
    if (!m_transport) {
        m_transport = std::make_unique<can::SocketCanTransport>(m_interfaceName);
    }
}

CANVehicleBackend::~CANVehicleBackend() {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_stateCallback = nullptr;
        m_healthCallback = nullptr;
        m_faultCallback = nullptr;
    }
    shutdown();
}

bool CANVehicleBackend::initialize() {
    HealthCallback hCb;
    CommunicationHealth hVal;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_transport) {
            m_transport = std::make_unique<can::SocketCanTransport>(m_interfaceName);
        }

        m_transport->registerFrameCallback([this](const can::CanFrame& frame) {
            onFrameReceived(frame);
        });

        const bool opened = m_transport->open(m_interfaceName);
        if (opened) {
            m_health = CommunicationHealth::HEALTHY;
        } else {
            m_health = CommunicationHealth::DISCONNECTED;
        }
        hCb = m_healthCallback;
        hVal = m_health;
    }

    if (hCb) {
        hCb(hVal);
    }

    return (hVal == CommunicationHealth::HEALTHY);
}

void CANVehicleBackend::shutdown() {
    HealthCallback hCb;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_transport) {
            m_transport->close();
        }
        m_health = CommunicationHealth::DISCONNECTED;
        hCb = m_healthCallback;
    }
    if (hCb) {
        hCb(CommunicationHealth::DISCONNECTED);
    }
}

domain::VehicleState CANVehicleBackend::getVehicleState() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_state;
}

CommunicationHealth CANVehicleBackend::getCommunicationHealth() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_health;
}

void CANVehicleBackend::setTargetTemperature(float tempCelsius) {
    can::CanFrame frame;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.targetTemperature = tempCelsius;
        frame = m_codec.encodeClimateCommand(m_state.acActive, m_state.fanSpeed, tempCelsius);
    }
    if (m_transport) {
        m_transport->sendFrame(frame);
    }
}

void CANVehicleBackend::setFanSpeed(int level) {
    can::CanFrame frame;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.fanSpeed = level;
        frame = m_codec.encodeClimateCommand(m_state.acActive, level, m_state.targetTemperature);
    }
    if (m_transport) {
        m_transport->sendFrame(frame);
    }
}

void CANVehicleBackend::setACActive(bool active) {
    can::CanFrame frame;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.acActive = active;
        frame = m_codec.encodeClimateCommand(active, m_state.fanSpeed, m_state.targetTemperature);
    }
    if (m_transport) {
        m_transport->sendFrame(frame);
    }
}

void CANVehicleBackend::setDriveMode(domain::DriveMode mode) {
    can::CanFrame frame;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.driveMode = mode;
        frame = m_codec.encodeVehicleCommand(mode, false);
    }
    if (m_transport) {
        m_transport->sendFrame(frame);
    }
}

void CANVehicleBackend::setDoorLock(bool locked) {
    can::CanFrame frame;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        frame = m_codec.encodeVehicleCommand(m_state.driveMode, locked);
    }
    if (m_transport) {
        m_transport->sendFrame(frame);
    }
}

void CANVehicleBackend::registerStateCallback(StateCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_stateCallback = std::move(callback);
}

void CANVehicleBackend::registerHealthCallback(HealthCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_healthCallback = std::move(callback);
}

void CANVehicleBackend::registerFaultCallback(FaultCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_faultCallback = std::move(callback);
}

void CANVehicleBackend::checkTimeout(uint64_t currentTimestampMs) {
    HealthCallback hCb;
    CommunicationHealth newHealth = CommunicationHealth::HEALTHY;
    bool healthChanged = false;

    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_health == CommunicationHealth::HEALTHY) {
            if (m_lastFrameTimestampMs > 0 &&
                (currentTimestampMs > m_lastFrameTimestampMs) &&
                (currentTimestampMs - m_lastFrameTimestampMs > m_timeoutThresholdMs))
            {
                m_health = CommunicationHealth::DISCONNECTED;
                newHealth = m_health;
                healthChanged = true;
                hCb = m_healthCallback;
            }
        }
    }

    if (healthChanged && hCb) {
        hCb(newHealth);
    }
}

void CANVehicleBackend::setTimeoutThresholdMs(uint64_t thresholdMs) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_timeoutThresholdMs = thresholdMs;
}

void CANVehicleBackend::onFrameReceived(const can::CanFrame& frame) {
    StateCallback sCb;
    HealthCallback hCb;
    FaultCallback fCb;

    domain::VehicleState stateCopy;
    CommunicationHealth healthToNotify = CommunicationHealth::HEALTHY;
    bool notifyHealth = false;
    bool notifyState = false;
    bool notifyFault = false;
    domain::FaultRecord fault{};

    {
        std::lock_guard<std::mutex> lock(m_mutex);
        const uint64_t frameTime = (frame.timestampMs > 0) ? frame.timestampMs : 1;
        m_lastFrameTimestampMs = frameTime;

        const auto res = m_codec.decodeFrame(frame, m_state);
        if (!res.success) {
            // Signal validation or frame formatting failure
            m_health = CommunicationHealth::DEGRADED;
            healthToNotify = CommunicationHealth::DEGRADED;
            notifyHealth = true;

            fault.type = domain::FaultType::INVALID_RANGE;
            fault.subsystem = "CAN_DECODER";
            fault.description = "CAN ID 0x" + [&]() {
                char buf[16];
                std::snprintf(buf, sizeof(buf), "%X", res.canId);
                return std::string(buf);
            }() + ": " + res.errorMessage;
            fault.timestampMs = frameTime;
            fault.isRecoverable = true;

            notifyFault = true;
            fCb = m_faultCallback;
            hCb = m_healthCallback;
        } else {
            // Valid frame decoded
            if (m_health != CommunicationHealth::HEALTHY) {
                m_health = CommunicationHealth::HEALTHY;
                healthToNotify = CommunicationHealth::HEALTHY;
                notifyHealth = true;
                hCb = m_healthCallback;
            }
            stateCopy = m_state;
            notifyState = true;
            sCb = m_stateCallback;
        }
    }

    if (notifyFault && fCb) {
        fCb(fault);
    }
    if (notifyHealth && hCb) {
        hCb(healthToNotify);
    }
    if (notifyState && sCb) {
        sCb(stateCopy);
    }
}

} // namespace driveos::vehicle
