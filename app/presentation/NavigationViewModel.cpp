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
            emit userLocationChanged();
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

QString NavigationViewModel::destinationAddress() const {
    if (!m_navService) return QStringLiteral("Sayyaji Rao Rd, Mysuru, Karnataka");
    return QString::fromStdString(m_navService->getActiveDestination().address);
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
    if (!m_navService) return QStringLiteral("Shortest Path via Dijkstra • Optimal Road Corridor");
    return QStringLiteral("Shortest Path via Dijkstra (%1 nodes, %2 km)")
        .arg(m_navService->getShortestPathNodeCount())
        .arg(QString::number(m_navService->getShortestPathDistanceKm(), 'f', 1));
}

bool NavigationViewModel::isNavigating() const {
    if (!m_navService) return true;
    return m_navService->isNavigating();
}

int NavigationViewModel::speedLimit() const {
    if (!m_navService) return 60;
    return m_navService->getActiveDestination().speedLimitKmH;
}

int NavigationViewModel::batteryArrivalSoc() const {
    if (!m_navService) return 82;
    return m_navService->getActiveDestination().batteryArrivalSoc;
}

double NavigationViewModel::currentLatitude() const {
    if (!m_navService) return 12.3410;
    return m_navService->getCurrentLatitude();
}

double NavigationViewModel::currentLongitude() const {
    if (!m_navService) return 76.6268;
    return m_navService->getCurrentLongitude();
}

double NavigationViewModel::currentHeading() const {
    if (!m_navService) return 45.0;
    return m_navService->getCurrentHeading();
}

double NavigationViewModel::vehicleSpeed() const {
    if (!m_navService) return 52.0;
    return m_navService->getVehicleSpeed();
}

double NavigationViewModel::destinationLatitude() const {
    if (!m_navService) return 12.3052;
    return m_navService->getActiveDestination().latitude;
}

double NavigationViewModel::destinationLongitude() const {
    if (!m_navService) return 76.6552;
    return m_navService->getActiveDestination().longitude;
}

float NavigationViewModel::routeProgress() const {
    if (!m_navService) return 0.25f;
    return m_navService->getRouteProgress();
}

QVariantList NavigationViewModel::routeWaypoints() const {
    QVariantList list;
    if (!m_navService) return list;

    const auto& wps = m_navService->getActiveDestination().waypoints;
    for (const auto& wp : wps) {
        QVariantMap point;
        point[QStringLiteral("lat")] = wp.first;
        point[QStringLiteral("lon")] = wp.second;
        list.append(point);
    }
    return list;
}

double NavigationViewModel::userLatitude() const {
    if (!m_navService) return 12.3551;
    return m_navService->getUserLatitude();
}

double NavigationViewModel::userLongitude() const {
    if (!m_navService) return 76.6186;
    return m_navService->getUserLongitude();
}

QString NavigationViewModel::userLocationTitle() const {
    if (!m_navService) return QStringLiteral("Current Location of the User");
    return QString::fromStdString(m_navService->getUserLocationTitle());
}

QString NavigationViewModel::userLocationAddress() const {
    if (!m_navService) return QStringLiteral("GSSSIETW Campus, KRS Road, Mysuru");
    return QString::fromStdString(m_navService->getUserLocationAddress());
}

QString NavigationViewModel::pathfindingAlgorithm() const {
    if (!m_navService) return QStringLiteral("Dijkstra's Shortest Path Algorithm");
    return QString::fromStdString(m_navService->getPathfindingAlgorithm());
}

int NavigationViewModel::shortestPathNodeCount() const {
    if (!m_navService) return 8;
    return m_navService->getShortestPathNodeCount();
}

double NavigationViewModel::shortestPathDistanceKm() const {
    if (!m_navService) return 8.4;
    return m_navService->getShortestPathDistanceKm();
}

QVariantList NavigationViewModel::shortestPathNodeNames() const {
    QVariantList list;
    if (!m_navService) return list;

    for (const auto& name : m_navService->getActiveShortestPath().nodeNames) {
        list.append(QString::fromStdString(name));
    }
    return list;
}

QString NavigationViewModel::mapLayerType() const {
    return m_mapLayerType;
}

bool NavigationViewModel::is3DMode() const {
    return m_is3DMode;
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
        map[QStringLiteral("address")] = QString::fromStdString(d.address);
        map[QStringLiteral("distance")] = QString::number(d.distanceKm, 'f', 1) + QStringLiteral(" km");
        map[QStringLiteral("eta")] = QString::number(d.etaMinutes) + QStringLiteral(" min");
        map[QStringLiteral("latitude")] = d.latitude;
        map[QStringLiteral("longitude")] = d.longitude;
        map[QStringLiteral("speedLimit")] = d.speedLimitKmH;
        map[QStringLiteral("batteryArrivalSoc")] = d.batteryArrivalSoc;
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

void NavigationViewModel::setMapLayerType(const QString& type) {
    if (m_mapLayerType != type) {
        m_mapLayerType = type;
        emit mapConfigChanged();
    }
}

void NavigationViewModel::setIs3DMode(bool enabled) {
    if (m_is3DMode != enabled) {
        m_is3DMode = enabled;
        emit mapConfigChanged();
    }
}

void NavigationViewModel::toggle3DMode() {
    setIs3DMode(!m_is3DMode);
}

void NavigationViewModel::setRouteProgress(float progress) {
    if (m_navService) {
        m_navService->setRouteProgress(progress);
    }
}

void NavigationViewModel::setUserLocation(double lat, double lon, const QString& title, const QString& address) {
    if (m_navService) {
        m_navService->setUserLocation(
            lat,
            lon,
            title.isEmpty() ? "Current Location of the User" : title.toStdString(),
            address.isEmpty() ? "GSSSIETW Campus, KRS Road, Mysuru" : address.toStdString()
        );
        emit userLocationChanged();
    }
}

} // namespace driveos::presentation
