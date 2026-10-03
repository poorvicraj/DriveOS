#pragma once

#include "BaseViewModel.hpp"
#include "domain/ClimateService.hpp"
#include "domain/SafetyPolicy.hpp"
#include <QString>

namespace driveos::presentation {

/**
 * @brief ViewModel for the Climate experience in DriveOS.
 * 
 * Exposes core HVAC setpoints, dual-zone target temperatures, fan speeds,
 * directional airflow modes, seat heating, and vehicle-state contextual awareness.
 */
class ClimateViewModel : public BaseViewModel {
    Q_OBJECT

    // Temperature & Ambient Readouts
    Q_PROPERTY(float cabinTemperature READ cabinTemperature NOTIFY climateChanged)
    Q_PROPERTY(QString cabinTemperatureFormatted READ cabinTemperatureFormatted NOTIFY climateChanged)
    Q_PROPERTY(float targetTemperature READ targetTemperature NOTIFY climateChanged)
    Q_PROPERTY(QString targetTemperatureFormatted READ targetTemperatureFormatted NOTIFY climateChanged)
    Q_PROPERTY(float passengerTemperature READ passengerTemperature NOTIFY climateChanged)
    Q_PROPERTY(QString passengerTemperatureFormatted READ passengerTemperatureFormatted NOTIFY climateChanged)
    Q_PROPERTY(float outsideTemperature READ outsideTemperature NOTIFY climateChanged)
    Q_PROPERTY(QString outsideTemperatureFormatted READ outsideTemperatureFormatted NOTIFY climateChanged)

    // Primary HVAC States
    Q_PROPERTY(bool isAcActive READ isAcActive NOTIFY climateChanged)
    Q_PROPERTY(bool isAutoMode READ isAutoMode NOTIFY climateChanged)
    Q_PROPERTY(bool isSyncActive READ isSyncActive NOTIFY climateChanged)
    Q_PROPERTY(int fanSpeed READ fanSpeed NOTIFY climateChanged)
    Q_PROPERTY(QString fanSpeedFormatted READ fanSpeedFormatted NOTIFY climateChanged)
    Q_PROPERTY(QString airflowMode READ airflowMode NOTIFY climateChanged)

    // Defrost & Air Handling
    Q_PROPERTY(bool isFrontDefrost READ isFrontDefrost NOTIFY climateChanged)
    Q_PROPERTY(bool isRearDefrost READ isRearDefrost NOTIFY climateChanged)
    Q_PROPERTY(bool isRecirculation READ isRecirculation NOTIFY climateChanged)

    // Seat Heating (3-Stage)
    Q_PROPERTY(int driverSeatHeat READ driverSeatHeat NOTIFY climateChanged)
    Q_PROPERTY(int passengerSeatHeat READ passengerSeatHeat NOTIFY climateChanged)

    // Thermal Dynamics Flags
    Q_PROPERTY(bool isHeating READ isHeating NOTIFY climateChanged)
    Q_PROPERTY(bool isCooling READ isCooling NOTIFY climateChanged)

public:
    explicit ClimateViewModel(domain::ClimateService* climateService,
                            domain::SafetyPolicy* safetyPolicy,
                            QObject* parent = nullptr);
    ~ClimateViewModel() override = default;

    // Getters
    [[nodiscard]] float cabinTemperature() const;
    [[nodiscard]] QString cabinTemperatureFormatted() const;
    [[nodiscard]] float targetTemperature() const;
    [[nodiscard]] QString targetTemperatureFormatted() const;
    [[nodiscard]] float passengerTemperature() const;
    [[nodiscard]] QString passengerTemperatureFormatted() const;
    [[nodiscard]] float outsideTemperature() const;
    [[nodiscard]] QString outsideTemperatureFormatted() const;

    [[nodiscard]] bool isAcActive() const;
    [[nodiscard]] bool isAutoMode() const;
    [[nodiscard]] bool isSyncActive() const;
    [[nodiscard]] int fanSpeed() const;
    [[nodiscard]] QString fanSpeedFormatted() const;
    [[nodiscard]] QString airflowMode() const;

    [[nodiscard]] bool isFrontDefrost() const;
    [[nodiscard]] bool isRearDefrost() const;
    [[nodiscard]] bool isRecirculation() const;
    [[nodiscard]] int driverSeatHeat() const;
    [[nodiscard]] int passengerSeatHeat() const;

    [[nodiscard]] bool isHeating() const;
    [[nodiscard]] bool isCooling() const;

    // Invocable Actions
    Q_INVOKABLE void adjustTargetTemperature(float delta);
    Q_INVOKABLE void adjustPassengerTemperature(float delta);
    Q_INVOKABLE void setFanSpeedLevel(int level);
    Q_INVOKABLE void toggleAc();
    Q_INVOKABLE void toggleAuto();
    Q_INVOKABLE void toggleSync();
    Q_INVOKABLE void setAirflowMode(const QString& mode);
    Q_INVOKABLE void toggleFrontDefrost();
    Q_INVOKABLE void toggleRearDefrost();
    Q_INVOKABLE void toggleRecirculation();
    Q_INVOKABLE void cycleDriverSeatHeat();
    Q_INVOKABLE void cyclePassengerSeatHeat();

signals:
    void climateChanged();

private:
    domain::ClimateService* m_climateService{nullptr};
    domain::SafetyPolicy* m_safetyPolicy{nullptr};
};

} // namespace driveos::presentation
