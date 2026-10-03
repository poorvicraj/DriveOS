#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include <functional>
#include <mutex>
#include <memory>
#include <optional>

namespace driveos::domain {
class VehicleStateManager;
struct FaultRecord;
}

namespace driveos::vehicle {
class VehicleDataInterface;
enum class CommunicationHealth : uint8_t;
}

namespace driveos::diagnostics {

/**
 * @brief Severity level for diagnostic trouble codes.
 */
enum class DtcSeverity : uint8_t {
    INFO = 0,
    WARNING,
    CRITICAL
};

/**
 * @brief Active status lifecycle of a DTC.
 */
enum class DtcStatus : uint8_t {
    INACTIVE = 0,
    ACTIVE,
    CONFIRMED,
    STORED
};

/**
 * @brief Diagnostic Trouble Code record representation.
 */
struct DtcRecord {
    std::string code;           // Standard alphanumeric code, e.g., "B1080", "U0100"
    std::string identifier;     // Symbolic name, e.g., "HVAC_SENSOR_TIMEOUT"
    std::string description;    // Plain-text fault explanation
    DtcSeverity severity{DtcSeverity::WARNING};
    DtcStatus status{DtcStatus::ACTIVE};
    uint64_t timestampMs{0};
    uint32_t occurrenceCount{1};
};

/**
 * @brief Known standard prototype DTC identifiers and codes.
 */
namespace DtcCode {
    inline constexpr const char* HVAC_SENSOR_TIMEOUT = "B1080";
    inline constexpr const char* VEHICLE_DATA_TIMEOUT = "U0100";
    inline constexpr const char* DOOR_SENSOR_FAULT = "B1024";
    inline constexpr const char* CAN_TIMEOUT = "U0111";
    inline constexpr const char* INVALID_VEHICLE_SIGNAL = "U0401";
    inline constexpr const char* HVAC_SENSOR_UNAVAILABLE = "B1081";
}

/**
 * @brief Lightweight Diagnostic Subsystem Interface & Implementation.
 * 
 * Manages active and confirmed DTCs with clear and query semantics.
 * 
 * IMPORTANT ARCHITECTURAL STATEMENT:
 * "This project implements a limited diagnostic prototype inspired by UDS concepts;
 * it is not a complete ISO 14229 implementation."
 */
class DiagnosticService {
public:
    using DtcListCallback = std::function<void(const std::vector<DtcRecord>&)>;
    using FaultCallback = std::function<void(const DtcRecord&)>;

    explicit DiagnosticService(domain::VehicleStateManager* stateManager = nullptr,
                              vehicle::VehicleDataInterface* vdi = nullptr);
    virtual ~DiagnosticService() = default;

    // --- Query Operations ---
    [[nodiscard]] virtual std::vector<DtcRecord> getActiveDtcs() const;
    [[nodiscard]] virtual std::vector<DtcRecord> getAllDtcs() const;
    [[nodiscard]] virtual std::optional<DtcRecord> getDtc(const std::string& codeOrId) const;
    [[nodiscard]] virtual bool hasActiveFaults() const;
    [[nodiscard]] virtual std::string getPrimaryFaultSummary() const;

    // --- DTC Lifecycle & Clearing ---
    virtual void clearDtcs();
    virtual bool clearDtc(const std::string& codeOrId);

    // --- Fault Recording ---
    virtual void recordFault(const std::string& code,
                             const std::string& description,
                             DtcSeverity severity = DtcSeverity::WARNING);
    virtual void recordFault(const std::string& code,
                             const std::string& identifier,
                             const std::string& description,
                             DtcSeverity severity);

    // --- Developer Fault Injection Hooks ---
    virtual bool injectFault(const std::string& faultKey);

    // --- Observer Callbacks ---
    virtual void registerDtcCallback(DtcListCallback callback);
    virtual void registerFaultCallback(FaultCallback callback);

    // --- Wiring Dependencies ---
    void setStateManager(domain::VehicleStateManager* stateManager);
    void setVehicleDataInterface(vehicle::VehicleDataInterface* vdi);

private:
    void notifyObservers();
    void notifyFault(const DtcRecord& record);

    mutable std::mutex m_mutex;
    domain::VehicleStateManager* m_stateManager{nullptr};
    vehicle::VehicleDataInterface* m_vdi{nullptr};

    std::vector<DtcRecord> m_dtcStore;
    std::vector<DtcListCallback> m_dtcCallbacks;
    std::vector<FaultCallback> m_faultCallbacks;
};

} // namespace driveos::diagnostics
