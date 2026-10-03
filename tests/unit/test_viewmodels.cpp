#include "presentation/ClimateViewModel.hpp"
#include "presentation/VehicleViewModel.hpp"
#include "presentation/MediaViewModel.hpp"
#include "presentation/HomeViewModel.hpp"
#include "domain/ClimateService.hpp"
#include "domain/VehicleService.hpp"
#include "domain/MediaService.hpp"
#include "domain/NavigationService.hpp"
#include "domain/SafetyPolicy.hpp"
#include "domain/VehicleStateManager.hpp"
#include "diagnostics/DiagnosticService.hpp"
#include "vehicle/SimulatedVehicleBackend.hpp"
#include <gtest/gtest.h>

using namespace driveos::presentation;
using namespace driveos::domain;
using namespace driveos::vehicle;
using namespace driveos::diagnostics;

// =============================================================================
// 1. ClimateViewModel Tests
// =============================================================================

TEST(ViewModelTestSuite, ClimateViewModelTemperatureAdjustment) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    ClimateService climateService(&backend, &safetyPolicy);

    ClimateViewModel vm(&climateService, &safetyPolicy);

    // Initial default temperature
    EXPECT_NEAR(vm.targetTemperature(), 22.0f, 1.0f);

    // Increment temperature
    const float prevTemp = vm.targetTemperature();
    vm.adjustTargetTemperature(1.0f);
    EXPECT_NEAR(vm.targetTemperature(), prevTemp + 1.0f, 0.1f);
    EXPECT_TRUE(vm.targetTemperatureFormatted().contains(QStringLiteral("°")));

    // Decrement temperature
    vm.adjustTargetTemperature(-2.0f);
    EXPECT_NEAR(vm.targetTemperature(), prevTemp - 1.0f, 0.1f);

    // Passenger temperature adjust
    const float prevPassTemp = vm.passengerTemperature();
    vm.adjustPassengerTemperature(0.5f);
    EXPECT_NEAR(vm.passengerTemperature(), prevPassTemp + 0.5f, 0.1f);

    // Boundary clamping (16.0°C to 28.0°C)
    climateService.setTargetTemperature(10.0f);
    EXPECT_GE(vm.targetTemperature(), 16.0f);

    climateService.setTargetTemperature(35.0f);
    EXPECT_LE(vm.targetTemperature(), 28.0f);
}

TEST(ViewModelTestSuite, ClimateViewModelHVACTogglesAndFanSpeed) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    ClimateService climateService(&backend, &safetyPolicy);

    ClimateViewModel vm(&climateService, &safetyPolicy);

    // Toggle AC
    const bool initialAc = vm.isAcActive();
    vm.toggleAc();
    EXPECT_EQ(vm.isAcActive(), !initialAc);

    // Toggle Auto mode
    const bool initialAuto = vm.isAutoMode();
    vm.toggleAuto();
    EXPECT_EQ(vm.isAutoMode(), !initialAuto);

    // Toggle Sync mode
    const bool initialSync = vm.isSyncActive();
    vm.toggleSync();
    EXPECT_EQ(vm.isSyncActive(), !initialSync);

    // Fan speed adjustment and formatted output
    vm.setFanSpeedLevel(3);
    EXPECT_EQ(vm.fanSpeed(), 3);
    EXPECT_EQ(vm.fanSpeedFormatted(), QStringLiteral("Level 3"));

    // Airflow mode selection
    vm.setAirflowMode(QStringLiteral("windshield"));
    EXPECT_EQ(vm.airflowMode(), QStringLiteral("windshield"));

    vm.setAirflowMode(QStringLiteral("floor"));
    EXPECT_EQ(vm.airflowMode(), QStringLiteral("floor"));

    vm.setAirflowMode(QStringLiteral("bilevel"));
    EXPECT_EQ(vm.airflowMode(), QStringLiteral("bilevel"));

    vm.setAirflowMode(QStringLiteral("vent"));
    EXPECT_EQ(vm.airflowMode(), QStringLiteral("vent"));

    // Seat heating cycling
    EXPECT_EQ(vm.driverSeatHeat(), 0);
    vm.cycleDriverSeatHeat();
    EXPECT_EQ(vm.driverSeatHeat(), 1);
    vm.cycleDriverSeatHeat();
    EXPECT_EQ(vm.driverSeatHeat(), 2);
    vm.cycleDriverSeatHeat();
    EXPECT_EQ(vm.driverSeatHeat(), 3);
    vm.cycleDriverSeatHeat();
    EXPECT_EQ(vm.driverSeatHeat(), 0);
}

TEST(ViewModelTestSuite, ClimateViewModelEssentialAllowedInMotion) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    ClimateService climateService(&backend, &safetyPolicy);

    ClimateViewModel vm(&climateService, &safetyPolicy);

    // Transition vehicle to driving in motion (65 km/h)
    stateManager.setOperationalState(OperationalState::DRIVING);
    stateManager.setSpeed(65.0f);

    EXPECT_TRUE(SafetyPolicy::isInMotion(stateManager.getVehicleState()));

    // Essential climate setpoints remain allowed while driving for comfort and safety
    vm.adjustTargetTemperature(0.5f);
    EXPECT_FALSE(vm.targetTemperatureFormatted().isEmpty());
}

// =============================================================================
// 2. VehicleViewModel Tests
// =============================================================================

TEST(ViewModelTestSuite, VehicleViewModelOperationalStateTransitions) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    VehicleService vehicleService(&backend, &safetyPolicy, &stateManager);
    DiagnosticService diagService(&stateManager, &backend);

    VehicleViewModel vm(&vehicleService, &safetyPolicy, &backend, &diagService);

    // Initial state
    EXPECT_EQ(vm.vehicleState(), QStringLiteral("PARKED"));
    EXPECT_TRUE(vm.isParked());
    EXPECT_FALSE(vm.isDriving());
    EXPECT_FALSE(vm.isReverse());
    EXPECT_FALSE(vm.isCharging());
    EXPECT_FALSE(vm.hasFault());

    // Transition to DRIVING
    vm.setVehicleState(QStringLiteral("DRIVING"));
    EXPECT_EQ(vm.vehicleState(), QStringLiteral("DRIVING"));
    EXPECT_TRUE(vm.isDriving());
    EXPECT_FALSE(vm.isParked());
    EXPECT_EQ(vm.gear(), QStringLiteral("D"));

    // Transition to REVERSE
    vm.setVehicleState(QStringLiteral("REVERSE"));
    EXPECT_EQ(vm.vehicleState(), QStringLiteral("REVERSE"));
    EXPECT_TRUE(vm.isReverse());
    EXPECT_EQ(vm.gear(), QStringLiteral("R"));

    // Transition to CHARGING
    vm.setVehicleState(QStringLiteral("CHARGING"));
    EXPECT_EQ(vm.vehicleState(), QStringLiteral("CHARGING"));
    EXPECT_TRUE(vm.isCharging());
    EXPECT_EQ(vm.gear(), QStringLiteral("P"));

    // Transition to FAULT
    vm.setVehicleState(QStringLiteral("FAULT"));
    EXPECT_EQ(vm.vehicleState(), QStringLiteral("FAULT"));
    EXPECT_TRUE(vm.hasFault());

    // Clear and restore to PARKED
    vm.clearFaults();
    EXPECT_FALSE(vm.hasFault());
}

TEST(ViewModelTestSuite, VehicleViewModelDriveModesAndClosures) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    VehicleService vehicleService(&backend, &safetyPolicy, &stateManager);
    DiagnosticService diagService(&stateManager, &backend);

    VehicleViewModel vm(&vehicleService, &safetyPolicy, &backend, &diagService);

    // Drive Mode selection when Parked (permitted)
    vm.setDriveMode(QStringLiteral("ECO"));
    EXPECT_EQ(vm.driveMode(), QStringLiteral("ECO"));

    vm.setDriveMode(QStringLiteral("SPORT"));
    EXPECT_EQ(vm.driveMode(), QStringLiteral("SPORT"));

    vm.setDriveMode(QStringLiteral("COMFORT"));
    EXPECT_EQ(vm.driveMode(), QStringLiteral("COMFORT"));

    // Prototype User Settings
    const bool prevHeadlights = vm.autoHeadlights();
    vm.toggleAutoHeadlights();
    EXPECT_EQ(vm.autoHeadlights(), !prevHeadlights);

    const bool prevLock = vm.autoLock();
    vm.toggleAutoLock();
    EXPECT_EQ(vm.autoLock(), !prevLock);

    vm.setDisplayBrightness(75);
    EXPECT_EQ(vm.displayBrightness(), 75);

    vm.adjustDisplayBrightness(10);
    EXPECT_EQ(vm.displayBrightness(), 85);
}

TEST(ViewModelTestSuite, VehicleViewModelDrivingSafetyGating) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    VehicleService vehicleService(&backend, &safetyPolicy, &stateManager);
    DiagnosticService diagService(&stateManager, &backend);

    VehicleViewModel vm(&vehicleService, &safetyPolicy, &backend, &diagService);

    // Initial parked state should not be restricted
    EXPECT_FALSE(vm.isRestricted());

    // Set driving in motion
    vm.setVehicleState(QStringLiteral("DRIVING"));
    EXPECT_TRUE(vm.isRestricted());

    // Deep configuration changes restricted while driving
    QString restrictionTitle;
    QObject::connect(&vm, &VehicleViewModel::restrictionNoticeTriggered,
                     [&](const QString& title, const QString&) {
                         restrictionTitle = title;
                     });

    vm.setDriveMode(QStringLiteral("SPORT"));
    EXPECT_FALSE(restrictionTitle.isEmpty());
}

TEST(ViewModelTestSuite, VehicleViewModelDiagnosticsAndDtcLifecycle) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    VehicleService vehicleService(&backend, &safetyPolicy, &stateManager);
    DiagnosticService diagService(&stateManager, &backend);

    VehicleViewModel vm(&vehicleService, &safetyPolicy, &backend, &diagService);

    EXPECT_FALSE(vm.hasActiveFaults());
    EXPECT_EQ(vm.diagnosticSummary(), QStringLiteral("Systems normal"));
    EXPECT_EQ(vm.activeDtcCount(), 0);

    // Inject fault via ViewModel
    vm.injectFault(QStringLiteral("HVAC_SENSOR_TIMEOUT"));

    EXPECT_TRUE(vm.hasActiveFaults());
    EXPECT_TRUE(vm.diagnosticSummary().contains(QStringLiteral("HVAC")));
    EXPECT_EQ(vm.activeDtcCount(), 1);

    // Recover
    vm.clearFaults();
    EXPECT_FALSE(vm.hasActiveFaults());
    EXPECT_EQ(vm.diagnosticSummary(), QStringLiteral("Systems normal"));
    EXPECT_EQ(vm.activeDtcCount(), 0);
}

// =============================================================================
// 3. MediaViewModel Tests
// =============================================================================

TEST(ViewModelTestSuite, MediaViewModelPlaybackAndVolumeControls) {
    VehicleStateManager stateManager;
    SafetyPolicy safetyPolicy(&stateManager);
    MediaService mediaService(&safetyPolicy);

    MediaViewModel vm(&mediaService);

    // Playback state toggle
    const bool wasPlaying = vm.isPlaying();
    vm.togglePlayPause();
    EXPECT_EQ(vm.isPlaying(), !wasPlaying);

    // Next track in simulated queue
    const QString prevTitle = vm.title();
    vm.nextTrack();
    EXPECT_FALSE(vm.title().isEmpty());
    EXPECT_FALSE(vm.artist().isEmpty());

    // Previous track
    vm.previousTrack();
    EXPECT_EQ(vm.title(), prevTitle);

    // Volume level setting
    vm.setVolumeLevel(70);
    EXPECT_EQ(vm.volume(), 70);

    // Mute toggle
    const bool wasMuted = vm.isMuted();
    vm.toggleMute();
    EXPECT_EQ(vm.isMuted(), !wasMuted);

    // Shuffle & repeat toggles
    const bool wasShuffle = vm.isShuffle();
    vm.toggleShuffle();
    EXPECT_EQ(vm.isShuffle(), !wasShuffle);

    const bool wasRepeat = vm.isRepeat();
    vm.toggleRepeat();
    EXPECT_EQ(vm.isRepeat(), !wasRepeat);

    // Source selection
    vm.setAudioSource(QStringLiteral("BLUETOOTH"));
    EXPECT_EQ(vm.audioSource(), QStringLiteral("BLUETOOTH"));
}

// =============================================================================
// 4. HomeViewModel / ShellViewModel Tests
// =============================================================================

TEST(ViewModelTestSuite, HomeViewModelTelemetryAndStatusSync) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    VehicleService vehicleService(&backend, &safetyPolicy, &stateManager);
    ClimateService climateService(&backend, &safetyPolicy);
    MediaService mediaService(&safetyPolicy);
    NavigationService navService(&safetyPolicy);

    HomeViewModel vm(&vehicleService, &safetyPolicy, &backend,
                     &climateService, &mediaService, &navService);

    // Telemetry reflects initialized backend
    EXPECT_GE(vm.batterySoc(), 0.0f);
    EXPECT_LE(vm.batterySoc(), 100.0f);
    EXPECT_FALSE(vm.batterySocFormatted().isEmpty());
    EXPECT_FALSE(vm.speedFormatted().isEmpty());
    EXPECT_FALSE(vm.rangeKmFormatted().isEmpty());
    EXPECT_EQ(vm.vehicleContextState(), QStringLiteral("PARKED"));

    // Contextual state update via HomeViewModel
    vm.setVehicleContextState(QStringLiteral("DRIVING"));
    EXPECT_EQ(vm.vehicleContextState(), QStringLiteral("DRIVING"));
    EXPECT_TRUE(vm.isDriving());
}
