#pragma once

#include "BaseViewModel.hpp"
#include "domain/VehicleService.hpp"
#include "domain/ClimateService.hpp"
#include "domain/MediaService.hpp"
#include "domain/NavigationService.hpp"
#include "domain/SafetyPolicy.hpp"
#include "vehicle/VehicleDataInterface.hpp"
#include <memory>
#include <QTime>
#include <QTimer>

namespace driveos::presentation {

/**
 * @brief ViewModel for the Home Digital Cockpit screen in DriveOS.
 * 
 * Provides UI-friendly vehicle telemetry, driver greeting, clock, operational state
 * transitions, climate summary, media controls, and navigation overview.
 * 
 * Ensures single source of truth by synchronizing with domain services
 * (VehicleService, VehicleStateManager, ClimateService, MediaService, NavigationService).
 */
class HomeViewModel : public BaseViewModel {
    Q_OBJECT

    // Telemetry & Powertrain
    Q_PROPERTY(float speed READ speed NOTIFY speedChanged)
    Q_PROPERTY(QString speedFormatted READ speedFormatted NOTIFY speedChanged)
    Q_PROPERTY(float batterySoc READ batterySoc NOTIFY batterySocChanged)
    Q_PROPERTY(QString batterySocFormatted READ batterySocFormatted NOTIFY batterySocChanged)
    Q_PROPERTY(float rangeKm READ rangeKm NOTIFY rangeKmChanged)
    Q_PROPERTY(QString rangeKmFormatted READ rangeKmFormatted NOTIFY rangeKmChanged)
    Q_PROPERTY(QString gear READ gear NOTIFY gearChanged)
    Q_PROPERTY(QString driveMode READ driveMode NOTIFY driveModeChanged)
    Q_PROPERTY(QString systemStatus READ systemStatus NOTIFY systemStatusChanged)
    Q_PROPERTY(QString backendName READ backendName CONSTANT)
    Q_PROPERTY(bool isDriving READ isDriving NOTIFY isDrivingChanged)
    Q_PROPERTY(bool isDegraded READ isDegraded NOTIFY degradedStatusChanged)
    Q_PROPERTY(bool hasFault READ hasFault NOTIFY degradedStatusChanged)
    Q_PROPERTY(QString communicationHealth READ communicationHealth NOTIFY degradedStatusChanged)

    // Contextual State Awareness (PARKED, DRIVING, REVERSE, CHARGING, FAULT)
    Q_PROPERTY(QString vehicleContextState READ vehicleContextState NOTIFY vehicleContextStateChanged)
    Q_PROPERTY(QString vehicleContextSubtitle READ vehicleContextSubtitle NOTIFY vehicleContextStateChanged)

    // Clock & Status Ribbon
    Q_PROPERTY(QString timeFormatted READ timeFormatted NOTIFY timeChanged)
    Q_PROPERTY(QString outsideTemperatureFormatted READ outsideTemperatureFormatted CONSTANT)
    Q_PROPERTY(QString greetingText READ greetingText NOTIFY timeChanged)

    // Climate Summary Context (Synchronized with ClimateService)
    Q_PROPERTY(float cabinTemperature READ cabinTemperature NOTIFY cabinTemperatureChanged)
    Q_PROPERTY(QString cabinTemperatureFormatted READ cabinTemperatureFormatted NOTIFY cabinTemperatureChanged)
    Q_PROPERTY(float targetTemperature READ targetTemperature NOTIFY targetTemperatureChanged)
    Q_PROPERTY(QString targetTemperatureFormatted READ targetTemperatureFormatted NOTIFY targetTemperatureChanged)
    Q_PROPERTY(int fanSpeed READ fanSpeed NOTIFY fanSpeedChanged)
    Q_PROPERTY(bool isAcActive READ isAcActive NOTIFY isAcActiveChanged)

    // Media Summary Context (Synchronized with MediaService)
    Q_PROPERTY(QString mediaTitle READ mediaTitle NOTIFY mediaChanged)
    Q_PROPERTY(QString mediaArtist READ mediaArtist NOTIFY mediaChanged)
    Q_PROPERTY(bool isMediaPlaying READ isMediaPlaying NOTIFY mediaPlaybackChanged)
    Q_PROPERTY(QString mediaElapsedFormatted READ mediaElapsedFormatted NOTIFY mediaProgressChanged)
    Q_PROPERTY(QString mediaDurationFormatted READ mediaDurationFormatted NOTIFY mediaChanged)
    Q_PROPERTY(float mediaProgress READ mediaProgress NOTIFY mediaProgressChanged)

    // Navigation Context (Synchronized with NavigationService)
    Q_PROPERTY(QString navDestination READ navDestination NOTIFY navChanged)
    Q_PROPERTY(QString navEta READ navEta NOTIFY navChanged)
    Q_PROPERTY(QString navDistance READ navDistance NOTIFY navChanged)
    Q_PROPERTY(QString navManeuver READ navManeuver NOTIFY navChanged)
    Q_PROPERTY(QString navNextTurnIcon READ navNextTurnIcon NOTIFY navChanged)

public:
    explicit HomeViewModel(domain::VehicleService* vehicleService,
                           domain::SafetyPolicy* safetyPolicy,
                           vehicle::VehicleDataInterface* vdi = nullptr,
                           domain::ClimateService* climateService = nullptr,
                           domain::MediaService* mediaService = nullptr,
                           domain::NavigationService* navService = nullptr,
                           QObject* parent = nullptr);
    ~HomeViewModel() override = default;

    // Telemetry getters
    [[nodiscard]] float speed() const noexcept { return m_speed; }
    [[nodiscard]] QString speedFormatted() const;
    [[nodiscard]] float batterySoc() const noexcept { return m_batterySoc; }
    [[nodiscard]] QString batterySocFormatted() const;
    [[nodiscard]] float rangeKm() const noexcept { return m_rangeKm; }
    [[nodiscard]] QString rangeKmFormatted() const;
    [[nodiscard]] QString gear() const;
    [[nodiscard]] QString driveMode() const;
    [[nodiscard]] QString systemStatus() const;
    [[nodiscard]] QString backendName() const { return QStringLiteral("SIMULATED VDI"); }
    [[nodiscard]] bool isDriving() const noexcept { return m_isDriving; }
    [[nodiscard]] bool isDegraded() const;
    [[nodiscard]] bool hasFault() const;
    [[nodiscard]] QString communicationHealth() const;

    // State awareness getters
    [[nodiscard]] QString vehicleContextState() const { return m_vehicleContextState; }
    [[nodiscard]] QString vehicleContextSubtitle() const;

    // Clock getters
    [[nodiscard]] QString timeFormatted() const { return m_timeFormatted; }
    [[nodiscard]] QString outsideTemperatureFormatted() const { return QStringLiteral("19°C"); }
    [[nodiscard]] QString greetingText() const;

    // Climate getters (Single source of truth: ClimateService)
    [[nodiscard]] float cabinTemperature() const noexcept { return m_cabinTemperature; }
    [[nodiscard]] QString cabinTemperatureFormatted() const;
    [[nodiscard]] float targetTemperature() const noexcept { return m_targetTemperature; }
    [[nodiscard]] QString targetTemperatureFormatted() const;
    [[nodiscard]] int fanSpeed() const noexcept { return m_fanSpeed; }
    [[nodiscard]] bool isAcActive() const noexcept { return m_isAcActive; }

    // Media getters (Single source of truth: MediaService)
    [[nodiscard]] QString mediaTitle() const { return m_mediaTitle; }
    [[nodiscard]] QString mediaArtist() const { return m_mediaArtist; }
    [[nodiscard]] bool isMediaPlaying() const noexcept { return m_isMediaPlaying; }
    [[nodiscard]] QString mediaElapsedFormatted() const;
    [[nodiscard]] QString mediaDurationFormatted() const;
    [[nodiscard]] float mediaProgress() const noexcept;

    // Navigation getters (Single source of truth: NavigationService)
    [[nodiscard]] QString navDestination() const;
    [[nodiscard]] QString navEta() const;
    [[nodiscard]] QString navDistance() const;
    [[nodiscard]] QString navManeuver() const;
    [[nodiscard]] QString navNextTurnIcon() const;

    // Commands (Dispatched to Domain Services)
    Q_INVOKABLE void toggleDriveMode();
    Q_INVOKABLE void accelerate(float deltaKmH);
    Q_INVOKABLE void brake();
    Q_INVOKABLE void setSimulatedSpeed(float speedKmH);
    Q_INVOKABLE void setVehicleContextState(const QString& state);
    Q_INVOKABLE void setScenario(const QString& scenario);
    Q_INVOKABLE void setFaultMode(const QString& faultMode);

    // Climate interactions (Commands ClimateService)
    Q_INVOKABLE void adjustTargetTemperature(float deltaCelsius);
    Q_INVOKABLE void toggleAcActive();
    Q_INVOKABLE void setFanSpeedLevel(int level);

    // Media interactions (Commands MediaService)
    Q_INVOKABLE void toggleMediaPlayPause();
    Q_INVOKABLE void nextMediaTrack();
    Q_INVOKABLE void prevMediaTrack();

signals:
    void speedChanged(float speed);
    void batterySocChanged(float soc);
    void rangeKmChanged(float range);
    void gearChanged(const QString& gear);
    void driveModeChanged(const QString& mode);
    void systemStatusChanged(const QString& status);
    void isDrivingChanged(bool isDriving);
    void vehicleContextStateChanged(const QString& state);
    void timeChanged();
    void cabinTemperatureChanged(float temp);
    void targetTemperatureChanged(float temp);
    void fanSpeedChanged(int speed);
    void isAcActiveChanged(bool active);
    void mediaChanged();
    void mediaPlaybackChanged(bool playing);
    void mediaProgressChanged();
    void navChanged();
    void degradedStatusChanged();

private:
    void handleStateUpdate(const domain::VehicleState& state);
    void handleHealthUpdate(vehicle::CommunicationHealth health);
    void updateClock();

    domain::VehicleService* m_vehicleService{nullptr};
    domain::SafetyPolicy* m_safetyPolicy{nullptr};
    vehicle::VehicleDataInterface* m_vdi{nullptr};
    domain::ClimateService* m_climateService{nullptr};
    domain::MediaService* m_mediaService{nullptr};
    domain::NavigationService* m_navService{nullptr};

    // Telemetry state
    float m_speed{0.0f};
    float m_batterySoc{92.0f};
    float m_rangeKm{410.0f};
    domain::Gear m_gear{domain::Gear::PARK};
    domain::DriveMode m_driveMode{domain::DriveMode::NORMAL};
    bool m_isDriving{false};
    vehicle::CommunicationHealth m_health{vehicle::CommunicationHealth::HEALTHY};

    // Contextual vehicle state (PARKED, DRIVING, REVERSE, CHARGING, FAULT)
    QString m_vehicleContextState{QStringLiteral("PARKED")};

    // Clock
    QString m_timeFormatted{QStringLiteral("10:42 AM")};
    QTimer* m_clockTimer{nullptr};

    // Climate
    float m_cabinTemperature{21.5f};
    float m_targetTemperature{22.0f};
    int m_fanSpeed{2};
    bool m_isAcActive{true};

    // Media
    QString m_mediaTitle{QStringLiteral("Midnight Drive")};
    QString m_mediaArtist{QStringLiteral("DriveOS Synthetics")};
    bool m_isMediaPlaying{true};
    uint32_t m_mediaElapsedSec{102};
    uint32_t m_mediaDurationSec{230};
    QTimer* m_playbackTimer{nullptr};
};

} // namespace driveos::presentation
