#include "diagnostics/DiagnosticService.hpp"
#include "domain/VehicleStateManager.hpp"
#include "domain/VehicleService.hpp"
#include "domain/SafetyPolicy.hpp"
#include "vehicle/SimulatedVehicleBackend.hpp"
#include <gtest/gtest.h>

using namespace driveos::diagnostics;
using namespace driveos::domain;
using namespace driveos::vehicle;

// =============================================================================
// 1. In-Memory DTC Store Operations
// =============================================================================

TEST(DiagnosticSubsystemTest, InitialStateNominal) {
    DiagnosticService diagService;

    EXPECT_FALSE(diagService.hasActiveFaults());
    EXPECT_TRUE(diagService.getActiveDtcs().empty());
    EXPECT_TRUE(diagService.getAllDtcs().empty());
    EXPECT_EQ(diagService.getPrimaryFaultSummary(), "Systems normal");
}

TEST(DiagnosticSubsystemTest, RecordAndReadDtcs) {
    DiagnosticService diagService;

    diagService.recordFault(DtcCode::HVAC_SENSOR_TIMEOUT,
                            "HVAC_SENSOR_TIMEOUT",
                            "Cabin HVAC temperature sensor timeout",
                            DtcSeverity::WARNING);

    EXPECT_TRUE(diagService.hasActiveFaults());

    auto activeDtcs = diagService.getActiveDtcs();
    ASSERT_EQ(activeDtcs.size(), 1u);
    EXPECT_EQ(activeDtcs[0].code, "B1080");
    EXPECT_EQ(activeDtcs[0].identifier, "HVAC_SENSOR_TIMEOUT");
    EXPECT_EQ(activeDtcs[0].description, "Cabin HVAC temperature sensor timeout");
    EXPECT_EQ(activeDtcs[0].severity, DtcSeverity::WARNING);
    EXPECT_EQ(activeDtcs[0].status, DtcStatus::ACTIVE);
    EXPECT_EQ(activeDtcs[0].occurrenceCount, 1u);
    EXPECT_GT(activeDtcs[0].timestampMs, 0u);

    // Recording identical fault increments occurrence count
    diagService.recordFault(DtcCode::HVAC_SENSOR_TIMEOUT,
                            "HVAC_SENSOR_TIMEOUT",
                            "Cabin HVAC temperature sensor timeout",
                            DtcSeverity::WARNING);

    activeDtcs = diagService.getActiveDtcs();
    ASSERT_EQ(activeDtcs.size(), 1u);
    EXPECT_EQ(activeDtcs[0].occurrenceCount, 2u);
}

TEST(DiagnosticSubsystemTest, ActiveAndInactiveStatusTransitions) {
    DiagnosticService diagService;

    diagService.recordFault(DtcCode::HVAC_SENSOR_TIMEOUT, "HVAC_SENSOR_TIMEOUT", "HVAC fault", DtcSeverity::WARNING);
    diagService.recordFault(DtcCode::DOOR_SENSOR_FAULT, "DOOR_SENSOR_FAULT", "Door fault", DtcSeverity::WARNING);

    EXPECT_EQ(diagService.getActiveDtcs().size(), 2u);
    EXPECT_EQ(diagService.getAllDtcs().size(), 2u);

    // Clear single DTC
    EXPECT_TRUE(diagService.clearDtc(DtcCode::HVAC_SENSOR_TIMEOUT));

    // Active list contains only the remaining active fault
    auto active = diagService.getActiveDtcs();
    ASSERT_EQ(active.size(), 1u);
    EXPECT_EQ(active[0].code, DtcCode::DOOR_SENSOR_FAULT);

    // All DTCs list still contains both records (with correct inactive/active status)
    auto all = diagService.getAllDtcs();
    ASSERT_EQ(all.size(), 2u);
    auto hvacRecord = diagService.getDtc(DtcCode::HVAC_SENSOR_TIMEOUT);
    ASSERT_TRUE(hvacRecord.has_value());
    EXPECT_EQ(hvacRecord->status, DtcStatus::INACTIVE);

    auto doorRecord = diagService.getDtc(DtcCode::DOOR_SENSOR_FAULT);
    ASSERT_TRUE(doorRecord.has_value());
    EXPECT_EQ(doorRecord->status, DtcStatus::ACTIVE);
}

TEST(DiagnosticSubsystemTest, ClearAllDtcs) {
    DiagnosticService diagService;

    diagService.recordFault(DtcCode::HVAC_SENSOR_TIMEOUT, "HVAC fault", DtcSeverity::WARNING);
    diagService.recordFault(DtcCode::VEHICLE_DATA_TIMEOUT, "Data timeout", DtcSeverity::CRITICAL);

    EXPECT_TRUE(diagService.hasActiveFaults());

    diagService.clearDtcs();

    EXPECT_FALSE(diagService.hasActiveFaults());
    EXPECT_TRUE(diagService.getActiveDtcs().empty());
    EXPECT_EQ(diagService.getPrimaryFaultSummary(), "Systems normal");

    // Retained in historical store as INACTIVE
    auto all = diagService.getAllDtcs();
    ASSERT_EQ(all.size(), 2u);
    EXPECT_EQ(all[0].status, DtcStatus::INACTIVE);
    EXPECT_EQ(all[1].status, DtcStatus::INACTIVE);
}

// =============================================================================
// 2. Required Sample DTCs Verification
// =============================================================================

TEST(DiagnosticSubsystemTest, SamplePrototypeFaults) {
    DiagnosticService diagService;

    // 1. HVAC_SENSOR_TIMEOUT
    diagService.injectFault("HVAC_SENSOR_TIMEOUT");
    auto dtc1 = diagService.getDtc(DtcCode::HVAC_SENSOR_TIMEOUT);
    ASSERT_TRUE(dtc1.has_value());
    EXPECT_EQ(dtc1->identifier, "HVAC_SENSOR_TIMEOUT");
    EXPECT_EQ(dtc1->code, "B1080");
    EXPECT_EQ(dtc1->severity, DtcSeverity::WARNING);

    // 2. VEHICLE_DATA_TIMEOUT
    diagService.injectFault("VEHICLE_DATA_TIMEOUT");
    auto dtc2 = diagService.getDtc(DtcCode::VEHICLE_DATA_TIMEOUT);
    ASSERT_TRUE(dtc2.has_value());
    EXPECT_EQ(dtc2->identifier, "VEHICLE_DATA_TIMEOUT");
    EXPECT_EQ(dtc2->code, "U0100");
    EXPECT_EQ(dtc2->severity, DtcSeverity::CRITICAL);

    // 3. DOOR_SENSOR_FAULT
    diagService.injectFault("DOOR_SENSOR_FAULT");
    auto dtc3 = diagService.getDtc(DtcCode::DOOR_SENSOR_FAULT);
    ASSERT_TRUE(dtc3.has_value());
    EXPECT_EQ(dtc3->identifier, "DOOR_SENSOR_FAULT");
    EXPECT_EQ(dtc3->code, "B1024");
    EXPECT_EQ(dtc3->severity, DtcSeverity::WARNING);
}

// =============================================================================
// 3. Developer Fault Injection & Hardware Synchronization
// =============================================================================

TEST(DiagnosticSubsystemTest, DeveloperTriggeredFaults) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    DiagnosticService diagService(&stateManager, &backend);

    // CAN Timeout
    diagService.injectFault("CAN_TIMEOUT");
    EXPECT_TRUE(diagService.hasActiveFaults());
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::FAULT);
    EXPECT_EQ(stateManager.getCommunicationHealth(), CommunicationHealth::DISCONNECTED);

    diagService.clearDtcs();
    EXPECT_FALSE(diagService.hasActiveFaults());
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    EXPECT_EQ(stateManager.getCommunicationHealth(), CommunicationHealth::HEALTHY);

    // HVAC sensor unavailable
    diagService.injectFault("HVAC_SENSOR_UNAVAILABLE");
    EXPECT_TRUE(diagService.hasActiveFaults());
    auto hvacDtc = diagService.getDtc("HVAC_SENSOR_UNAVAILABLE");
    ASSERT_TRUE(hvacDtc.has_value());
    EXPECT_EQ(hvacDtc->code, "B1081");

    diagService.clearDtcs();

    // Invalid vehicle signal
    diagService.injectFault("INVALID_VEHICLE_SIGNAL");
    EXPECT_TRUE(diagService.hasActiveFaults());
    auto invDtc = diagService.getDtc("INVALID_VEHICLE_SIGNAL");
    ASSERT_TRUE(invDtc.has_value());
    EXPECT_EQ(invDtc->code, "U0401");
}

// =============================================================================
// 4. Fault -> Warning -> Clear -> State Restoration (No Stale State)
// =============================================================================

TEST(DiagnosticSubsystemTest, CompleteFaultAndRecoveryLifecycle) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    DiagnosticService diagService(&stateManager, &backend);

    // Step 1: Normal initial state
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    EXPECT_EQ(stateManager.getCommunicationHealth(), CommunicationHealth::HEALTHY);
    EXPECT_FALSE(diagService.hasActiveFaults());
    EXPECT_EQ(diagService.getPrimaryFaultSummary(), "Systems normal");

    // Step 2: Fault injected
    diagService.injectFault("VEHICLE_DATA_TIMEOUT");

    EXPECT_TRUE(diagService.hasActiveFaults());
    EXPECT_EQ(diagService.getPrimaryFaultSummary(), "Vehicle data unavailable");
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::FAULT);
    EXPECT_EQ(stateManager.getCommunicationHealth(), CommunicationHealth::DISCONNECTED);

    // Step 3: Fault cleared & recovery
    diagService.clearDtcs();

    // Step 4: Normal state completely restored (no stale fault state left)
    EXPECT_FALSE(diagService.hasActiveFaults());
    EXPECT_EQ(diagService.getPrimaryFaultSummary(), "Systems normal");
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    EXPECT_EQ(stateManager.getCommunicationHealth(), CommunicationHealth::HEALTHY);
    EXPECT_FALSE(stateManager.hasFault());
    EXPECT_FALSE(stateManager.isDegraded());
}

// =============================================================================
// 5. Service Layer Observation & Recovery Callbacks
// =============================================================================

TEST(DiagnosticSubsystemTest, ServiceObservationAndRecoveryCallbacks) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    DiagnosticService diagService(&stateManager, &backend);
    VehicleService vehicleService(&backend, &safetyPolicy, &stateManager);

    int dtcCallbackCount = 0;
    diagService.registerDtcCallback([&](const std::vector<DtcRecord>& /*dtcs*/) {
        dtcCallbackCount++;
    });

    // 1. Initial nominal status
    EXPECT_FALSE(diagService.hasActiveFaults());
    EXPECT_EQ(diagService.getPrimaryFaultSummary(), "Systems normal");
    EXPECT_FALSE(vehicleService.hasFault());

    // 2. Developer triggers fault injection
    diagService.injectFault("HVAC_SENSOR_TIMEOUT");

    EXPECT_TRUE(diagService.hasActiveFaults());
    EXPECT_EQ(diagService.getPrimaryFaultSummary(), "HVAC sensor timeout");
    EXPECT_GT(dtcCallbackCount, 0);
    ASSERT_EQ(diagService.getActiveDtcs().size(), 1u);

    auto activeDtcs = diagService.getActiveDtcs();
    EXPECT_EQ(activeDtcs[0].code, "B1080");
    EXPECT_EQ(activeDtcs[0].identifier, "HVAC_SENSOR_TIMEOUT");
    EXPECT_EQ(activeDtcs[0].severity, DtcSeverity::WARNING);
    EXPECT_EQ(activeDtcs[0].status, DtcStatus::ACTIVE);

    // 3. Trigger recovery
    diagService.clearDtcs();

    // 4. Verification of full restoration
    EXPECT_FALSE(diagService.hasActiveFaults());
    EXPECT_EQ(diagService.getPrimaryFaultSummary(), "Systems normal");
    EXPECT_TRUE(diagService.getActiveDtcs().empty());
    EXPECT_FALSE(vehicleService.hasFault());
    EXPECT_EQ(stateManager.getCommunicationHealth(), CommunicationHealth::HEALTHY);
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
}

