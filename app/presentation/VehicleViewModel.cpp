#include "VehicleViewModel.hpp"
#include <algorithm>
#include <cmath>

namespace driveos::presentation {

VehicleViewModel::VehicleViewModel(domain::VehicleService* vehicleService,
                                   domain::SafetyPolicy* safetyPolicy,
                                   vehicle::VehicleDataInterface* vdi,
                                   diagnostics::DiagnosticService* diagService,
                                   QObject* parent)
    : BaseViewModel(parent)
    , m_vehicleService(vehicleService)
    , m_safetyPolicy(safetyPolicy)
    , m_vdi(vdi)
    , m_diagService(diagService)
{
    if (m_vehicleService) {
        m_cachedState = m_vehicleService->getVehicleState();

        m_vehicleService->registerStateCallback([this](const domain::VehicleState& state) {
            syncFromVehicleState(state);
        });

        m_vehicleService->registerSafetyWarningCallback([this](const std::string& reason) {
            emit restrictionNoticeTriggered(
                QStringLiteral("Distraction Warning"),
                QString::fromStdString(reason));
        });

        m_vehicleService->registerHealthCallback([this](vehicle::CommunicationHealth health) {
            if (health == vehicle::CommunicationHealth::DISCONNECTED) {
                emit restrictionNoticeTriggered(
                    QStringLiteral("Communication Offline"),
                    QStringLiteral("Vehicle telemetry bus disconnected. Operating in degraded fallback."));
            }
            emit vehicleStateChanged();
            emit diagnosticsChanged();
        });
    }

    if (m_diagService) {
        m_diagService->registerDtcCallback([this](const std::vector<diagnostics::DtcRecord>& /*dtcs*/) {
            emit diagnosticsChanged();
            emit vehicleStateChanged();
        });

        m_diagService->registerFaultCallback([this](const diagnostics::DtcRecord& dtc) {
            emit restrictionNoticeTriggered(
                QStringLiteral("Diagnostic Fault Recorded"),
                QString("[%1] %2").arg(QString::fromStdString(dtc.code), QString::fromStdString(dtc.description)));
            emit diagnosticsChanged();
            emit vehicleStateChanged();
        });
    }
}

void VehicleViewModel::syncFromVehicleState(const domain::VehicleState& state) {
    const bool wasRestricted = isRestricted();
    const QString prevMode = driveMode();
    const QString prevState = vehicleState();
    const float prevSoc = m_cachedState.batterySoc;

    m_cachedState = state;

    if (prevState != vehicleState()) {
        emit vehicleStateChanged();
    }
    if (prevMode != driveMode()) {
        emit driveModeChanged();
    }
    if (std::abs(prevSoc - state.batterySoc) > 0.01f) {
        emit batterySocChanged();
    }
    emit doorsChanged();

    if (wasRestricted != isRestricted()) {
        emit restrictionChanged();
    }

    emit diagnosticsChanged();
}

QString VehicleViewModel::vehicleState() const {
    switch (m_cachedState.operationalState) {
    case domain::OperationalState::PARKED: return QStringLiteral("PARKED");
    case domain::OperationalState::DRIVING: return QStringLiteral("DRIVING");
    case domain::OperationalState::REVERSE: return QStringLiteral("REVERSE");
    case domain::OperationalState::CHARGING: return QStringLiteral("CHARGING");
    case domain::OperationalState::FAULT: return QStringLiteral("FAULT");
    }
    return QStringLiteral("PARKED");
}

QString VehicleViewModel::stateDescription() const {
    switch (m_cachedState.operationalState) {
    case domain::OperationalState::PARKED:
        return QStringLiteral("Parked • Systems Ready");
    case domain::OperationalState::DRIVING:
        return QStringLiteral("Driving • Road Dynamics Active");
    case domain::OperationalState::REVERSE:
        return QStringLiteral("Reverse • Rear Sensors Active");
    case domain::OperationalState::CHARGING:
        return QStringLiteral("Charging • Fast DC Connected");
    case domain::OperationalState::FAULT:
        return QStringLiteral("Degraded • Check Diagnostics");
    }
    return QStringLiteral("Vehicle Operational");
}

float VehicleViewModel::speed() const {
    return m_cachedState.speed;
}

QString VehicleViewModel::speedFormatted() const {
    return QString::number(std::round(m_cachedState.speed));
}

float VehicleViewModel::batterySoc() const {
    return m_cachedState.batterySoc;
}

QString VehicleViewModel::batterySocFormatted() const {
    return QString::number(std::round(m_cachedState.batterySoc)) + QStringLiteral("%");
}

float VehicleViewModel::rangeKm() const {
    return m_cachedState.rangeKm;
}

QString VehicleViewModel::rangeKmFormatted() const {
    return QString::number(std::round(m_cachedState.rangeKm)) + QStringLiteral(" km");
}

float VehicleViewModel::batteryTemperature() const {
    return m_cachedState.batteryTemperature;
}

QString VehicleViewModel::batteryTemperatureFormatted() const {
    return QString::number(m_cachedState.batteryTemperature, 'f', 1) + QStringLiteral("°C");
}

QString VehicleViewModel::driveMode() const {
    switch (m_cachedState.driveMode) {
    case domain::DriveMode::NORMAL: return QStringLiteral("COMFORT");
    case domain::DriveMode::ECO: return QStringLiteral("ECO");
    case domain::DriveMode::SPORT: return QStringLiteral("SPORT");
    }
    return QStringLiteral("COMFORT");
}

QString VehicleViewModel::ignitionState() const {
    switch (m_cachedState.ignitionState) {
    case domain::IgnitionState::OFF: return QStringLiteral("OFF");
    case domain::IgnitionState::ACCESSORY: return QStringLiteral("ACC");
    case domain::IgnitionState::ON: return QStringLiteral("ON");
    }
    return QStringLiteral("ON");
}

QString VehicleViewModel::gear() const {
    switch (m_cachedState.gear) {
    case domain::Gear::PARK: return QStringLiteral("P");
    case domain::Gear::REVERSE: return QStringLiteral("R");
    case domain::Gear::NEUTRAL: return QStringLiteral("N");
    case domain::Gear::DRIVE: return QStringLiteral("D");
    }
    return QStringLiteral("P");
}

bool VehicleViewModel::frontLeftDoorOpen() const {
    return m_cachedState.doors.frontLeftOpen;
}

bool VehicleViewModel::frontRightDoorOpen() const {
    return m_cachedState.doors.frontRightOpen;
}

bool VehicleViewModel::rearLeftDoorOpen() const {
    return m_cachedState.doors.rearLeftOpen;
}

bool VehicleViewModel::rearRightDoorOpen() const {
    return m_cachedState.doors.rearRightOpen;
}

bool VehicleViewModel::doorsAllClosed() const {
    return !m_cachedState.doors.frontLeftOpen &&
           !m_cachedState.doors.frontRightOpen &&
           !m_cachedState.doors.rearLeftOpen &&
           !m_cachedState.doors.rearRightOpen;
}

bool VehicleViewModel::doorsLocked() const {
    return m_doorsLocked;
}

bool VehicleViewModel::isRestricted() const {
    return m_safetyPolicy ?
        !m_safetyPolicy->isVehicleConfigurationAllowed(m_cachedState) :
        (m_cachedState.speed > 0.5f);
}

bool VehicleViewModel::isDriving() const {
    return m_cachedState.operationalState == domain::OperationalState::DRIVING;
}

bool VehicleViewModel::isParked() const {
    return m_cachedState.operationalState == domain::OperationalState::PARKED;
}

bool VehicleViewModel::isReverse() const {
    return m_cachedState.operationalState == domain::OperationalState::REVERSE;
}

bool VehicleViewModel::isCharging() const {
    return m_cachedState.operationalState == domain::OperationalState::CHARGING;
}

bool VehicleViewModel::hasFault() const {
    return m_cachedState.operationalState == domain::OperationalState::FAULT;
}

bool VehicleViewModel::hasActiveFaults() const {
    if (m_diagService) {
        return m_diagService->hasActiveFaults() || hasFault();
    }
    return hasFault();
}

QString VehicleViewModel::diagnosticSummary() const {
    if (m_diagService) {
        return QString::fromStdString(m_diagService->getPrimaryFaultSummary());
    }
    if (hasFault()) {
        return QStringLiteral("Vehicle data unavailable");
    }
    return QStringLiteral("Systems normal");
}

int VehicleViewModel::activeDtcCount() const {
    if (m_diagService) {
        return static_cast<int>(m_diagService->getActiveDtcs().size());
    }
    return hasFault() ? 1 : 0;
}

QVariantList VehicleViewModel::activeDtcs() const {
    QVariantList list;
    if (m_diagService) {
        for (const auto& dtc : m_diagService->getActiveDtcs()) {
            QVariantMap map;
            map[QStringLiteral("code")] = QString::fromStdString(dtc.code);
            map[QStringLiteral("identifier")] = QString::fromStdString(dtc.identifier);
            map[QStringLiteral("description")] = QString::fromStdString(dtc.description);
            map[QStringLiteral("severity")] = (dtc.severity == diagnostics::DtcSeverity::CRITICAL) ? QStringLiteral("CRITICAL") :
                                              ((dtc.severity == diagnostics::DtcSeverity::WARNING) ? QStringLiteral("WARNING") : QStringLiteral("INFO"));
            map[QStringLiteral("status")] = (dtc.status == diagnostics::DtcStatus::ACTIVE) ? QStringLiteral("ACTIVE") : QStringLiteral("INACTIVE");
            map[QStringLiteral("timestampMs")] = static_cast<qulonglong>(dtc.timestampMs);
            map[QStringLiteral("occurrenceCount")] = static_cast<int>(dtc.occurrenceCount);
            list.append(map);
        }
    }
    return list;
}

void VehicleViewModel::setDriveMode(const QString& mode) {
    if (isRestricted()) {
        emit restrictionNoticeTriggered(
            QStringLiteral("Unavailable while driving"),
            QStringLiteral("Drive dynamics mode cannot be adjusted while vehicle is in motion."));
        return;
    }

    domain::DriveMode dm = domain::DriveMode::NORMAL;
    if (mode == QStringLiteral("ECO")) dm = domain::DriveMode::ECO;
    else if (mode == QStringLiteral("SPORT")) dm = domain::DriveMode::SPORT;

    if (m_vehicleService) {
        m_vehicleService->setDriveMode(dm);
    } else if (m_vdi) {
        m_vdi->setDriveMode(dm);
    }
    emit driveModeChanged();
}

void VehicleViewModel::toggleAutoHeadlights() {
    if (isRestricted()) {
        emit restrictionNoticeTriggered(
            QStringLiteral("Unavailable while driving"),
            QStringLiteral("Lighting settings are locked while driving for road safety."));
        return;
    }
    m_autoHeadlights = !m_autoHeadlights;
    emit settingsChanged();
}

void VehicleViewModel::toggleAutoLock() {
    if (isRestricted()) {
        emit restrictionNoticeTriggered(
            QStringLiteral("Unavailable while driving"),
            QStringLiteral("Access configuration cannot be altered while vehicle is in motion."));
        return;
    }
    m_autoLock = !m_autoLock;
    emit settingsChanged();
}

void VehicleViewModel::setDisplayBrightness(int level) {
    m_displayBrightness = std::clamp(level, 10, 100);
    emit settingsChanged();
}

void VehicleViewModel::adjustDisplayBrightness(int delta) {
    setDisplayBrightness(m_displayBrightness + delta);
}

void VehicleViewModel::toggleOnePedalDrive() {
    if (isRestricted()) {
        emit restrictionNoticeTriggered(
            QStringLiteral("Unavailable while driving"),
            QStringLiteral("Regenerative braking profile cannot be toggled while vehicle is in motion."));
        return;
    }
    m_onePedalDrive = !m_onePedalDrive;
    emit settingsChanged();
}

void VehicleViewModel::toggleChildLock() {
    if (isRestricted()) {
        emit restrictionNoticeTriggered(
            QStringLiteral("Unavailable while driving"),
            QStringLiteral("Child safety lock cannot be modified while driving."));
        return;
    }
    m_childLock = !m_childLock;
    emit settingsChanged();
}

void VehicleViewModel::toggleDoorLock() {
    if (isRestricted()) {
        emit restrictionNoticeTriggered(
            QStringLiteral("Unavailable while driving"),
            QStringLiteral("Door lock override restricted while vehicle is in motion."));
        return;
    }
    m_doorsLocked = !m_doorsLocked;
    if (m_vehicleService) {
        m_vehicleService->setDoorLock(m_doorsLocked);
    }
    emit doorsChanged();
}

void VehicleViewModel::toggleDoor(const QString& doorName) {
    if (isRestricted()) {
        emit restrictionNoticeTriggered(
            QStringLiteral("Unavailable while driving"),
            QStringLiteral("Door closures cannot be toggled while vehicle is in motion."));
        return;
    }
    if (m_vehicleService) {
        m_vehicleService->toggleDoor(doorName.toStdString());
    } else if (m_vdi) {
        m_vdi->toggleDoor(doorName.toStdString());
    }
}

void VehicleViewModel::setVehicleState(const QString& state) {
    if (m_vehicleService) {
        m_vehicleService->setScenario(state.toStdString());
    } else if (m_vdi) {
        m_vdi->setScenario(state.toStdString());
    }

    if (state == QStringLiteral("FAULT")) {
        injectFault(QStringLiteral("VEHICLE_DATA_TIMEOUT"));
    }
}

void VehicleViewModel::setScenario(const QString& scenario) {
    setVehicleState(scenario);
}

void VehicleViewModel::setFaultMode(const QString& faultMode) {
    if (m_vehicleService) {
        m_vehicleService->setFaultMode(faultMode.toStdString());
    } else if (m_vdi) {
        m_vdi->setFaultMode(faultMode.toStdString());
    }
}

void VehicleViewModel::injectFault(const QString& faultKey) {
    if (m_diagService) {
        m_diagService->injectFault(faultKey.toStdString());
    } else {
        setFaultMode(faultKey);
    }
    emit diagnosticsChanged();
    emit vehicleStateChanged();
}

void VehicleViewModel::clearFaults() {
    if (m_diagService) {
        m_diagService->clearDtcs();
    }
    if (m_vehicleService) {
        m_vehicleService->setFaultMode("NONE");
        m_vehicleService->setOperationalState(domain::OperationalState::PARKED);
    } else if (m_vdi) {
        m_vdi->setFaultMode("NONE");
    }
    emit diagnosticsChanged();
    emit vehicleStateChanged();
}

void VehicleViewModel::clearDtc(const QString& codeOrId) {
    if (m_diagService) {
        m_diagService->clearDtc(codeOrId.toStdString());
    }
    emit diagnosticsChanged();
    emit vehicleStateChanged();
}

} // namespace driveos::presentation
