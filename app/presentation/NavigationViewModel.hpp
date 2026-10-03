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
 * Exposes simulated map coordinates, mock destinations list, turn-by-turn maneuvers,
 * ETA / distance metrics, and driving mode adaptation.
 */
class NavigationViewModel : public BaseViewModel {
    Q_OBJECT

    // Active Route Information
    Q_PROPERTY(QString destinationTitle READ destinationTitle NOTIFY navStateChanged)
    Q_PROPERTY(QString destinationCategory READ destinationCategory NOTIFY navStateChanged)
    Q_PROPERTY(QString destinationIcon READ destinationIcon NOTIFY navStateChanged)
    Q_PROPERTY(QString etaFormatted READ etaFormatted NOTIFY navStateChanged)
    Q_PROPERTY(QString distanceFormatted READ distanceFormatted NOTIFY navStateChanged)
    Q_PROPERTY(QString arrivalClockFormatted READ arrivalClockFormatted NOTIFY navStateChanged)
    Q_PROPERTY(QString maneuverInstruction READ maneuverInstruction NOTIFY navStateChanged)
    Q_PROPERTY(QString turnIcon READ turnIcon NOTIFY navStateChanged)
    Q_PROPERTY(QString routeStatus READ routeStatus NOTIFY navStateChanged)
    Q_PROPERTY(bool isNavigating READ isNavigating NOTIFY navStateChanged)

    // Map Target Coordinates (Normalized 0.0 - 1.0)
    Q_PROPERTY(float destX READ destX NOTIFY navStateChanged)
    Q_PROPERTY(float destY READ destY NOTIFY navStateChanged)

    // Mock Destination List
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
    [[nodiscard]] QString etaFormatted() const;
    [[nodiscard]] QString distanceFormatted() const;
    [[nodiscard]] QString arrivalClockFormatted() const;
    [[nodiscard]] QString maneuverInstruction() const;
    [[nodiscard]] QString turnIcon() const;
    [[nodiscard]] QString routeStatus() const;
    [[nodiscard]] bool isNavigating() const;
    [[nodiscard]] float destX() const;
    [[nodiscard]] float destY() const;
    [[nodiscard]] QVariantList destinations() const;
    [[nodiscard]] int selectedIndex() const;
    [[nodiscard]] bool isDriving() const;

    // Invocable UI Actions
    Q_INVOKABLE void selectDestination(int index);
    Q_INVOKABLE void startNavigation();
    Q_INVOKABLE void stopNavigation();
    Q_INVOKABLE void toggleNavigation();

signals:
    void navStateChanged();
    void destinationsChanged();
    void vehicleStateChanged();

private:
    domain::NavigationService* m_navService{nullptr};
    domain::VehicleService* m_vehicleService{nullptr};
};

} // namespace driveos::presentation
