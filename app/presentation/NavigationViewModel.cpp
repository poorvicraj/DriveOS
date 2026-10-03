#include "NavigationViewModel.hpp"
#include <QTime>
#include <QVariantMap>

namespace driveos::presentation {

NavigationViewModel::NavigationViewModel(domain::NavigationService* navService,
                                         domain::VehicleService* vehicleService,
                                         QObject* parent)
    : BaseViewModel(parent)
    , m_navService(navService)
    , m_vehicleService(vehicleService)
{
    if (m_navService) {
        m_navService->registerObserver([this]() {
            emit navStateChanged();
            emit destinationsChanged();
        });
    }

    if (m_vehicleService) {
        m_vehicleService->registerStateCallback([this](const domain::VehicleState&) {
            emit vehicleStateChanged();
        });
    }
}

QString NavigationViewModel::destinationTitle() const {
    if (!m_navService) return QStringLiteral("Mysuru Palace");
    return QString::fromStdString(m_navService->getActiveDestination().name);
}

QString NavigationViewModel::destinationCategory() const {
    if (!m_navService) return QStringLiteral("Landmark");
    return QString::fromStdString(m_navService->getActiveDestination().category);
}

QString NavigationViewModel::destinationIcon() const {
    if (!m_navService) return QStringLiteral("🏰");
    return QString::fromStdString(m_navService->getActiveDestination().icon);
}

QString NavigationViewModel::etaFormatted() const {
    if (!m_navService) return QStringLiteral("18 min");
    return QString::number(m_navService->getActiveDestination().etaMinutes) + QStringLiteral(" min");
}

QString NavigationViewModel::distanceFormatted() const {
    if (!m_navService) return QStringLiteral("8.4 km");
    return QString::number(m_navService->getActiveDestination().distanceKm, 'f', 1) + QStringLiteral(" km");
}

QString NavigationViewModel::arrivalClockFormatted() const {
    if (!m_navService) return QStringLiteral("11:00 AM");
    const int etaMins = m_navService->getActiveDestination().etaMinutes;
    QTime arrival = QTime::currentTime().addSecs(etaMins * 60);
    return arrival.toString(QStringLiteral("h:mm AP"));
}

QString NavigationViewModel::maneuverInstruction() const {
    if (!m_navService) return QStringLiteral("In 450 m, turn right onto Palace Road");
    return QString::fromStdString(m_navService->getActiveDestination().maneuverText);
}

QString NavigationViewModel::turnIcon() const {
    if (!m_navService) return QStringLiteral("↱");
    return QString::fromStdString(m_navService->getActiveDestination().turnIcon);
}

QString NavigationViewModel::routeStatus() const {
    return QStringLiteral("Fastest Route via Outer Ring Road • Typical Traffic");
}

bool NavigationViewModel::isNavigating() const {
    if (!m_navService) return true;
    return m_navService->isNavigating();
}

float NavigationViewModel::destX() const {
    if (!m_navService) return 0.74f;
    return m_navService->getActiveDestination().destX;
}

float NavigationViewModel::destY() const {
    if (!m_navService) return 0.26f;
    return m_navService->getActiveDestination().destY;
}

QVariantList NavigationViewModel::destinations() const {
    QVariantList list;
    if (!m_navService) return list;

    const auto& dests = m_navService->getDestinations();
    const size_t activeIdx = m_navService->getActiveDestinationIndex();

    for (size_t i = 0; i < dests.size(); ++i) {
        const auto& d = dests[i];
        QVariantMap map;
        map[QStringLiteral("index")] = static_cast<int>(i);
        map[QStringLiteral("id")] = QString::fromStdString(d.id);
        map[QStringLiteral("name")] = QString::fromStdString(d.name);
        map[QStringLiteral("category")] = QString::fromStdString(d.category);
        map[QStringLiteral("icon")] = QString::fromStdString(d.icon);
        map[QStringLiteral("distance")] = QString::number(d.distanceKm, 'f', 1) + QStringLiteral(" km");
        map[QStringLiteral("eta")] = QString::number(d.etaMinutes) + QStringLiteral(" min");
        map[QStringLiteral("isSelected")] = (i == activeIdx);
        list.append(map);
    }
    return list;
}

int NavigationViewModel::selectedIndex() const {
    if (!m_navService) return 0;
    return static_cast<int>(m_navService->getActiveDestinationIndex());
}

bool NavigationViewModel::isDriving() const {
    if (!m_vehicleService) return false;
    const auto state = m_vehicleService->getVehicleState();
    return domain::SafetyPolicy::isInMotion(state);
}

void NavigationViewModel::selectDestination(int index) {
    if (m_navService && index >= 0) {
        m_navService->selectDestinationIndex(static_cast<size_t>(index));
    }
}

void NavigationViewModel::startNavigation() {
    if (m_navService) {
        m_navService->startNavigation();
    }
}

void NavigationViewModel::stopNavigation() {
    if (m_navService) {
        m_navService->stopNavigation();
    }
}

void NavigationViewModel::toggleNavigation() {
    if (m_navService) {
        m_navService->toggleNavigation();
    }
}

} // namespace driveos::presentation
