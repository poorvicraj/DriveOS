#pragma once

#include "BaseViewModel.hpp"
#include "domain/VehicleService.hpp"
#include "domain/SafetyPolicy.hpp"
#include "vehicle/VehicleDataInterface.hpp"
#include "diagnostics/DiagnosticService.hpp"
#include <QString>
#include <QVariantList>
#include <QVariantMap>

namespace driveos::presentation {

/**
 * @brief ViewModel managing the primary Vehicle Overview and Chassis Status.
 * 
 * Provides structured telemetry hierarchies, closures & doors visualization,
 * user-configurable prototype settings (Drive Mode, Lighting, Doors, Display),
 * enforces driver distraction safety policies when in motion, and exposes
 * diagnostic trouble code (DTC) status and developer fault injection.
 */
class VehicleViewModel : public BaseViewModel {
    Q_OBJECT

    // Overview & Telemetry Hierarchy
    Q_PROPERTY(QString vehicleState READ vehicleState NOTIFY vehicleStateChanged)
    Q_PROPERTY(QString stateDescription READ stateDescription NOTIFY vehicleStateChanged)
    Q_PROPERTY(float speed READ speed NOTIFY vehicleStateChanged)
    Q_PROPERTY(QString speedFormatted READ speedFormatted NOTIFY vehicleStateChanged)
    Q_PROPERTY(float batterySoc READ batterySoc NOTIFY batterySocChanged)
    Q_PROPERTY(QString batterySocFormatted READ batterySocFormatted NOTIFY batterySocChanged)
    Q_PROPERTY(float rangeKm READ rangeKm NOTIFY vehicleStateChanged)
    Q_PROPERTY(QString rangeKmFormatted READ rangeKmFormatted NOTIFY vehicleStateChanged)
    Q_PROPERTY(float batteryTemperature READ batteryTemperature NOTIFY vehicleStateChanged)
    Q_PROPERTY(QString batteryTemperatureFormatted READ batteryTemperatureFormatted NOTIFY vehicleStateChanged)
    Q_PROPERTY(QString driveMode READ driveMode NOTIFY driveModeChanged)
    Q_PROPERTY(QString ignitionState READ ignitionState NOTIFY vehicleStateChanged)
    Q_PROPERTY(QString gear READ gear NOTIFY vehicleStateChanged)

    // Body Closures & Doors
    Q_PROPERTY(bool frontLeftDoorOpen READ frontLeftDoorOpen NOTIFY doorsChanged)
    Q_PROPERTY(bool frontRightDoorOpen READ frontRightDoorOpen NOTIFY doorsChanged)
    Q_PROPERTY(bool rearLeftDoorOpen READ rearLeftDoorOpen NOTIFY doorsChanged)
    Q_PROPERTY(bool rearRightDoorOpen READ rearRightDoorOpen NOTIFY doorsChanged)
    Q_PROPERTY(bool doorsAllClosed READ doorsAllClosed NOTIFY doorsChanged)
    Q_PROPERTY(bool doorsLocked READ doorsLocked NOTIFY doorsChanged)

    // User Prototype Settings
    Q_PROPERTY(bool autoHeadlights READ autoHeadlights NOTIFY settingsChanged)
    Q_PROPERTY(bool autoLock READ autoLock NOTIFY settingsChanged)
    Q_PROPERTY(int displayBrightness READ displayBrightness NOTIFY settingsChanged)
    Q_PROPERTY(bool onePedalDrive READ onePedalDrive NOTIFY settingsChanged)
    Q_PROPERTY(bool childLock READ childLock NOTIFY settingsChanged)

    // Driving Safety & Restriction Awareness
    Q_PROPERTY(bool isRestricted READ isRestricted NOTIFY restrictionChanged)
    Q_PROPERTY(QString restrictionReason READ restrictionReason CONSTANT)
    Q_PROPERTY(bool isDriving READ isDriving NOTIFY vehicleStateChanged)
    Q_PROPERTY(bool isParked READ isParked NOTIFY vehicleStateChanged)
    Q_PROPERTY(bool isReverse READ isReverse NOTIFY vehicleStateChanged)
    Q_PROPERTY(bool isCharging READ isCharging NOTIFY vehicleStateChanged)
    Q_PROPERTY(bool hasFault READ hasFault NOTIFY vehicleStateChanged)

    // Diagnostics & Fault Subsystem
    Q_PROPERTY(bool hasActiveFaults READ hasActiveFaults NOTIFY diagnosticsChanged)
    Q_PROPERTY(QString diagnosticSummary READ diagnosticSummary NOTIFY diagnosticsChanged)
    Q_PROPERTY(int activeDtcCount READ activeDtcCount NOTIFY diagnosticsChanged)
    Q_PROPERTY(QVariantList activeDtcs READ activeDtcs NOTIFY diagnosticsChanged)

public:
    explicit VehicleViewModel(domain::VehicleService* vehicleService,
                            domain::SafetyPolicy* safetyPolicy,
                            vehicle::VehicleDataInterface* vdi = nullptr,
                            diagnostics::DiagnosticService* diagService = nullptr,
                            QObject* parent = nullptr);
    ~VehicleViewModel() override = default;

    // Telemetry getters
    [[nodiscard]] QString vehicleState() const;
    [[nodiscard]] QString stateDescription() const;
    [[nodiscard]] float speed() const;
    [[nodiscard]] QString speedFormatted() const;
    [[nodiscard]] float batterySoc() const;
    [[nodiscard]] QString batterySocFormatted() const;
    [[nodiscard]] float rangeKm() const;
    [[nodiscard]] QString rangeKmFormatted() const;
    [[nodiscard]] float batteryTemperature() const;
    [[nodiscard]] QString batteryTemperatureFormatted() const;
    [[nodiscard]] QString driveMode() const;
    [[nodiscard]] QString ignitionState() const;
    [[nodiscard]] QString gear() const;

    // Door getters
    [[nodiscard]] bool frontLeftDoorOpen() const;
    [[nodiscard]] bool frontRightDoorOpen() const;
    [[nodiscard]] bool rearLeftDoorOpen() const;
    [[nodiscard]] bool rearRightDoorOpen() const;
    [[nodiscard]] bool doorsAllClosed() const;
    [[nodiscard]] bool doorsLocked() const;

    // Settings getters
    [[nodiscard]] bool autoHeadlights() const noexcept { return m_autoHeadlights; }
    [[nodiscard]] bool autoLock() const noexcept { return m_autoLock; }
    [[nodiscard]] int displayBrightness() const noexcept { return m_displayBrightness; }
    [[nodiscard]] bool onePedalDrive() const noexcept { return m_onePedalDrive; }
    [[nodiscard]] bool childLock() const noexcept { return m_childLock; }

    // Restriction getters
    [[nodiscard]] bool isRestricted() const;
    [[nodiscard]] QString restrictionReason() const {
        return QStringLiteral("Unavailable while driving");
    }
    [[nodiscard]] bool isDriving() const;
    [[nodiscard]] bool isParked() const;
    [[nodiscard]] bool isReverse() const;
    [[nodiscard]] bool isCharging() const;
    [[nodiscard]] bool hasFault() const;

    // Diagnostics getters
    [[nodiscard]] bool hasActiveFaults() const;
    [[nodiscard]] QString diagnosticSummary() const;
    [[nodiscard]] int activeDtcCount() const;
    [[nodiscard]] QVariantList activeDtcs() const;

    // Invocable Actions
    Q_INVOKABLE void setDriveMode(const QString& mode);
    Q_INVOKABLE void toggleAutoHeadlights();
    Q_INVOKABLE void toggleAutoLock();
    Q_INVOKABLE void setDisplayBrightness(int level);
    Q_INVOKABLE void adjustDisplayBrightness(int delta);
    Q_INVOKABLE void toggleOnePedalDrive();
    Q_INVOKABLE void toggleChildLock();
    Q_INVOKABLE void toggleDoorLock();
    Q_INVOKABLE void toggleDoor(const QString& doorName);
    Q_INVOKABLE void setVehicleState(const QString& state);
    Q_INVOKABLE void setScenario(const QString& scenario);
    Q_INVOKABLE void setFaultMode(const QString& faultMode);

    // Diagnostics & Fault Invocables
    Q_INVOKABLE void injectFault(const QString& faultKey);
    Q_INVOKABLE void clearFaults();
    Q_INVOKABLE void clearDtc(const QString& codeOrId);

signals:
    void vehicleStateChanged();
    void batterySocChanged();
    void driveModeChanged();
    void doorsChanged();
    void settingsChanged();
    void restrictionChanged();
    void restrictionNoticeTriggered(const QString& title, const QString& message);
    void diagnosticsChanged();

private:
    void syncFromVehicleState(const domain::VehicleState& state);

    domain::VehicleService* m_vehicleService{nullptr};
    domain::SafetyPolicy* m_safetyPolicy{nullptr};
    vehicle::VehicleDataInterface* m_vdi{nullptr};
    diagnostics::DiagnosticService* m_diagService{nullptr};

    domain::VehicleState m_cachedState{};

    // User Configurable Prototype Settings
    bool m_autoHeadlights{true};
    bool m_autoLock{true};
    int m_displayBrightness{85};
    bool m_onePedalDrive{true};
    bool m_childLock{false};
    bool m_doorsLocked{true};
};

} // namespace driveos::presentation
