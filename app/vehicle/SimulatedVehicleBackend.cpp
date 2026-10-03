#include "SimulatedVehicleBackend.hpp"
#include <QCoreApplication>
#include <algorithm>

namespace driveos::vehicle {

SimulatedVehicleBackend::SimulatedVehicleBackend(QObject* parent)
    : QObject(parent)
{
    m_state.speed = 0.0f;
    m_state.operationalState = domain::OperationalState::PARKED;
    m_state.gear = domain::Gear::PARK;
    m_state.driveMode = domain::DriveMode::NORMAL;
    m_state.batterySoc = 84.5f;
    m_state.rangeKm = 422.5f;
    m_state.batteryTemperature = 25.0f;
    m_state.chargingState = domain::ChargingState::DISCONNECTED;
    m_state.cabinTemperature = 21.5f;
    m_state.outsideTemperature = 19.0f;
    m_state.targetTemperature = 22.0f;
    m_state.acActive = true;
    m_state.fanSpeed = 2;
    m_state.ignitionState = domain::IgnitionState::ON;
    m_state.timestampMs = 0;

    m_targetSpeed = 0.0f;
    m_targetOperationalState = domain::OperationalState::PARKED;
    m_targetGear = domain::Gear::PARK;
}

SimulatedVehicleBackend::~SimulatedVehicleBackend() {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_stateCallback = nullptr;
        m_healthCallback = nullptr;
        m_faultCallback = nullptr;
    }
    shutdown();
}

bool SimulatedVehicleBackend::initialize() {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_health = CommunicationHealth::HEALTHY;
        m_faultMode = FaultSimulationMode::NONE;
    }

    if (m_healthCallback) {
        m_healthCallback(CommunicationHealth::HEALTHY);
    }
    notifyStateChanged();

    // Start simulation ticker if running inside a Qt application with event loop
    if (QCoreApplication::instance() && !m_timer) {
        m_timer = new QTimer(this);
        connect(m_timer, &QTimer::timeout, this, [this]() {
            stepSimulation(0.1f);
        });
        m_timer->start(100); // 10 Hz simulation loop
    }

    return true;
}

void SimulatedVehicleBackend::shutdown() {
    if (m_timer) {
        m_timer->stop();
    }
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_health = CommunicationHealth::DISCONNECTED;
    }
    if (m_healthCallback) {
        m_healthCallback(CommunicationHealth::DISCONNECTED);
    }
}

domain::VehicleState SimulatedVehicleBackend::getVehicleState() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_state;
}

CommunicationHealth SimulatedVehicleBackend::getCommunicationHealth() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_health;
}

void SimulatedVehicleBackend::setTargetTemperature(float tempCelsius) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.targetTemperature = std::clamp(tempCelsius, 16.0f, 28.0f);
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::setFanSpeed(int level) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.fanSpeed = std::clamp(level, 0, 5);
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::setACActive(bool active) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.acActive = active;
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::setDriveMode(domain::DriveMode mode) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.driveMode = mode;
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::setDoorLock(bool locked) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (locked) {
            m_state.doors.frontLeftOpen = false;
            m_state.doors.frontRightOpen = false;
            m_state.doors.rearLeftOpen = false;
            m_state.doors.rearRightOpen = false;
        }
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::setSpeed(float speedKmH) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_targetSpeed = std::clamp(speedKmH, 0.0f, 250.0f);
    if (m_targetSpeed > 0.1f) {
        m_targetOperationalState = domain::OperationalState::DRIVING;
        m_targetGear = domain::Gear::DRIVE;
        m_state.operationalState = domain::OperationalState::DRIVING;
        m_state.gear = domain::Gear::DRIVE;
    } else {
        m_targetOperationalState = domain::OperationalState::PARKED;
        m_targetGear = domain::Gear::PARK;
    }
}

void SimulatedVehicleBackend::setOperationalState(domain::OperationalState opState, domain::Gear gear, float speedKmH) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.operationalState = opState;
        m_state.gear = gear;
        m_targetOperationalState = opState;
        m_targetGear = gear;
        m_targetSpeed = std::clamp(speedKmH, 0.0f, 250.0f);

        if (opState == domain::OperationalState::CHARGING) {
            m_state.chargingState = domain::ChargingState::CHARGING;
            m_state.speed = 0.0f;
            m_targetSpeed = 0.0f;
        } else if (opState == domain::OperationalState::PARKED) {
            m_state.chargingState = domain::ChargingState::DISCONNECTED;
            m_state.speed = 0.0f;
            m_targetSpeed = 0.0f;
        } else if (opState == domain::OperationalState::FAULT) {
            m_state.speed = 0.0f;
            m_targetSpeed = 0.0f;
        } else if (opState == domain::OperationalState::DRIVING) {
            m_state.chargingState = domain::ChargingState::DISCONNECTED;
            if (speedKmH > 0.1f) {
                m_state.speed = speedKmH;
            } else if (m_state.speed < 0.1f) {
                m_targetSpeed = 64.0f;
            }
        } else if (opState == domain::OperationalState::REVERSE) {
            m_state.chargingState = domain::ChargingState::DISCONNECTED;
            m_targetSpeed = (speedKmH > 0.1f) ? speedKmH : 4.0f;
            m_state.speed = m_targetSpeed;
        }
    }

    notifyStateChanged();
}

void SimulatedVehicleBackend::toggleDoor(const std::string& doorName) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (doorName == "FL" || doorName == "frontLeft") {
            m_state.doors.frontLeftOpen = !m_state.doors.frontLeftOpen;
        } else if (doorName == "FR" || doorName == "frontRight") {
            m_state.doors.frontRightOpen = !m_state.doors.frontRightOpen;
        } else if (doorName == "RL" || doorName == "rearLeft") {
            m_state.doors.rearLeftOpen = !m_state.doors.rearLeftOpen;
        } else if (doorName == "RR" || doorName == "rearRight") {
            m_state.doors.rearRightOpen = !m_state.doors.rearRightOpen;
        }
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::setDoorOpen(const std::string& doorName, bool open) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (doorName == "FL" || doorName == "frontLeft") {
            m_state.doors.frontLeftOpen = open;
        } else if (doorName == "FR" || doorName == "frontRight") {
            m_state.doors.frontRightOpen = open;
        } else if (doorName == "RL" || doorName == "rearLeft") {
            m_state.doors.rearLeftOpen = open;
        } else if (doorName == "RR" || doorName == "rearRight") {
            m_state.doors.rearRightOpen = open;
        }
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::setScenario(SimulationScenario scenario) {
    HealthCallback hCb;
    CommunicationHealth hVal;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_currentScenario = scenario;
        m_faultMode = FaultSimulationMode::NONE;
        m_health = CommunicationHealth::HEALTHY;

        switch (scenario) {
        case SimulationScenario::PARKED:
            m_targetSpeed = 0.0f;
            m_targetGear = domain::Gear::PARK;
            m_targetOperationalState = domain::OperationalState::PARKED;
            m_state.chargingState = domain::ChargingState::DISCONNECTED;
            m_state.ignitionState = domain::IgnitionState::ON;
            if (m_state.speed < 0.1f) {
                m_state.operationalState = domain::OperationalState::PARKED;
                m_state.gear = domain::Gear::PARK;
            }
            break;

        case SimulationScenario::DRIVING:
            m_targetSpeed = 64.0f;
            m_targetGear = domain::Gear::DRIVE;
            m_targetOperationalState = domain::OperationalState::DRIVING;
            m_state.operationalState = domain::OperationalState::DRIVING;
            m_state.gear = domain::Gear::DRIVE;
            m_state.chargingState = domain::ChargingState::DISCONNECTED;
            m_state.ignitionState = domain::IgnitionState::ON;
            // Close doors for driving safety
            m_state.doors.frontLeftOpen = false;
            m_state.doors.frontRightOpen = false;
            m_state.doors.rearLeftOpen = false;
            m_state.doors.rearRightOpen = false;
            break;

        case SimulationScenario::REVERSE:
            m_targetSpeed = 4.0f;
            m_state.speed = 4.0f;
            m_targetGear = domain::Gear::REVERSE;
            m_targetOperationalState = domain::OperationalState::REVERSE;
            m_state.operationalState = domain::OperationalState::REVERSE;
            m_state.gear = domain::Gear::REVERSE;
            m_state.chargingState = domain::ChargingState::DISCONNECTED;
            m_state.ignitionState = domain::IgnitionState::ON;
            break;

        case SimulationScenario::CHARGING:
            m_targetSpeed = 0.0f;
            m_targetGear = domain::Gear::PARK;
            m_targetOperationalState = domain::OperationalState::CHARGING;
            m_state.operationalState = domain::OperationalState::CHARGING;
            m_state.gear = domain::Gear::PARK;
            m_state.chargingState = domain::ChargingState::CHARGING;
            m_state.ignitionState = domain::IgnitionState::ACCESSORY;
            m_state.speed = 0.0f;
            break;

        case SimulationScenario::FAULT:
            m_targetSpeed = 0.0f;
            m_targetGear = domain::Gear::PARK;
            m_targetOperationalState = domain::OperationalState::FAULT;
            m_state.operationalState = domain::OperationalState::FAULT;
            m_state.gear = domain::Gear::PARK;
            m_state.speed = 0.0f;
            break;
        }

        hCb = m_healthCallback;
        hVal = m_health;
    }

    if (hCb) {
        hCb(hVal);
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::setScenario(const std::string& scenarioName) {
    if (scenarioName == "PARKED") {
        setScenario(SimulationScenario::PARKED);
    } else if (scenarioName == "DRIVING") {
        setScenario(SimulationScenario::DRIVING);
    } else if (scenarioName == "REVERSE") {
        setScenario(SimulationScenario::REVERSE);
    } else if (scenarioName == "CHARGING") {
        setScenario(SimulationScenario::CHARGING);
    } else if (scenarioName == "FAULT") {
        setScenario(SimulationScenario::FAULT);
    }
}

SimulationScenario SimulatedVehicleBackend::getScenario() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_currentScenario;
}

void SimulatedVehicleBackend::setFaultMode(FaultSimulationMode faultMode) {
    HealthCallback hCb;
    CommunicationHealth hVal;
    FaultCallback fCb;
    domain::FaultRecord fault{};
    bool emitFault = false;
    bool emitStateChanged = false;

    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_faultMode = faultMode;

        switch (faultMode) {
        case FaultSimulationMode::NONE:
            m_health = CommunicationHealth::HEALTHY;
            if (m_state.operationalState == domain::OperationalState::FAULT) {
                m_state.operationalState = domain::OperationalState::PARKED;
                m_state.gear = domain::Gear::PARK;
            }
            hCb = m_healthCallback;
            hVal = m_health;
            emitStateChanged = true;
            break;

        case FaultSimulationMode::UNAVAILABLE_DATA:
            m_health = CommunicationHealth::DISCONNECTED;
            hCb = m_healthCallback;
            hVal = m_health;
            break;

        case FaultSimulationMode::STALE_DATA:
            m_health = CommunicationHealth::DEGRADED;
            hCb = m_healthCallback;
            hVal = m_health;
            break;

        case FaultSimulationMode::INVALID_DATA:
            m_health = CommunicationHealth::DEGRADED;
            m_state.speed = 999.0f;
            m_state.batterySoc = -50.0f;
            m_state.cabinTemperature = 999.0f;
            fault.type = domain::FaultType::INVALID_RANGE;
            fault.subsystem = "CAN_TRANSCEIVER";
            fault.description = "DBC physical limit violation: speed=999 km/h, soc=-50%";
            fault.timestampMs = m_state.timestampMs;
            fault.isRecoverable = true;
            fCb = m_faultCallback;
            emitFault = true;
            hCb = m_healthCallback;
            hVal = m_health;
            emitStateChanged = true;
            break;
        }
    }

    if (emitFault && fCb) {
        fCb(fault);
    }
    if (hCb) {
        hCb(hVal);
    }
    if (emitStateChanged) {
        notifyStateChanged();
    }
}

void SimulatedVehicleBackend::setFaultMode(const std::string& faultModeName) {
    if (faultModeName == "NONE") {
        setFaultMode(FaultSimulationMode::NONE);
    } else if (faultModeName == "UNAVAILABLE" || faultModeName == "UNAVAILABLE_DATA") {
        setFaultMode(FaultSimulationMode::UNAVAILABLE_DATA);
    } else if (faultModeName == "STALE" || faultModeName == "STALE_DATA") {
        setFaultMode(FaultSimulationMode::STALE_DATA);
    } else if (faultModeName == "INVALID" || faultModeName == "INVALID_DATA") {
        setFaultMode(FaultSimulationMode::INVALID_DATA);
    }
}

FaultSimulationMode SimulatedVehicleBackend::getFaultMode() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_faultMode;
}

void SimulatedVehicleBackend::injectFault(const domain::FaultRecord& fault) {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_state.operationalState = domain::OperationalState::FAULT;
        m_health = CommunicationHealth::DEGRADED;
    }
    if (m_faultCallback) {
        m_faultCallback(fault);
    }
    if (m_healthCallback) {
        m_healthCallback(CommunicationHealth::DEGRADED);
    }
    notifyStateChanged();
}

void SimulatedVehicleBackend::clearFaults() {
    setFaultMode(FaultSimulationMode::NONE);
}

void SimulatedVehicleBackend::stepSimulation(float dtSeconds) {
    bool shouldNotify = false;
    {
        std::lock_guard<std::mutex> lock(m_mutex);

        // If data is unavailable, do not emit any cyclic state frames
        if (m_faultMode == FaultSimulationMode::UNAVAILABLE_DATA) {
            return;
        }

        // If data is stale, do not advance simulation clock or signals
        if (m_faultMode == FaultSimulationMode::STALE_DATA) {
            return;
        }

        // If data is invalid, keep corrupted state active
        if (m_faultMode == FaultSimulationMode::INVALID_DATA) {
            shouldNotify = true;
        } else {
            m_state.timestampMs += static_cast<uint64_t>(dtSeconds * 1000.0f);

            // --- 1. Realistic Speed Slewing ---
            // Smooth natural acceleration (18 km/h per second) and braking (28 km/h per second)
            if (m_state.speed < m_targetSpeed) {
                const float accelRate = 18.0f;
                m_state.speed = std::min(m_targetSpeed, m_state.speed + accelRate * dtSeconds);
            } else if (m_state.speed > m_targetSpeed) {
                const float decelRate = 28.0f;
                m_state.speed = std::max(m_targetSpeed, m_state.speed - decelRate * dtSeconds);
            }

            // Slew-synchronized state & gear transitions
            if (m_state.speed < 0.1f) {
                if (m_targetOperationalState == domain::OperationalState::PARKED ||
                    m_targetOperationalState == domain::OperationalState::CHARGING ||
                    m_targetOperationalState == domain::OperationalState::FAULT) {
                    m_state.operationalState = m_targetOperationalState;
                    m_state.gear = domain::Gear::PARK;
                }
            } else {
                if (m_targetOperationalState == domain::OperationalState::DRIVING) {
                    m_state.operationalState = domain::OperationalState::DRIVING;
                    m_state.gear = domain::Gear::DRIVE;
                } else if (m_targetOperationalState == domain::OperationalState::REVERSE) {
                    m_state.operationalState = domain::OperationalState::REVERSE;
                    m_state.gear = domain::Gear::REVERSE;
                }
            }

            // --- 2. Battery SOC & Range Depletion / Charging ---
            if (m_state.operationalState == domain::OperationalState::DRIVING) {
                const float modeMultiplier = (m_state.driveMode == domain::DriveMode::SPORT) ? 1.35f :
                                             (m_state.driveMode == domain::DriveMode::ECO) ? 0.75f : 1.0f;
                const float drain = (m_state.speed / 100.0f) * 0.035f * modeMultiplier * dtSeconds;
                m_state.batterySoc = std::max(2.0f, m_state.batterySoc - drain);
                m_state.rangeKm = m_state.batterySoc * 5.0f;
                m_state.batteryTemperature = std::min(38.0f, m_state.batteryTemperature + 0.02f * dtSeconds);
            } else if (m_state.operationalState == domain::OperationalState::CHARGING) {
                const float chargeGain = 0.12f * dtSeconds; // ~0.12% per second (~45 kW fast charge simulated)
                m_state.batterySoc = std::min(100.0f, m_state.batterySoc + chargeGain);
                m_state.rangeKm = m_state.batterySoc * 5.0f;
                m_state.chargingState = domain::ChargingState::CHARGING;
                m_state.batteryTemperature = std::min(32.0f, m_state.batteryTemperature + 0.01f * dtSeconds);
            } else {
                if (m_state.batteryTemperature > 24.5f) {
                    m_state.batteryTemperature -= 0.01f * dtSeconds;
                }
            }

            // --- 3. Cabin Temperature Natural Slew ---
            if (m_state.acActive && m_state.fanSpeed > 0) {
                const float fanCoeff = 0.04f + 0.02f * static_cast<float>(m_state.fanSpeed);
                const float deltaT = fanCoeff * dtSeconds;
                if (m_state.cabinTemperature < m_state.targetTemperature) {
                    m_state.cabinTemperature = std::min(m_state.targetTemperature, m_state.cabinTemperature + deltaT);
                } else if (m_state.cabinTemperature > m_state.targetTemperature) {
                    m_state.cabinTemperature = std::max(m_state.targetTemperature, m_state.cabinTemperature - deltaT);
                }
            } else {
                const float leakRate = 0.005f * dtSeconds;
                if (m_state.cabinTemperature < m_state.outsideTemperature) {
                    m_state.cabinTemperature = std::min(m_state.outsideTemperature, m_state.cabinTemperature + leakRate);
                } else if (m_state.cabinTemperature > m_state.outsideTemperature) {
                    m_state.cabinTemperature = std::max(m_state.outsideTemperature, m_state.cabinTemperature - leakRate);
                }
            }

            shouldNotify = true;
        }
    }

    if (shouldNotify) {
        notifyStateChanged();
    }
}

void SimulatedVehicleBackend::registerStateCallback(StateCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_stateCallback = std::move(callback);
}

void SimulatedVehicleBackend::registerHealthCallback(HealthCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_healthCallback = std::move(callback);
}

void SimulatedVehicleBackend::registerFaultCallback(FaultCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_faultCallback = std::move(callback);
}

void SimulatedVehicleBackend::notifyStateChanged() {
    StateCallback cb;
    domain::VehicleState st;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        cb = m_stateCallback;
        st = m_state;
    }
    if (cb) {
        cb(st);
    }
}

} // namespace driveos::vehicle
