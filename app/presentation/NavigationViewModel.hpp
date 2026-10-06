#pragma once

#include "BaseViewModel.hpp"
#include "domain/NavigationService.hpp"
#include "domain/VehicleService.hpp"
#include <QString>
#include <QVariantList>

namespace driveos::presentation {

/**
 * @brief ViewModel for the Navigation screen in DriveOS.
 * 
 * Exposes real geographic coordinates, Dijkstra shortest path telemetry,
 * satellite map layers, moving vehicle simulation, and distinct user location marker.
 */
class NavigationViewModel : public BaseViewModel {
    Q_OBJECT

    // Active Route Information
    Q_PROPERTY(QString destinationTitle READ destinationTitle NOTIFY navStateChanged)
    Q_PROPERTY(QString destinationCategory READ destinationCategory NOTIFY navStateChanged)
    Q_PROPERTY(QString destinationIcon READ destinationIcon NOTIFY navStateChanged)
    Q_PROPERTY(QString destinationAddress READ destinationAddress NOTIFY navStateChanged)
    Q_PROPERTY(QString etaFormatted READ etaFormatted NOTIFY navStateChanged)
    Q_PROPERTY(QString distanceFormatted READ distanceFormatted NOTIFY navStateChanged)
    Q_PROPERTY(QString arrivalClockFormatted READ arrivalClockFormatted NOTIFY navStateChanged)
    Q_PROPERTY(QString maneuverInstruction READ maneuverInstruction NOTIFY navStateChanged)
    Q_PROPERTY(QString turnIcon READ turnIcon NOTIFY navStateChanged)
    Q_PROPERTY(QString routeStatus READ routeStatus NOTIFY navStateChanged)
    Q_PROPERTY(bool isNavigating READ isNavigating NOTIFY navStateChanged)
    Q_PROPERTY(int speedLimit READ speedLimit NOTIFY navStateChanged)
    Q_PROPERTY(int batteryArrivalSoc READ batteryArrivalSoc NOTIFY navStateChanged)

    // Real Geographic & Moving Vehicle Telemetry
    Q_PROPERTY(double currentLatitude READ currentLatitude NOTIFY navStateChanged)
    Q_PROPERTY(double currentLongitude READ currentLongitude NOTIFY navStateChanged)
    Q_PROPERTY(double currentHeading READ currentHeading NOTIFY navStateChanged)
    Q_PROPERTY(double vehicleSpeed READ vehicleSpeed NOTIFY navStateChanged)
    Q_PROPERTY(double destinationLatitude READ destinationLatitude NOTIFY navStateChanged)
    Q_PROPERTY(double destinationLongitude READ destinationLongitude NOTIFY navStateChanged)
    Q_PROPERTY(float routeProgress READ routeProgress NOTIFY navStateChanged)
    Q_PROPERTY(QVariantList routeWaypoints READ routeWaypoints NOTIFY navStateChanged)

    // User's Current Location (Distinct from moving vehicle)
    Q_PROPERTY(double userLatitude READ userLatitude NOTIFY userLocationChanged)
    Q_PROPERTY(double userLongitude READ userLongitude NOTIFY userLocationChanged)
    Q_PROPERTY(QString userLocationTitle READ userLocationTitle NOTIFY userLocationChanged)
    Q_PROPERTY(QString userLocationAddress READ userLocationAddress NOTIFY userLocationChanged)

    // Shortest Path Graph Telemetry
    Q_PROPERTY(QString pathfindingAlgorithm READ pathfindingAlgorithm CONSTANT)
    Q_PROPERTY(int shortestPathNodeCount READ shortestPathNodeCount NOTIFY navStateChanged)
    Q_PROPERTY(double shortestPathDistanceKm READ shortestPathDistanceKm NOTIFY navStateChanged)
    Q_PROPERTY(QVariantList shortestPathNodeNames READ shortestPathNodeNames NOTIFY navStateChanged)

    // Map Configuration & Mode
    Q_PROPERTY(QString mapLayerType READ mapLayerType WRITE setMapLayerType NOTIFY mapConfigChanged)
    Q_PROPERTY(bool is3DMode READ is3DMode WRITE setIs3DMode NOTIFY mapConfigChanged)

    // Canvas Target Normalized Coordinates (legacy support)
    Q_PROPERTY(float destX READ destX NOTIFY navStateChanged)
    Q_PROPERTY(float destY READ destY NOTIFY navStateChanged)

    // Destination List
    Q_PROPERTY(QVariantList destinations READ destinations NOTIFY destinationsChanged)
    Q_PROPERTY(int selectedIndex READ selectedIndex NOTIFY navStateChanged)

    // Driving Context
    Q_PROPERTY(bool isDriving READ isDriving NOTIFY vehicleStateChanged)

public:
    explicit NavigationViewModel(domain::NavigationService* navService,
                                domain::VehicleService* vehicleService = nullptr,
                                QObject* parent = nullptr);
    ~NavigationViewModel() override = default;

    // Getters
    [[nodiscard]] QString destinationTitle() const;
    [[nodiscard]] QString destinationCategory() const;
    [[nodiscard]] QString destinationIcon() const;
    [[nodiscard]] QString destinationAddress() const;
    [[nodiscard]] QString etaFormatted() const;
    [[nodiscard]] QString distanceFormatted() const;
    [[nodiscard]] QString arrivalClockFormatted() const;
    [[nodiscard]] QString maneuverInstruction() const;
    [[nodiscard]] QString turnIcon() const;
    [[nodiscard]] QString routeStatus() const;
    [[nodiscard]] bool isNavigating() const;
    [[nodiscard]] int speedLimit() const;
    [[nodiscard]] int batteryArrivalSoc() const;

    [[nodiscard]] double currentLatitude() const;
    [[nodiscard]] double currentLongitude() const;
    [[nodiscard]] double currentHeading() const;
    [[nodiscard]] double vehicleSpeed() const;
    [[nodiscard]] double destinationLatitude() const;
    [[nodiscard]] double destinationLongitude() const;
    [[nodiscard]] float routeProgress() const;
    [[nodiscard]] QVariantList routeWaypoints() const;

    [[nodiscard]] double userLatitude() const;
    [[nodiscard]] double userLongitude() const;
    [[nodiscard]] QString userLocationTitle() const;
    [[nodiscard]] QString userLocationAddress() const;

    [[nodiscard]] QString pathfindingAlgorithm() const;
    [[nodiscard]] int shortestPathNodeCount() const;
    [[nodiscard]] double shortestPathDistanceKm() const;
    [[nodiscard]] QVariantList shortestPathNodeNames() const;

    [[nodiscard]] QString mapLayerType() const;
    [[nodiscard]] bool is3DMode() const;
    [[nodiscard]] float destX() const;
    [[nodiscard]] float destY() const;
    [[nodiscard]] QVariantList destinations() const;
    [[nodiscard]] int selectedIndex() const;
    [[nodiscard]] bool isDriving() const;

    // Setters & Invocables
    Q_INVOKABLE void selectDestination(int index);
    Q_INVOKABLE void startNavigation();
    Q_INVOKABLE void stopNavigation();
    Q_INVOKABLE void toggleNavigation();
    Q_INVOKABLE void setMapLayerType(const QString& type);
    Q_INVOKABLE void setIs3DMode(bool enabled);
    Q_INVOKABLE void toggle3DMode();
    Q_INVOKABLE void setRouteProgress(float progress);
    Q_INVOKABLE void setUserLocation(double lat, double lon, const QString& title = QString(), const QString& address = QString());

signals:
    void navStateChanged();
    void destinationsChanged();
    void userLocationChanged();
    void vehicleStateChanged();
    void mapConfigChanged();

private:
    domain::NavigationService* m_navService{nullptr};
    domain::VehicleService* m_vehicleService{nullptr};
    QString m_mapLayerType{QStringLiteral("satellite")}; // "satellite", "street", "dark"
    bool m_is3DMode{false};
};

} // namespace driveos::presentation
