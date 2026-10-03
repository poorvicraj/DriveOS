#include "ClimateViewModel.hpp"

namespace driveos::presentation {

ClimateViewModel::ClimateViewModel(domain::ClimateService* climateService,
                                   domain::SafetyPolicy* safetyPolicy,
                                   QObject* parent)
    : BaseViewModel(parent)
    , m_climateService(climateService)
    , m_safetyPolicy(safetyPolicy)
{
    if (m_climateService) {
        m_climateService->registerStateCallback([this]() {
            emit climateChanged();
        });

        m_climateService->registerClimateCallback([this](float, float, int, bool) {
            emit climateChanged();
        });
    }
}

float ClimateViewModel::cabinTemperature() const {
    if (!m_climateService) return 21.5f;
    return m_climateService->getCabinTemperature();
}

QString ClimateViewModel::cabinTemperatureFormatted() const {
    return QString::number(cabinTemperature(), 'f', 1) + QStringLiteral("°C");
}

float ClimateViewModel::targetTemperature() const {
    if (!m_climateService) return 22.0f;
    return m_climateService->getTargetTemperature();
}

QString ClimateViewModel::targetTemperatureFormatted() const {
    return QString::number(targetTemperature(), 'f', 1) + QStringLiteral("°");
}

float ClimateViewModel::passengerTemperature() const {
    if (!m_climateService) return 22.0f;
    return m_climateService->getPassengerTemperature();
}

QString ClimateViewModel::passengerTemperatureFormatted() const {
    return QString::number(passengerTemperature(), 'f', 1) + QStringLiteral("°");
}

float ClimateViewModel::outsideTemperature() const {
    if (!m_climateService) return 19.0f;
    return m_climateService->getOutsideTemperature();
}

QString ClimateViewModel::outsideTemperatureFormatted() const {
    return QString::number(static_cast<int>(outsideTemperature())) + QStringLiteral("°C");
}

bool ClimateViewModel::isAcActive() const {
    if (!m_climateService) return true;
    return m_climateService->isACActive();
}

bool ClimateViewModel::isAutoMode() const {
    if (!m_climateService) return true;
    return m_climateService->isAutoMode();
}

bool ClimateViewModel::isSyncActive() const {
    if (!m_climateService) return true;
    return m_climateService->isSyncActive();
}

int ClimateViewModel::fanSpeed() const {
    if (!m_climateService) return 2;
    return m_climateService->getFanSpeed();
}

QString ClimateViewModel::fanSpeedFormatted() const {
    int spd = fanSpeed();
    if (spd <= 0) return QStringLiteral("Off");
    return QStringLiteral("Level %1").arg(spd);
}

QString ClimateViewModel::airflowMode() const {
    if (!m_climateService) return QStringLiteral("vent");
    switch (m_climateService->getAirflowDirection()) {
    case domain::AirflowDirection::WINDSHIELD: return QStringLiteral("windshield");
    case domain::AirflowDirection::VENT:       return QStringLiteral("vent");
    case domain::AirflowDirection::FLOOR:      return QStringLiteral("floor");
    case domain::AirflowDirection::BI_LEVEL:   return QStringLiteral("bilevel");
    }
    return QStringLiteral("vent");
}

bool ClimateViewModel::isFrontDefrost() const {
    if (!m_climateService) return false;
    return m_climateService->isFrontDefrost();
}

bool ClimateViewModel::isRearDefrost() const {
    if (!m_climateService) return false;
    return m_climateService->isRearDefrost();
}

bool ClimateViewModel::isRecirculation() const {
    if (!m_climateService) return false;
    return m_climateService->isRecirculation();
}

int ClimateViewModel::driverSeatHeat() const {
    if (!m_climateService) return 0;
    return m_climateService->getDriverSeatHeat();
}

int ClimateViewModel::passengerSeatHeat() const {
    if (!m_climateService) return 0;
    return m_climateService->getPassengerSeatHeat();
}

bool ClimateViewModel::isHeating() const {
    return targetTemperature() > cabinTemperature();
}

bool ClimateViewModel::isCooling() const {
    return targetTemperature() < cabinTemperature();
}

void ClimateViewModel::adjustTargetTemperature(float delta) {
    if (m_climateService) {
        m_climateService->setTargetTemperature(targetTemperature() + delta);
    }
}

void ClimateViewModel::adjustPassengerTemperature(float delta) {
    if (m_climateService) {
        m_climateService->setPassengerTemperature(passengerTemperature() + delta);
    }
}

void ClimateViewModel::setFanSpeedLevel(int level) {
    if (m_climateService) {
        m_climateService->setFanSpeed(level);
    }
}

void ClimateViewModel::toggleAc() {
    if (m_climateService) {
        m_climateService->setACActive(!isAcActive());
    }
}

void ClimateViewModel::toggleAuto() {
    if (m_climateService) {
        m_climateService->setAutoMode(!isAutoMode());
    }
}

void ClimateViewModel::toggleSync() {
    if (m_climateService) {
        m_climateService->setSyncActive(!isSyncActive());
    }
}

void ClimateViewModel::setAirflowMode(const QString& mode) {
    if (!m_climateService) return;

    if (mode == QStringLiteral("windshield")) {
        m_climateService->setAirflowDirection(domain::AirflowDirection::WINDSHIELD);
    } else if (mode == QStringLiteral("vent")) {
        m_climateService->setAirflowDirection(domain::AirflowDirection::VENT);
    } else if (mode == QStringLiteral("floor")) {
        m_climateService->setAirflowDirection(domain::AirflowDirection::FLOOR);
    } else if (mode == QStringLiteral("bilevel")) {
        m_climateService->setAirflowDirection(domain::AirflowDirection::BI_LEVEL);
    }
}

void ClimateViewModel::toggleFrontDefrost() {
    if (m_climateService) {
        m_climateService->setFrontDefrost(!isFrontDefrost());
    }
}

void ClimateViewModel::toggleRearDefrost() {
    if (m_climateService) {
        m_climateService->setRearDefrost(!isRearDefrost());
    }
}

void ClimateViewModel::toggleRecirculation() {
    if (m_climateService) {
        m_climateService->setRecirculation(!isRecirculation());
    }
}

void ClimateViewModel::cycleDriverSeatHeat() {
    if (m_climateService) {
        m_climateService->cycleDriverSeatHeat();
    }
}

void ClimateViewModel::cyclePassengerSeatHeat() {
    if (m_climateService) {
        m_climateService->cyclePassengerSeatHeat();
    }
}

} // namespace driveos::presentation
