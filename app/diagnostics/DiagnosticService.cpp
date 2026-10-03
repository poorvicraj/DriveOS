#include "DiagnosticService.hpp"
#include "domain/VehicleStateManager.hpp"
#include "vehicle/VehicleDataInterface.hpp"
#include <chrono>
#include <algorithm>

namespace driveos::diagnostics {

namespace {
uint64_t currentSystemTimeMs() {
    return static_cast<uint64_t>(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count());
}
}

DiagnosticService::DiagnosticService(domain::VehicleStateManager* stateManager,
                                     vehicle::VehicleDataInterface* vdi)
    : m_stateManager(stateManager)
    , m_vdi(vdi)
{
    if (m_stateManager) {
        setStateManager(m_stateManager);
    } else if (m_vdi) {
        setVehicleDataInterface(m_vdi);
    }
}

std::vector<DtcRecord> DiagnosticService::getActiveDtcs() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    std::vector<DtcRecord> activeList;
    for (const auto& record : m_dtcStore) {
        if (record.status == DtcStatus::ACTIVE || record.status == DtcStatus::CONFIRMED) {
            activeList.push_back(record);
        }
    }
    return activeList;
}

std::vector<DtcRecord> DiagnosticService::getAllDtcs() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_dtcStore;
}

std::optional<DtcRecord> DiagnosticService::getDtc(const std::string& codeOrId) const {
    std::lock_guard<std::mutex> lock(m_mutex);
    for (const auto& record : m_dtcStore) {
        if (record.code == codeOrId || record.identifier == codeOrId) {
            return record;
        }
    }
    return std::nullopt;
}

bool DiagnosticService::hasActiveFaults() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    for (const auto& record : m_dtcStore) {
        if (record.status == DtcStatus::ACTIVE || record.status == DtcStatus::CONFIRMED) {
            return true;
        }
    }
    return false;
}

std::string DiagnosticService::getPrimaryFaultSummary() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    for (const auto& record : m_dtcStore) {
        if (record.status == DtcStatus::ACTIVE || record.status == DtcStatus::CONFIRMED) {
            if (!record.description.empty()) {
                return record.description;
            }
            if (!record.identifier.empty()) {
                return record.identifier;
            }
            return record.code;
        }
    }
    return "Systems normal";
}

void DiagnosticService::clearDtcs() {
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        for (auto& record : m_dtcStore) {
            record.status = DtcStatus::INACTIVE;
        }
    }

    // Restore state manager and HAL backend without leaving stale fault state
    if (m_stateManager) {
        if (m_stateManager->getOperationalState() == domain::OperationalState::FAULT) {
            m_stateManager->setOperationalState(domain::OperationalState::PARKED);
        }
        m_stateManager->setCommunicationHealth(vehicle::CommunicationHealth::HEALTHY);
    }

    if (m_vdi) {
        m_vdi->setFaultMode("NONE");
    }

    notifyObservers();
}

bool DiagnosticService::clearDtc(const std::string& codeOrId) {
    bool found = false;
    bool anyActiveRemaining = false;

    {
        std::lock_guard<std::mutex> lock(m_mutex);
        for (auto& record : m_dtcStore) {
            if (record.code == codeOrId || record.identifier == codeOrId) {
                record.status = DtcStatus::INACTIVE;
                found = true;
            } else if (record.status == DtcStatus::ACTIVE || record.status == DtcStatus::CONFIRMED) {
                anyActiveRemaining = true;
            }
        }
    }

    if (found) {
        if (!anyActiveRemaining) {
            if (m_stateManager) {
                if (m_stateManager->getOperationalState() == domain::OperationalState::FAULT) {
                    m_stateManager->setOperationalState(domain::OperationalState::PARKED);
                }
                m_stateManager->setCommunicationHealth(vehicle::CommunicationHealth::HEALTHY);
            }
            if (m_vdi) {
                m_vdi->setFaultMode("NONE");
            }
        }
        notifyObservers();
    }

    return found;
}

void DiagnosticService::recordFault(const std::string& code,
                                    const std::string& description,
                                    DtcSeverity severity) {
    recordFault(code, "", description, severity);
}

void DiagnosticService::recordFault(const std::string& code,
                                    const std::string& identifier,
                                    const std::string& description,
                                    DtcSeverity severity) {
    DtcRecord recordCopy;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        auto it = std::find_if(m_dtcStore.begin(), m_dtcStore.end(),
                               [&](const DtcRecord& rec) {
                                   return rec.code == code || (!identifier.empty() && rec.identifier == identifier);
                               });

        const uint64_t now = currentSystemTimeMs();

        if (it != m_dtcStore.end()) {
            it->status = DtcStatus::ACTIVE;
            it->severity = severity;
            it->description = description;
            if (!identifier.empty()) {
                it->identifier = identifier;
            }
            it->timestampMs = now;
            it->occurrenceCount++;
            recordCopy = *it;
        } else {
            DtcRecord newRecord;
            newRecord.code = code;
            newRecord.identifier = identifier.empty() ? code : identifier;
            newRecord.description = description;
            newRecord.severity = severity;
            newRecord.status = DtcStatus::ACTIVE;
            newRecord.timestampMs = now;
            newRecord.occurrenceCount = 1;
            m_dtcStore.push_back(newRecord);
            recordCopy = newRecord;
        }
    }

    notifyFault(recordCopy);
    notifyObservers();
}

bool DiagnosticService::injectFault(const std::string& faultKey) {
    if (faultKey == "HVAC_SENSOR_TIMEOUT" || faultKey == DtcCode::HVAC_SENSOR_TIMEOUT) {
        recordFault(DtcCode::HVAC_SENSOR_TIMEOUT,
                    "HVAC_SENSOR_TIMEOUT",
                    "HVAC sensor timeout",
                    DtcSeverity::WARNING);
        if (m_stateManager) {
            m_stateManager->setCommunicationHealth(vehicle::CommunicationHealth::DEGRADED);
        }
        return true;
    }

    if (faultKey == "VEHICLE_DATA_TIMEOUT" || faultKey == DtcCode::VEHICLE_DATA_TIMEOUT) {
        recordFault(DtcCode::VEHICLE_DATA_TIMEOUT,
                    "VEHICLE_DATA_TIMEOUT",
                    "Vehicle data unavailable",
                    DtcSeverity::CRITICAL);
        if (m_stateManager) {
            m_stateManager->setOperationalState(domain::OperationalState::FAULT);
            m_stateManager->setCommunicationHealth(vehicle::CommunicationHealth::DISCONNECTED);
        }
        if (m_vdi) {
            m_vdi->setFaultMode("UNAVAILABLE_DATA");
        }
        return true;
    }

    if (faultKey == "DOOR_SENSOR_FAULT" || faultKey == DtcCode::DOOR_SENSOR_FAULT) {
        recordFault(DtcCode::DOOR_SENSOR_FAULT,
                    "DOOR_SENSOR_FAULT",
                    "Door sensor fault: latch circuit range",
                    DtcSeverity::WARNING);
        if (m_stateManager) {
            m_stateManager->setCommunicationHealth(vehicle::CommunicationHealth::DEGRADED);
        }
        return true;
    }

    if (faultKey == "CAN_TIMEOUT" || faultKey == DtcCode::CAN_TIMEOUT) {
        recordFault(DtcCode::CAN_TIMEOUT,
                    "CAN_TIMEOUT",
                    "CAN bus communication timeout",
                    DtcSeverity::CRITICAL);
        if (m_stateManager) {
            m_stateManager->setOperationalState(domain::OperationalState::FAULT);
            m_stateManager->setCommunicationHealth(vehicle::CommunicationHealth::DISCONNECTED);
        }
        if (m_vdi) {
            m_vdi->setFaultMode("UNAVAILABLE");
        }
        return true;
    }

    if (faultKey == "INVALID_VEHICLE_SIGNAL" || faultKey == DtcCode::INVALID_VEHICLE_SIGNAL) {
        recordFault(DtcCode::INVALID_VEHICLE_SIGNAL,
                    "INVALID_VEHICLE_SIGNAL",
                    "Invalid vehicle signal: physical bounds violation",
                    DtcSeverity::WARNING);
        if (m_stateManager) {
            m_stateManager->setCommunicationHealth(vehicle::CommunicationHealth::DEGRADED);
        }
        if (m_vdi) {
            m_vdi->setFaultMode("INVALID_DATA");
        }
        return true;
    }

    if (faultKey == "HVAC_SENSOR_UNAVAILABLE" || faultKey == DtcCode::HVAC_SENSOR_UNAVAILABLE) {
        recordFault(DtcCode::HVAC_SENSOR_UNAVAILABLE,
                    "HVAC_SENSOR_UNAVAILABLE",
                    "HVAC sensor unavailable: sensor link down",
                    DtcSeverity::WARNING);
        if (m_stateManager) {
            m_stateManager->setCommunicationHealth(vehicle::CommunicationHealth::DEGRADED);
        }
        return true;
    }

    // Fallback for custom generic fault
    recordFault("GEN01", faultKey, faultKey, DtcSeverity::WARNING);
    return true;
}

void DiagnosticService::registerDtcCallback(DtcListCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_dtcCallbacks.push_back(std::move(callback));
}

void DiagnosticService::registerFaultCallback(FaultCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_faultCallbacks.push_back(std::move(callback));
}

void DiagnosticService::setStateManager(domain::VehicleStateManager* stateManager) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_stateManager = stateManager;
    if (m_stateManager) {
        m_stateManager->registerFaultCallback([this](const domain::FaultRecord& fault) {
            if (fault.type == domain::FaultType::COMMUNICATION_TIMEOUT) {
                recordFault(DtcCode::CAN_TIMEOUT, "CAN_TIMEOUT", fault.description, DtcSeverity::CRITICAL);
            } else if (fault.type == domain::FaultType::DATA_UNAVAILABLE) {
                recordFault(DtcCode::VEHICLE_DATA_TIMEOUT, "VEHICLE_DATA_TIMEOUT", fault.description, DtcSeverity::CRITICAL);
            } else if (fault.type == domain::FaultType::INVALID_RANGE) {
                recordFault(DtcCode::INVALID_VEHICLE_SIGNAL, "INVALID_VEHICLE_SIGNAL", fault.description, DtcSeverity::WARNING);
            } else if (fault.type == domain::FaultType::SENSOR_FAILURE) {
                recordFault(DtcCode::HVAC_SENSOR_TIMEOUT, "HVAC_SENSOR_TIMEOUT", fault.description, DtcSeverity::WARNING);
            } else {
                recordFault("SYS01", "SYSTEM_FAULT", fault.description, DtcSeverity::WARNING);
            }
        });

        m_stateManager->registerHealthCallback([this](vehicle::CommunicationHealth health) {
            if (health == vehicle::CommunicationHealth::DISCONNECTED ||
                health == vehicle::CommunicationHealth::BUS_OFF) {
                recordFault(DtcCode::VEHICLE_DATA_TIMEOUT,
                            "VEHICLE_DATA_TIMEOUT",
                            "Vehicle data unavailable",
                            DtcSeverity::CRITICAL);
            }
        });
    }
}

void DiagnosticService::setVehicleDataInterface(vehicle::VehicleDataInterface* vdi) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_vdi = vdi;
    if (m_vdi && !m_stateManager) {
        m_vdi->registerFaultCallback([this](const domain::FaultRecord& fault) {
            if (fault.type == domain::FaultType::COMMUNICATION_TIMEOUT) {
                recordFault(DtcCode::CAN_TIMEOUT, "CAN_TIMEOUT", fault.description, DtcSeverity::CRITICAL);
            } else if (fault.type == domain::FaultType::DATA_UNAVAILABLE) {
                recordFault(DtcCode::VEHICLE_DATA_TIMEOUT, "VEHICLE_DATA_TIMEOUT", fault.description, DtcSeverity::CRITICAL);
            } else if (fault.type == domain::FaultType::INVALID_RANGE) {
                recordFault(DtcCode::INVALID_VEHICLE_SIGNAL, "INVALID_VEHICLE_SIGNAL", fault.description, DtcSeverity::WARNING);
            } else if (fault.type == domain::FaultType::SENSOR_FAILURE) {
                recordFault(DtcCode::HVAC_SENSOR_TIMEOUT, "HVAC_SENSOR_TIMEOUT", fault.description, DtcSeverity::WARNING);
            } else {
                recordFault("SYS01", "SYSTEM_FAULT", fault.description, DtcSeverity::WARNING);
            }
        });

        m_vdi->registerHealthCallback([this](vehicle::CommunicationHealth health) {
            if (health == vehicle::CommunicationHealth::DISCONNECTED ||
                health == vehicle::CommunicationHealth::BUS_OFF) {
                recordFault(DtcCode::VEHICLE_DATA_TIMEOUT,
                            "VEHICLE_DATA_TIMEOUT",
                            "Vehicle data unavailable",
                            DtcSeverity::CRITICAL);
            }
        });
    }
}

void DiagnosticService::notifyObservers() {
    std::vector<DtcListCallback> callbacks;
    std::vector<DtcRecord> currentDtcs;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        callbacks = m_dtcCallbacks;
        currentDtcs = m_dtcStore;
    }
    for (const auto& cb : callbacks) {
        if (cb) cb(currentDtcs);
    }
}

void DiagnosticService::notifyFault(const DtcRecord& record) {
    std::vector<FaultCallback> callbacks;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        callbacks = m_faultCallbacks;
    }
    for (const auto& cb : callbacks) {
        if (cb) cb(record);
    }
}

} // namespace driveos::diagnostics
