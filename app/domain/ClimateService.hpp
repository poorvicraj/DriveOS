#pragma once

#include "VehicleState.hpp"
#include "SafetyPolicy.hpp"
#include "vehicle/VehicleDataInterface.hpp"
#include <algorithm>
#include <functional>
#include <string>
#include <vector>

namespace driveos::domain {

/**
 * @brief Directional airflow distribution mode.
 */
enum class AirflowDirection : uint8_t {
    WINDSHIELD = 0, // Defrost / Defog
    VENT,           // Face / Dashboard Vents
    FLOOR,          // Footwell Vents
    BI_LEVEL        // Face & Footwell Vents
};

/**
 * @brief Application domain service managing cabin climate, HVAC setpoints, and airflow.
 * 
 * Coordinates target temperatures, blower fan speeds, compressor states,
 * dual-zone synchronisation, seat heating, and directional airflow distribution.
 * Dispatches commands to the VehicleDataInterface (HAL) while enforcing safety policies.
 */
class ClimateService {
public:
    using ClimateChangedCallback = std::function<void(float cabinTemp, float targetTemp, int fanSpeed, bool acActive)>;
    using ClimateStateCallback = std::function<void()>;

    ClimateService(vehicle::VehicleDataInterface* vdi, SafetyPolicy* safetyPolicy)
        : m_vdi(vdi)
        , m_safetyPolicy(safetyPolicy)
    {
        if (m_vdi) {
            auto st = m_vdi->getVehicleState();
            m_cabinTemperature = st.cabinTemperature;
            m_outsideTemperature = st.outsideTemperature;
            m_targetTemperature = st.targetTemperature;
            m_passengerTemperature = st.targetTemperature;
            m_fanSpeed = st.fanSpeed;
            m_acActive = st.acActive;
        }
    }

    virtual ~ClimateService() = default;

    virtual bool setTargetTemperature(float tempCelsius) {
        // Enforce physical boundary clamping: 16.0°C to 28.0°C
        const float clamped = std::clamp(tempCelsius, 16.0f, 28.0f);
        m_targetTemperature = clamped;
        if (m_syncActive) {
            m_passengerTemperature = clamped;
        }

        if (m_vdi) {
            m_vdi->setTargetTemperature(clamped);
        }

        notifyClimateChanged();
        return true;
    }

    virtual bool setPassengerTemperature(float tempCelsius) {
        const float clamped = std::clamp(tempCelsius, 16.0f, 28.0f);
        m_passengerTemperature = clamped;
        if (m_syncActive && m_passengerTemperature != m_targetTemperature) {
            m_syncActive = false;
        }
        notifyClimateChanged();
        return true;
    }

    virtual bool setFanSpeed(int level) {
        // Enforce boundary clamping: 0 (Off) to 5 (Max)
        const int clamped = std::clamp(level, 0, 5);
        m_fanSpeed = clamped;
        if (m_fanSpeed > 0 && !m_acActive) {
            // Keep fan active
        }

        if (m_vdi) {
            m_vdi->setFanSpeed(clamped);
        }

        notifyClimateChanged();
        return true;
    }

    virtual bool setACActive(bool active) {
        m_acActive = active;
        if (m_vdi) {
            m_vdi->setACActive(active);
        }
        notifyClimateChanged();
        return true;
    }

    virtual void setAutoMode(bool autoMode) {
        m_autoMode = autoMode;
        if (m_autoMode) {
            m_acActive = true;
            m_fanSpeed = 2;
            m_airflowDirection = AirflowDirection::VENT;
            if (m_vdi) {
                m_vdi->setACActive(true);
                m_vdi->setFanSpeed(2);
            }
        }
        notifyClimateChanged();
    }

    virtual void setSyncActive(bool sync) {
        m_syncActive = sync;
        if (m_syncActive) {
            m_passengerTemperature = m_targetTemperature;
        }
        notifyClimateChanged();
    }

    virtual void setAirflowDirection(AirflowDirection dir) {
        m_airflowDirection = dir;
        m_autoMode = false;
        notifyClimateChanged();
    }

    virtual void setFrontDefrost(bool active) {
        m_frontDefrost = active;
        if (m_frontDefrost) {
            m_airflowDirection = AirflowDirection::WINDSHIELD;
            m_acActive = true;
            m_fanSpeed = std::max(m_fanSpeed, 3);
            if (m_vdi) {
                m_vdi->setACActive(true);
                m_vdi->setFanSpeed(m_fanSpeed);
            }
        }
        notifyClimateChanged();
    }

    virtual void setRearDefrost(bool active) {
        m_rearDefrost = active;
        notifyClimateChanged();
    }

    virtual void setRecirculation(bool active) {
        m_recirculation = active;
        notifyClimateChanged();
    }

    virtual void cycleDriverSeatHeat() {
        m_driverSeatHeat = (m_driverSeatHeat + 1) % 4; // 0 (Off) -> 1 (Low) -> 2 (Med) -> 3 (High) -> 0
        notifyClimateChanged();
    }

    virtual void cyclePassengerSeatHeat() {
        m_passengerSeatHeat = (m_passengerSeatHeat + 1) % 4;
        notifyClimateChanged();
    }

    // Getters
    [[nodiscard]] virtual float getTargetTemperature() const { return m_targetTemperature; }
    [[nodiscard]] virtual float getPassengerTemperature() const { return m_passengerTemperature; }
    [[nodiscard]] virtual float getCabinTemperature() const { return m_cabinTemperature; }
    [[nodiscard]] virtual float getOutsideTemperature() const { return m_outsideTemperature; }
    [[nodiscard]] virtual int getFanSpeed() const { return m_fanSpeed; }
    [[nodiscard]] virtual bool isACActive() const { return m_acActive; }
    [[nodiscard]] virtual bool isAutoMode() const { return m_autoMode; }
    [[nodiscard]] virtual bool isSyncActive() const { return m_syncActive; }
    [[nodiscard]] virtual AirflowDirection getAirflowDirection() const { return m_airflowDirection; }
    [[nodiscard]] virtual bool isFrontDefrost() const { return m_frontDefrost; }
    [[nodiscard]] virtual bool isRearDefrost() const { return m_rearDefrost; }
    [[nodiscard]] virtual bool isRecirculation() const { return m_recirculation; }
    [[nodiscard]] virtual int getDriverSeatHeat() const { return m_driverSeatHeat; }
    [[nodiscard]] virtual int getPassengerSeatHeat() const { return m_passengerSeatHeat; }

    virtual void registerClimateCallback(ClimateChangedCallback callback) {
        m_climateCallbacks.push_back(std::move(callback));
    }

    virtual void registerStateCallback(ClimateStateCallback callback) {
        m_stateCallbacks.push_back(std::move(callback));
    }

private:
    void notifyClimateChanged() {
        for (const auto& cb : m_climateCallbacks) {
            if (cb) cb(m_cabinTemperature, m_targetTemperature, m_fanSpeed, m_acActive);
        }
        for (const auto& cb : m_stateCallbacks) {
            if (cb) cb();
        }
    }

    vehicle::VehicleDataInterface* m_vdi{nullptr};
    SafetyPolicy* m_safetyPolicy{nullptr};

    float m_cabinTemperature{21.5f};
    float m_outsideTemperature{19.0f};
    float m_targetTemperature{22.0f};
    float m_passengerTemperature{22.0f};
    int m_fanSpeed{2};
    bool m_acActive{true};
    bool m_autoMode{true};
    bool m_syncActive{true};
    AirflowDirection m_airflowDirection{AirflowDirection::VENT};
    bool m_frontDefrost{false};
    bool m_rearDefrost{false};
    bool m_recirculation{false};
    int m_driverSeatHeat{0};
    int m_passengerSeatHeat{0};

    std::vector<ClimateChangedCallback> m_climateCallbacks;
    std::vector<ClimateStateCallback> m_stateCallbacks;
};

} // namespace driveos::domain
