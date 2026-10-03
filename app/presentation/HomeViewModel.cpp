#include "HomeViewModel.hpp"
#include <QDateTime>
#include <algorithm>

namespace driveos::presentation {

HomeViewModel::HomeViewModel(domain::VehicleService* vehicleService,
                             domain::SafetyPolicy* safetyPolicy,
                             vehicle::VehicleDataInterface* vdi,
                             domain::ClimateService* climateService,
                             domain::MediaService* mediaService,
                             domain::NavigationService* navService,
                             QObject* parent)
    : BaseViewModel(parent)
    , m_vehicleService(vehicleService)
    , m_safetyPolicy(safetyPolicy)
    , m_vdi(vdi)
    , m_climateService(climateService)
    , m_mediaService(mediaService)
    , m_navService(navService)
{
    // Setup vehicle service callbacks
    if (m_vehicleService) {
        m_vehicleService->registerStateCallback([this](const domain::VehicleState& state) {
            handleStateUpdate(state);
        });

        m_vehicleService->registerSafetyWarningCallback([this](const std::string& reason) {
            emit userNotificationRequested(QStringLiteral("Driver Distraction Lockout"),
                                           QString::fromStdString(reason));
        });

        m_vehicleService->registerHealthCallback([this](vehicle::CommunicationHealth health) {
            handleHealthUpdate(health);
        });

        handleStateUpdate(m_vehicleService->getVehicleState());
        handleHealthUpdate(m_vehicleService->getHealth());
    }

    // Setup MediaService synchronization (Single Source of Truth)
    if (m_mediaService) {
        m_mediaService->registerTrackCallback([this](const domain::MediaTrack& trk) {
            m_mediaTitle = QString::fromStdString(trk.title);
            m_mediaArtist = QString::fromStdString(trk.artist);
            m_mediaDurationSec = trk.durationSec;
            m_mediaElapsedSec = trk.elapsedSec;
            emit mediaChanged();
            emit mediaProgressChanged();
        });

        m_mediaService->registerPlaybackCallback([this](domain::PlaybackState st) {
            m_isMediaPlaying = (st == domain::PlaybackState::PLAYING);
            emit mediaPlaybackChanged(m_isMediaPlaying);
        });

        auto cur = m_mediaService->getCurrentTrack();
        m_mediaTitle = QString::fromStdString(cur.title);
        m_mediaArtist = QString::fromStdString(cur.artist);
        m_mediaDurationSec = cur.durationSec;
        m_mediaElapsedSec = cur.elapsedSec;
        m_isMediaPlaying = (m_mediaService->getPlaybackState() == domain::PlaybackState::PLAYING);
    }

    // Setup ClimateService synchronization (Single Source of Truth)
    if (m_climateService) {
        m_climateService->registerClimateCallback([this](float cabinTemp, float targetTemp, int fanSpeed, bool acActive) {
            m_cabinTemperature = cabinTemp;
            m_targetTemperature = targetTemp;
            m_fanSpeed = fanSpeed;
            m_isAcActive = acActive;
            emit cabinTemperatureChanged(m_cabinTemperature);
            emit targetTemperatureChanged(m_targetTemperature);
            emit fanSpeedChanged(m_fanSpeed);
            emit isAcActiveChanged(m_isAcActive);
        });

        m_cabinTemperature = m_climateService->getCabinTemperature();
        m_targetTemperature = m_climateService->getTargetTemperature();
        m_fanSpeed = m_climateService->getFanSpeed();
        m_isAcActive = m_climateService->isACActive();
    }

    // Setup NavigationService synchronization
    if (m_navService) {
        m_navService->registerObserver([this]() {
            emit navChanged();
        });
    }

    // Setup live clock update timer
    m_clockTimer = new QTimer(this);
    connect(m_clockTimer, &QTimer::timeout, this, &HomeViewModel::updateClock);
    m_clockTimer->start(5000);
    updateClock();

    // Setup simulated media playback progress timer
    m_playbackTimer = new QTimer(this);
    connect(m_playbackTimer, &QTimer::timeout, this, [this]() {
        if (m_isMediaPlaying) {
            m_mediaElapsedSec++;
            if (m_mediaElapsedSec >= m_mediaDurationSec) {
                m_mediaElapsedSec = 0;
            }
            emit mediaProgressChanged();
        }
    });
    m_playbackTimer->start(1000);
}

QString HomeViewModel::speedFormatted() const {
    if (m_health == vehicle::CommunicationHealth::DISCONNECTED) {
        return QStringLiteral("--");
    }
    return QString::number(static_cast<int>(m_speed));
}

QString HomeViewModel::batterySocFormatted() const {
    if (m_health == vehicle::CommunicationHealth::DISCONNECTED) {
        return QStringLiteral("--");
    }
    return QString::number(static_cast<int>(m_batterySoc)) + QStringLiteral("%");
}

QString HomeViewModel::rangeKmFormatted() const {
    if (m_health == vehicle::CommunicationHealth::DISCONNECTED) {
        return QStringLiteral("--");
    }
    return QString::number(static_cast<int>(m_rangeKm)) + QStringLiteral(" km");
}

QString HomeViewModel::gear() const {
    switch (m_gear) {
    case domain::Gear::PARK:    return QStringLiteral("P");
    case domain::Gear::REVERSE: return QStringLiteral("R");
    case domain::Gear::NEUTRAL: return QStringLiteral("N");
    case domain::Gear::DRIVE:   return QStringLiteral("D");
    }
    return QStringLiteral("P");
}

QString HomeViewModel::driveMode() const {
    switch (m_driveMode) {
    case domain::DriveMode::ECO:    return QStringLiteral("ECO");
    case domain::DriveMode::NORMAL: return QStringLiteral("COMFORT");
    case domain::DriveMode::SPORT:  return QStringLiteral("SPORT");
    }
    return QStringLiteral("COMFORT");
}

QString HomeViewModel::systemStatus() const {
    if (m_health == vehicle::CommunicationHealth::BUS_OFF || m_vehicleContextState == QStringLiteral("FAULT")) {
        return QStringLiteral("SYSTEM FAULT");
    }
    if (m_health == vehicle::CommunicationHealth::DISCONNECTED) {
        return QStringLiteral("OFFLINE");
    }
    if (m_health == vehicle::CommunicationHealth::DEGRADED) {
        return QStringLiteral("DEGRADED");
    }
    return QStringLiteral("OPERATIONAL");
}

bool HomeViewModel::isDegraded() const {
    return m_health != vehicle::CommunicationHealth::HEALTHY ||
           m_vehicleContextState == QStringLiteral("FAULT");
}

bool HomeViewModel::hasFault() const {
    return m_vehicleContextState == QStringLiteral("FAULT") ||
           m_health == vehicle::CommunicationHealth::BUS_OFF;
}

QString HomeViewModel::communicationHealth() const {
    switch (m_health) {
    case vehicle::CommunicationHealth::HEALTHY:      return QStringLiteral("HEALTHY");
    case vehicle::CommunicationHealth::DEGRADED:     return QStringLiteral("DEGRADED");
    case vehicle::CommunicationHealth::DISCONNECTED: return QStringLiteral("DISCONNECTED");
    case vehicle::CommunicationHealth::BUS_OFF:      return QStringLiteral("BUS_OFF");
    }
    return QStringLiteral("HEALTHY");
}

QString HomeViewModel::vehicleContextSubtitle() const {
    if (m_vehicleContextState == QStringLiteral("PARKED")) {
        return QStringLiteral("Ready to drive");
    } else if (m_vehicleContextState == QStringLiteral("DRIVING")) {
        return QStringLiteral("On the road");
    } else if (m_vehicleContextState == QStringLiteral("REVERSE")) {
        return QStringLiteral("Reverse maneuvering • Obstacle assist");
    } else if (m_vehicleContextState == QStringLiteral("CHARGING")) {
        return QStringLiteral("Charging • 45 kW DC Fast");
    } else if (m_vehicleContextState == QStringLiteral("FAULT")) {
        return QStringLiteral("Vehicle data unavailable • System fault");
    }
    return QStringLiteral("Ready to drive");
}

QString HomeViewModel::greetingText() const {
    const int hour = QTime::currentTime().hour();
    if (hour >= 4 && hour < 12) {
        return QStringLiteral("GOOD MORNING");
    } else if (hour >= 12 && hour < 17) {
        return QStringLiteral("GOOD AFTERNOON");
    } else {
        return QStringLiteral("GOOD EVENING");
    }
}

QString HomeViewModel::cabinTemperatureFormatted() const {
    return QString::number(m_cabinTemperature, 'f', 1) + QStringLiteral("°C");
}

QString HomeViewModel::targetTemperatureFormatted() const {
    return QString::number(m_targetTemperature, 'f', 1) + QStringLiteral("°C");
}

QString HomeViewModel::mediaElapsedFormatted() const {
    const int mins = m_mediaElapsedSec / 60;
    const int secs = m_mediaElapsedSec % 60;
    return QStringLiteral("%1:%2").arg(mins).arg(secs, 2, 10, QChar('0'));
}

QString HomeViewModel::mediaDurationFormatted() const {
    const int mins = m_mediaDurationSec / 60;
    const int secs = m_mediaDurationSec % 60;
    return QStringLiteral("%1:%2").arg(mins).arg(secs, 2, 10, QChar('0'));
}

float HomeViewModel::mediaProgress() const noexcept {
    if (m_mediaDurationSec == 0) return 0.0f;
    return static_cast<float>(m_mediaElapsedSec) / static_cast<float>(m_mediaDurationSec);
}

QString HomeViewModel::navDestination() const {
    if (!m_navService) return QStringLiteral("Home → Mysuru Palace");
    return QStringLiteral("Home → ") + QString::fromStdString(m_navService->getActiveDestination().name);
}

QString HomeViewModel::navEta() const {
    if (!m_navService) return QStringLiteral("18 min");
    return QString::number(m_navService->getActiveDestination().etaMinutes) + QStringLiteral(" min");
}

QString HomeViewModel::navDistance() const {
    if (!m_navService) return QStringLiteral("8.4 km");
    return QString::number(m_navService->getActiveDestination().distanceKm, 'f', 1) + QStringLiteral(" km");
}

QString HomeViewModel::navManeuver() const {
    if (!m_navService) return QStringLiteral("In 450 m, turn right onto Palace Road");
    return QString::fromStdString(m_navService->getActiveDestination().maneuverText);
}

QString HomeViewModel::navNextTurnIcon() const {
    if (!m_navService) return QStringLiteral("↱");
    return QString::fromStdString(m_navService->getActiveDestination().turnIcon);
}

void HomeViewModel::updateClock() {
    QString timeStr = QTime::currentTime().toString(QStringLiteral("h:mm AP"));
    if (timeStr.isEmpty()) {
        timeStr = QStringLiteral("10:42 AM");
    }
    if (m_timeFormatted != timeStr) {
        m_timeFormatted = timeStr;
        emit timeChanged();
    }
}

void HomeViewModel::toggleDriveMode() {
    if (m_safetyPolicy && !m_safetyPolicy->isVehicleConfigurationAllowed()) {
        emit userNotificationRequested(QStringLiteral("Unavailable while driving"),
                                       QStringLiteral("Drive mode changes are restricted in motion for vehicle stability."));
        return;
    }

    domain::DriveMode nextMode = domain::DriveMode::NORMAL;
    if (m_driveMode == domain::DriveMode::NORMAL) {
        nextMode = domain::DriveMode::SPORT;
    } else if (m_driveMode == domain::DriveMode::SPORT) {
        nextMode = domain::DriveMode::ECO;
    } else {
        nextMode = domain::DriveMode::NORMAL;
    }

    if (m_vehicleService) {
        m_vehicleService->setDriveMode(nextMode);
    } else {
        m_driveMode = nextMode;
        emit driveModeChanged(driveMode());
    }
}

void HomeViewModel::accelerate(float deltaKmH) {
    if (m_vehicleService) {
        m_vehicleService->setSpeed(m_speed + deltaKmH);
    } else {
        m_speed += deltaKmH;
        emit speedChanged(m_speed);
    }
}

void HomeViewModel::brake() {
    if (m_vehicleService) {
        m_vehicleService->setSpeed(0.0f);
    } else {
        m_speed = 0.0f;
        emit speedChanged(m_speed);
    }
}

void HomeViewModel::setSimulatedSpeed(float speedKmH) {
    if (m_vehicleService) {
        m_vehicleService->setSpeed(speedKmH);
    } else {
        m_speed = speedKmH;
        emit speedChanged(m_speed);
    }
}

void HomeViewModel::setVehicleContextState(const QString& state) {
    if (m_vehicleContextState == state) return;

    if (m_vehicleService) {
        m_vehicleService->setScenario(state.toStdString());
    }

    if (state == QStringLiteral("FAULT")) {
        emit userNotificationRequested(QStringLiteral("Subsystem Caution"),
                                       QStringLiteral("DTC B1200: Low-voltage CAN bus communication degraded. Diagnostics required."));
    }
}

void HomeViewModel::setScenario(const QString& scenario) {
    setVehicleContextState(scenario);
}

void HomeViewModel::setFaultMode(const QString& faultMode) {
    if (m_vehicleService) {
        m_vehicleService->setFaultMode(faultMode.toStdString());
    }
}

void HomeViewModel::adjustTargetTemperature(float deltaCelsius) {
    if (m_climateService) {
        m_climateService->setTargetTemperature(m_targetTemperature + deltaCelsius);
    } else {
        m_targetTemperature = std::clamp(m_targetTemperature + deltaCelsius, 16.0f, 28.0f);
        emit targetTemperatureChanged(m_targetTemperature);
    }
}

void HomeViewModel::toggleAcActive() {
    if (m_climateService) {
        m_climateService->setACActive(!m_isAcActive);
    } else {
        m_isAcActive = !m_isAcActive;
        emit isAcActiveChanged(m_isAcActive);
    }
}

void HomeViewModel::setFanSpeedLevel(int level) {
    if (m_climateService) {
        m_climateService->setFanSpeed(level);
    } else {
        m_fanSpeed = std::clamp(level, 0, 5);
        emit fanSpeedChanged(m_fanSpeed);
    }
}

void HomeViewModel::toggleMediaPlayPause() {
    if (m_mediaService) {
        m_mediaService->togglePlayPause();
    } else {
        m_isMediaPlaying = !m_isMediaPlaying;
        emit mediaPlaybackChanged(m_isMediaPlaying);
    }
}

void HomeViewModel::nextMediaTrack() {
    if (m_mediaService) {
        m_mediaService->nextTrack();
    }
}

void HomeViewModel::prevMediaTrack() {
    if (m_mediaService) {
        m_mediaService->previousTrack();
    }
}

void HomeViewModel::handleStateUpdate(const domain::VehicleState& state) {
    if (m_speed != state.speed) {
        m_speed = state.speed;
        emit speedChanged(m_speed);
    }

    if (m_batterySoc != state.batterySoc) {
        m_batterySoc = state.batterySoc;
        emit batterySocChanged(m_batterySoc);
    }

    if (m_rangeKm != state.rangeKm) {
        m_rangeKm = state.rangeKm;
        emit rangeKmChanged(m_rangeKm);
    }

    if (m_gear != state.gear) {
        m_gear = state.gear;
        emit gearChanged(gear());
    }

    if (m_driveMode != state.driveMode) {
        m_driveMode = state.driveMode;
        emit driveModeChanged(driveMode());
    }

    if (m_cabinTemperature != state.cabinTemperature) {
        m_cabinTemperature = state.cabinTemperature;
        emit cabinTemperatureChanged(m_cabinTemperature);
    }

    QString nextContextState = QStringLiteral("PARKED");
    switch (state.operationalState) {
    case domain::OperationalState::PARKED:   nextContextState = QStringLiteral("PARKED"); break;
    case domain::OperationalState::DRIVING:  nextContextState = QStringLiteral("DRIVING"); break;
    case domain::OperationalState::REVERSE:  nextContextState = QStringLiteral("REVERSE"); break;
    case domain::OperationalState::CHARGING: nextContextState = QStringLiteral("CHARGING"); break;
    case domain::OperationalState::FAULT:    nextContextState = QStringLiteral("FAULT"); break;
    }

    if (m_vehicleContextState != nextContextState) {
        m_vehicleContextState = nextContextState;
        emit vehicleContextStateChanged(m_vehicleContextState);
        emit degradedStatusChanged();
        emit systemStatusChanged(systemStatus());
    }

    bool driving = domain::SafetyPolicy::isInMotion(state);
    if (m_isDriving != driving) {
        m_isDriving = driving;
        emit isDrivingChanged(m_isDriving);
    }

    // Evaluate in-motion restriction status
    if (m_safetyPolicy) {
        auto eval = m_safetyPolicy->evaluateInteraction(domain::InteractionCategory::DEEP_SETTINGS, state);
        setRestricted(!eval.isAllowed, QString::fromStdString(eval.restrictionReason));
    }
}

void HomeViewModel::handleHealthUpdate(vehicle::CommunicationHealth health) {
    if (m_health != health) {
        m_health = health;
        emit degradedStatusChanged();
        emit systemStatusChanged(systemStatus());

        if (health == vehicle::CommunicationHealth::DISCONNECTED) {
            emit userNotificationRequested(QStringLiteral("Communication Offline"),
                                           QStringLiteral("Vehicle telemetry bus disconnected. Operating in degraded fallback."));
        } else if (health == vehicle::CommunicationHealth::DEGRADED) {
            emit userNotificationRequested(QStringLiteral("Communication Degraded"),
                                           QStringLiteral("Bus frame drops detected. Check physical wiring harness."));
        }
    }
}

} // namespace driveos::presentation
