#include <gtest/gtest.h>
#include "domain/VehicleState.hpp"
#include "domain/VehicleStateManager.hpp"
#include "domain/SafetyPolicy.hpp"
#include "domain/FaultModel.hpp"
#include "domain/VehicleService.hpp"
#include "domain/ClimateService.hpp"
#include "domain/MediaService.hpp"
#include "domain/NavigationService.hpp"
#include "diagnostics/DiagnosticService.hpp"
#include "vehicle/VehicleDataInterface.hpp"
#include "vehicle/SimulatedVehicleBackend.hpp"

using namespace driveos::domain;
using namespace driveos::diagnostics;
using namespace driveos::vehicle;

// Lightweight mock for architectural foundation tests
class MockVehicleDataInterface : public VehicleDataInterface {
public:
    bool initialize() override { return true; }
    void shutdown() override {}

    [[nodiscard]] VehicleState getVehicleState() const override { return m_state; }
    [[nodiscard]] CommunicationHealth getCommunicationHealth() const override { return m_health; }

    void setTargetTemperature(float temp) override { m_targetTemp = temp; }
    void setFanSpeed(int level) override { m_fanSpeed = level; }
    void setACActive(bool active) override { m_acActive = active; }
    void setDriveMode(DriveMode mode) override { m_mode = mode; m_state.driveMode = mode; }
    void setDoorLock(bool locked) override { m_locked = locked; }
    void setOperationalState(OperationalState opState, Gear gear, float speedKmH) override {
        m_state.operationalState = opState;
        m_state.gear = gear;
        m_state.speed = speedKmH;
    }
    void toggleDoor(const std::string& doorName) override {
        if (doorName == "FL") m_state.doors.frontLeftOpen = !m_state.doors.frontLeftOpen;
    }
    void setSpeed(float speedKmH) override { m_state.speed = speedKmH; }

    void registerStateCallback(StateCallback callback) override { m_stateCb = std::move(callback); }
    void registerHealthCallback(HealthCallback callback) override { m_healthCb = std::move(callback); }
    void registerFaultCallback(FaultCallback callback) override { m_faultCb = std::move(callback); }

    VehicleState m_state{};
    CommunicationHealth m_health{CommunicationHealth::HEALTHY};
    float m_targetTemp{22.0f};
    int m_fanSpeed{2};
    bool m_acActive{true};
    DriveMode m_mode{DriveMode::NORMAL};
    bool m_locked{true};

    StateCallback m_stateCb;
    HealthCallback m_healthCb;
    FaultCallback m_faultCb;
};

TEST(ArchitectureFoundationTest, VehicleStateDefaultInitialization) {
    VehicleState state{};
    EXPECT_FLOAT_EQ(state.speed, 0.0f);
    EXPECT_EQ(state.operationalState, OperationalState::PARKED);
    EXPECT_EQ(state.gear, Gear::PARK);
    EXPECT_EQ(state.driveMode, DriveMode::NORMAL);
    EXPECT_GT(state.batterySoc, 0.0f);
    EXPECT_FALSE(state.doors.frontLeftOpen);
}

TEST(ArchitectureFoundationTest, SafetyPolicyAllowsAllWhenParked) {
    SafetyPolicy policy;
    VehicleState state{};
    state.speed = 0.0f;
    state.gear = Gear::PARK;

    EXPECT_FALSE(SafetyPolicy::isInMotion(state));

    auto evalNav = policy.evaluateInteraction(InteractionCategory::PRIMARY_NAVIGATION, state);
    EXPECT_TRUE(evalNav.isAllowed);

    auto evalDeep = policy.evaluateInteraction(InteractionCategory::DEEP_SETTINGS, state);
    EXPECT_TRUE(evalDeep.isAllowed);
}

TEST(ArchitectureFoundationTest, SafetyPolicyRestrictsDeepSettingsInMotion) {
    SafetyPolicy policy;
    VehicleState state{};
    state.speed = 45.0f;
    state.gear = Gear::DRIVE;

    EXPECT_TRUE(SafetyPolicy::isInMotion(state));

    // Primary navigation and basic HVAC remain permitted
    auto evalNav = policy.evaluateInteraction(InteractionCategory::PRIMARY_NAVIGATION, state);
    EXPECT_TRUE(evalNav.isAllowed);

    auto evalHvac = policy.evaluateInteraction(InteractionCategory::BASIC_HVAC, state);
    EXPECT_TRUE(evalHvac.isAllowed);

    // Deep settings and keyboard input are restricted
    auto evalDeep = policy.evaluateInteraction(InteractionCategory::DEEP_SETTINGS, state);
    EXPECT_FALSE(evalDeep.isAllowed);
    EXPECT_FALSE(evalDeep.restrictionReason.empty());

    auto evalText = policy.evaluateInteraction(InteractionCategory::NUMERIC_OR_TEXT_INPUT, state);
    EXPECT_FALSE(evalText.isAllowed);
}

TEST(ArchitectureFoundationTest, SignalValueLifecycle) {
    SignalValue<float> speedSignal{};
    EXPECT_EQ(speedSignal.status, SignalStatus::NOT_AVAILABLE);
    EXPECT_FALSE(speedSignal.isValid());

    speedSignal.value = 60.0f;
    speedSignal.status = SignalStatus::VALID;
    EXPECT_TRUE(speedSignal.isValid());
    EXPECT_FALSE(speedSignal.isStale());

    speedSignal.status = SignalStatus::STALE;
    EXPECT_TRUE(speedSignal.isStale());
    EXPECT_FALSE(speedSignal.isValid());
}

TEST(ArchitectureFoundationTest, ClimateServiceClamping) {
    MockVehicleDataInterface mockVdi;
    SafetyPolicy safety;
    ClimateService climate(&mockVdi, &safety);

    // Clamps below minimum (16.0)
    climate.setTargetTemperature(12.0f);
    EXPECT_FLOAT_EQ(mockVdi.m_targetTemp, 16.0f);

    // Clamps above maximum (28.0)
    climate.setTargetTemperature(35.0f);
    EXPECT_FLOAT_EQ(mockVdi.m_targetTemp, 28.0f);

    // Valid value passed through
    climate.setTargetTemperature(21.5f);
    EXPECT_FLOAT_EQ(mockVdi.m_targetTemp, 21.5f);

    // Fan speed clamping (0 to 5)
    climate.setFanSpeed(-1);
    EXPECT_EQ(mockVdi.m_fanSpeed, 0);

    climate.setFanSpeed(10);
    EXPECT_EQ(mockVdi.m_fanSpeed, 5);
}

TEST(ArchitectureFoundationTest, ClimateServiceDualZoneAndAirflow) {
    MockVehicleDataInterface mockVdi;
    SafetyPolicy safety;
    ClimateService climate(&mockVdi, &safety);

    // Airflow direction switching
    climate.setAirflowDirection(AirflowDirection::VENT);
    EXPECT_EQ(climate.getAirflowDirection(), AirflowDirection::VENT);

    climate.setAirflowDirection(AirflowDirection::WINDSHIELD);
    EXPECT_EQ(climate.getAirflowDirection(), AirflowDirection::WINDSHIELD);

    climate.setAirflowDirection(AirflowDirection::FLOOR);
    EXPECT_EQ(climate.getAirflowDirection(), AirflowDirection::FLOOR);

    climate.setAirflowDirection(AirflowDirection::BI_LEVEL);
    EXPECT_EQ(climate.getAirflowDirection(), AirflowDirection::BI_LEVEL);

    // Dual zone sync behavior
    climate.setSyncActive(true);
    climate.setTargetTemperature(23.0f);
    EXPECT_FLOAT_EQ(climate.getTargetTemperature(), 23.0f);
    EXPECT_FLOAT_EQ(climate.getPassengerTemperature(), 23.0f);

    // Unsync allows independent passenger temperature
    climate.setSyncActive(false);
    climate.setPassengerTemperature(20.5f);
    EXPECT_FLOAT_EQ(climate.getTargetTemperature(), 23.0f);
    EXPECT_FLOAT_EQ(climate.getPassengerTemperature(), 20.5f);

    // Re-enabling sync snaps passenger temperature back to driver target
    climate.setSyncActive(true);
    EXPECT_FLOAT_EQ(climate.getPassengerTemperature(), 23.0f);

    // 3-Stage Heated Seats cycling (0 -> 1 -> 2 -> 3 -> 0)
    EXPECT_EQ(climate.getDriverSeatHeat(), 0);
    climate.cycleDriverSeatHeat();
    EXPECT_EQ(climate.getDriverSeatHeat(), 1);
    climate.cycleDriverSeatHeat();
    EXPECT_EQ(climate.getDriverSeatHeat(), 2);
    climate.cycleDriverSeatHeat();
    EXPECT_EQ(climate.getDriverSeatHeat(), 3);
    climate.cycleDriverSeatHeat();
    EXPECT_EQ(climate.getDriverSeatHeat(), 0);

    // Defrost & Recirculation
    climate.setFrontDefrost(true);
    EXPECT_TRUE(climate.isFrontDefrost());
    climate.setRearDefrost(true);
    EXPECT_TRUE(climate.isRearDefrost());
    climate.setRecirculation(true);
    EXPECT_TRUE(climate.isRecirculation());

    // Multi-observer callbacks
    int observerCalls = 0;
    climate.registerStateCallback([&observerCalls]() {
        observerCalls++;
    });
    climate.setTargetTemperature(22.5f);
    EXPECT_GT(observerCalls, 0);
}

TEST(ArchitectureFoundationTest, MediaServiceControls) {
    SafetyPolicy safety;
    MediaService media(&safety);

    EXPECT_EQ(media.getPlaybackState(), PlaybackState::PLAYING);
    media.togglePlayPause();
    EXPECT_EQ(media.getPlaybackState(), PlaybackState::PAUSED);
    media.togglePlayPause();
    EXPECT_EQ(media.getPlaybackState(), PlaybackState::PLAYING);

    // Volume clamping (0 to 100)
    media.setVolume(150);
    EXPECT_EQ(media.getVolume(), 100);

    media.setVolume(-10);
    EXPECT_EQ(media.getVolume(), 0);

    media.setVolume(50);
    EXPECT_EQ(media.getVolume(), 50);
}

TEST(ArchitectureFoundationTest, MediaServiceQueueAndSources) {
    SafetyPolicy safety;
    MediaService media(&safety);

    // Verify initial playlist queue has multiple tracks
    const auto& playlist = media.getPlaylist();
    EXPECT_GT(playlist.size(), 3);
    EXPECT_EQ(media.getCurrentTrackIndex(), 0);
    EXPECT_EQ(media.getCurrentTrack().title, "Midnight Drive");

    // Next track advances
    media.nextTrack();
    EXPECT_EQ(media.getCurrentTrackIndex(), 1);
    EXPECT_EQ(media.getCurrentTrack().title, "Cyberpunk Horizon");

    // Direct jump by index
    media.playTrackAtIndex(3);
    EXPECT_EQ(media.getCurrentTrackIndex(), 3);
    EXPECT_EQ(media.getCurrentTrack().title, "Solar Drift");

    // Audio source switching
    media.setAudioSource("USB Storage");
    EXPECT_EQ(media.getAudioSource(), "USB Storage");

    // Empty state handling
    EXPECT_TRUE(media.hasMedia());
    media.setEmptyState(true);
    EXPECT_FALSE(media.hasMedia());
    EXPECT_EQ(media.getPlaybackState(), PlaybackState::STOPPED);

    // Restoring from empty state
    media.setEmptyState(false);
    EXPECT_TRUE(media.hasMedia());
    EXPECT_EQ(media.getPlaybackState(), PlaybackState::PLAYING);
}

TEST(ArchitectureFoundationTest, VehicleServiceSafetyGating) {
    MockVehicleDataInterface mockVdi;
    SafetyPolicy safety;
    VehicleService vehicle(&mockVdi, &safety);

    // Stationary / Parked: allow mode change and door locking
    mockVdi.m_state.speed = 0.0f;
    mockVdi.m_state.gear = Gear::PARK;
    EXPECT_TRUE(vehicle.setDriveMode(DriveMode::SPORT));
    EXPECT_EQ(mockVdi.m_mode, DriveMode::SPORT);

    // In motion: vehicle service rejects deep settings
    mockVdi.m_state.speed = 60.0f;
    mockVdi.m_state.gear = Gear::DRIVE;
    std::string warningMsg;
    vehicle.registerSafetyWarningCallback([&warningMsg](const std::string& reason) {
        warningMsg = reason;
    });

    EXPECT_FALSE(vehicle.setDriveMode(DriveMode::ECO));
    EXPECT_FALSE(warningMsg.empty());
}

TEST(ArchitectureFoundationTest, DiagnosticRecordModel) {
    DtcRecord record;
    record.code = "U0111";
    record.description = "Lost Communication With Battery Energy Control Module";
    record.severity = DtcSeverity::CRITICAL;
    record.status = DtcStatus::ACTIVE;

    EXPECT_EQ(record.code, "U0111");
    EXPECT_EQ(record.severity, DtcSeverity::CRITICAL);
    EXPECT_EQ(record.status, DtcStatus::ACTIVE);
}

TEST(ArchitectureFoundationTest, VehicleStatesAndDoorSimulation) {
    MockVehicleDataInterface mockVdi;
    SafetyPolicy safety;
    VehicleService vehicle(&mockVdi, &safety);

    // Verify Reverse state triggers motion safety restriction
    mockVdi.m_state.operationalState = OperationalState::REVERSE;
    mockVdi.m_state.gear = Gear::REVERSE;
    mockVdi.m_state.speed = 3.5f;
    EXPECT_TRUE(SafetyPolicy::isInMotion(mockVdi.m_state));

    auto evalDeep = safety.evaluateInteraction(InteractionCategory::DEEP_SETTINGS, mockVdi.m_state);
    EXPECT_FALSE(evalDeep.isAllowed);
    EXPECT_FALSE(evalDeep.restrictionReason.empty());

    // Verify Driving state triggers motion safety restriction
    mockVdi.m_state.operationalState = OperationalState::DRIVING;
    mockVdi.m_state.gear = Gear::DRIVE;
    mockVdi.m_state.speed = 65.0f;
    EXPECT_TRUE(SafetyPolicy::isInMotion(mockVdi.m_state));

    // Verify Parked state allows configuration
    mockVdi.m_state.operationalState = OperationalState::PARKED;
    mockVdi.m_state.gear = Gear::PARK;
    mockVdi.m_state.speed = 0.0f;
    EXPECT_FALSE(SafetyPolicy::isInMotion(mockVdi.m_state));
    auto evalParked = safety.evaluateInteraction(InteractionCategory::DEEP_SETTINGS, mockVdi.m_state);
    EXPECT_TRUE(evalParked.isAllowed);

    // Verify Charging state
    mockVdi.m_state.operationalState = OperationalState::CHARGING;
    mockVdi.m_state.chargingState = ChargingState::CHARGING;
    EXPECT_FALSE(SafetyPolicy::isInMotion(mockVdi.m_state));

    // Verify Door closure state
    mockVdi.m_state.doors.frontLeftOpen = true;
    EXPECT_TRUE(mockVdi.m_state.doors.frontLeftOpen);
    EXPECT_FALSE(mockVdi.m_state.doors.frontRightOpen);

    // Setting door lock closes all doors
    mockVdi.setDoorLock(true);
    // VDI setDoorLock implementation in mock can verify invocation
}

TEST(ArchitectureFoundationTest, NavigationServiceOperations) {
    SafetyPolicy safety;
    NavigationService nav(&safety);

    // Verify default destination is Mysuru Palace
    const auto& destinations = nav.getDestinations();
    EXPECT_GT(destinations.size(), 4);
    EXPECT_EQ(nav.getActiveDestination().name, "Mysuru Palace");
    EXPECT_FLOAT_EQ(nav.getActiveDestination().distanceKm, 8.4f);
    EXPECT_EQ(nav.getActiveDestination().etaMinutes, 18);
    EXPECT_TRUE(nav.isNavigating());

    // Observer notifications on destination selection
    int observerCalls = 0;
    nav.registerObserver([&observerCalls]() {
        observerCalls++;
    });

    // Select second destination: Home
    nav.selectDestinationIndex(1);
    EXPECT_EQ(nav.getActiveDestinationIndex(), 1);
    EXPECT_EQ(nav.getActiveDestination().name, "Home (North District)");
    EXPECT_FLOAT_EQ(nav.getActiveDestination().distanceKm, 4.2f);
    EXPECT_GT(observerCalls, 0);

    // Select Technology University destination
    nav.selectDestinationIndex(3);
    EXPECT_EQ(nav.getActiveDestinationIndex(), 3);
    EXPECT_EQ(nav.getActiveDestination().name, "Technology University Campus");

    // Test Navigation Start, Stop, and Toggle
    nav.stopNavigation();
    EXPECT_FALSE(nav.isNavigating());

    nav.startNavigation();
    EXPECT_TRUE(nav.isNavigating());

    nav.toggleNavigation();
    EXPECT_FALSE(nav.isNavigating());

    nav.toggleNavigation();
    EXPECT_TRUE(nav.isNavigating());
}

TEST(ArchitectureFoundationTest, VehicleStateManagerLifecycleAndTransitions) {
    MockVehicleDataInterface mockVdi;
    VehicleStateManager stateManager(&mockVdi);

    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    EXPECT_EQ(stateManager.getGear(), Gear::PARK);
    EXPECT_FLOAT_EQ(stateManager.getSpeed(), 0.0f);
    EXPECT_FALSE(stateManager.isDegraded());
    EXPECT_FALSE(stateManager.hasFault());

    // Transition to DRIVING
    EXPECT_TRUE(stateManager.setOperationalState(OperationalState::DRIVING));
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::DRIVING);
    EXPECT_EQ(stateManager.getGear(), Gear::DRIVE);
    EXPECT_GT(stateManager.getSpeed(), 0.0f);

    // Transition to REVERSE
    EXPECT_TRUE(stateManager.setOperationalState(OperationalState::REVERSE));
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::REVERSE);
    EXPECT_EQ(stateManager.getGear(), Gear::REVERSE);
    EXPECT_FLOAT_EQ(stateManager.getSpeed(), 4.0f);

    // Transition to CHARGING
    EXPECT_TRUE(stateManager.setOperationalState(OperationalState::CHARGING));
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::CHARGING);
    EXPECT_EQ(stateManager.getGear(), Gear::PARK);
    EXPECT_FLOAT_EQ(stateManager.getSpeed(), 0.0f);
    EXPECT_EQ(stateManager.getVehicleState().chargingState, ChargingState::CHARGING);

    // Transition back to PARKED
    EXPECT_TRUE(stateManager.setOperationalState(OperationalState::PARKED));
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    EXPECT_EQ(stateManager.getGear(), Gear::PARK);
    EXPECT_EQ(stateManager.getVehicleState().chargingState, ChargingState::DISCONNECTED);
}

TEST(ArchitectureFoundationTest, VehicleStateManagerMultiObserver) {
    MockVehicleDataInterface mockVdi;
    VehicleStateManager stateManager(&mockVdi);

    int observer1Count = 0;
    int observer2Count = 0;
    OperationalState lastObservedState = OperationalState::PARKED;

    stateManager.registerStateCallback([&observer1Count](const VehicleState&) {
        observer1Count++;
    });

    stateManager.registerStateCallback([&observer2Count](const VehicleState&) {
        observer2Count++;
    });

    stateManager.registerOperationalStateCallback([&lastObservedState](OperationalState st) {
        lastObservedState = st;
    });

    // Dispatch state change
    stateManager.setOperationalState(OperationalState::DRIVING);
    EXPECT_EQ(observer1Count, 1);
    EXPECT_EQ(observer2Count, 1);
    EXPECT_EQ(lastObservedState, OperationalState::DRIVING);

    // Dispatch drive mode
    stateManager.setDriveMode(DriveMode::SPORT);
    EXPECT_EQ(observer1Count, 2);
    EXPECT_EQ(observer2Count, 2);
    EXPECT_EQ(stateManager.getDriveMode(), DriveMode::SPORT);
}

TEST(ArchitectureFoundationTest, VehicleStateManagerDegradedAndFaultHandling) {
    MockVehicleDataInterface mockVdi;
    VehicleStateManager stateManager(&mockVdi);

    EXPECT_FALSE(stateManager.isDegraded());
    EXPECT_FALSE(stateManager.hasFault());
    EXPECT_EQ(stateManager.getCommunicationHealth(), CommunicationHealth::HEALTHY);

    // Health drops to DEGRADED
    int healthObserverCalls = 0;
    stateManager.registerHealthCallback([&healthObserverCalls](CommunicationHealth) {
        healthObserverCalls++;
    });

    stateManager.setCommunicationHealth(CommunicationHealth::DEGRADED);
    EXPECT_TRUE(stateManager.isDegraded());
    EXPECT_FALSE(stateManager.hasFault());
    EXPECT_EQ(healthObserverCalls, 1);

    // Health drops to DISCONNECTED (simulating bus loss)
    stateManager.setCommunicationHealth(CommunicationHealth::DISCONNECTED);
    EXPECT_TRUE(stateManager.isDegraded());
    EXPECT_EQ(stateManager.getCommunicationHealth(), CommunicationHealth::DISCONNECTED);

    // Controller enters BUS_OFF
    stateManager.setCommunicationHealth(CommunicationHealth::BUS_OFF);
    EXPECT_TRUE(stateManager.isDegraded());
    EXPECT_TRUE(stateManager.hasFault());
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::FAULT);

    // Fault record injection
    FaultRecord fault;
    fault.type = FaultType::COMMUNICATION_TIMEOUT;
    fault.subsystem = "BMS";
    fault.description = "Battery Energy Control Module degraded";

    bool faultCallbackReceived = false;
    stateManager.registerFaultCallback([&faultCallbackReceived](const FaultRecord& f) {
        faultCallbackReceived = (f.type == FaultType::COMMUNICATION_TIMEOUT);
    });

    stateManager.injectFault(fault);
    EXPECT_TRUE(faultCallbackReceived);
    EXPECT_TRUE(stateManager.hasFault());
}

TEST(ArchitectureFoundationTest, SharedStateClimateSingleSourceOfTruth) {
    MockVehicleDataInterface mockVdi;
    SafetyPolicy safety;
    ClimateService climateService(&mockVdi, &safety);

    // Simulate Home summary observer and Climate detail screen observer
    float homeObservedTargetTemp = 0.0f;
    float climateObservedTargetTemp = 0.0f;
    bool homeObservedAc = false;
    bool climateObservedAc = false;

    climateService.registerClimateCallback([&](float, float target, int, bool ac) {
        homeObservedTargetTemp = target;
        homeObservedAc = ac;
    });

    climateService.registerClimateCallback([&](float, float target, int, bool ac) {
        climateObservedTargetTemp = target;
        climateObservedAc = ac;
    });

    // Action originating from Home shortcut: adjust temperature
    climateService.setTargetTemperature(23.5f);
    EXPECT_FLOAT_EQ(homeObservedTargetTemp, 23.5f);
    EXPECT_FLOAT_EQ(climateObservedTargetTemp, 23.5f);
    EXPECT_FLOAT_EQ(climateService.getTargetTemperature(), 23.5f);

    // Action originating from Climate detail screen: toggle AC
    climateService.setACActive(false);
    EXPECT_FALSE(homeObservedAc);
    EXPECT_FALSE(climateObservedAc);
    EXPECT_FALSE(climateService.isACActive());
}

TEST(ArchitectureFoundationTest, SharedStateMediaSingleSourceOfTruth) {
    SafetyPolicy safety;
    MediaService mediaService(&safety);

    // Simulate Home Now Playing observer and Media screen observer
    std::string homeTrackTitle;
    std::string mediaScreenTrackTitle;
    PlaybackState homePlayback = PlaybackState::STOPPED;
    PlaybackState mediaScreenPlayback = PlaybackState::STOPPED;

    mediaService.registerTrackCallback([&](const MediaTrack& trk) {
        homeTrackTitle = trk.title;
    });
    mediaService.registerTrackCallback([&](const MediaTrack& trk) {
        mediaScreenTrackTitle = trk.title;
    });

    mediaService.registerPlaybackCallback([&](PlaybackState st) {
        homePlayback = st;
    });
    mediaService.registerPlaybackCallback([&](PlaybackState st) {
        mediaScreenPlayback = st;
    });

    // Action originating from Home shortcut: toggle play/pause
    mediaService.togglePlayPause();
    EXPECT_EQ(homePlayback, PlaybackState::PAUSED);
    EXPECT_EQ(mediaScreenPlayback, PlaybackState::PAUSED);

    // Action originating from Media screen: next track
    mediaService.nextTrack();
    EXPECT_EQ(homeTrackTitle, "Cyberpunk Horizon");
    EXPECT_EQ(mediaScreenTrackTitle, "Cyberpunk Horizon");
    EXPECT_EQ(mediaService.getCurrentTrack().title, "Cyberpunk Horizon");
}

TEST(VehicleSimulatorTest, DeterministicNaturalSpeedSlew) {
    SimulatedVehicleBackend sim;
    EXPECT_FLOAT_EQ(sim.getVehicleState().speed, 0.0f);
    EXPECT_EQ(sim.getVehicleState().operationalState, OperationalState::PARKED);
    EXPECT_EQ(sim.getVehicleState().gear, Gear::PARK);

    // Switch scenario to DRIVING (target 64 km/h)
    sim.setScenario(SimulationScenario::DRIVING);

    // 1st second: speed increases by ~18 km/h (0 -> 18)
    sim.stepSimulation(1.0f);
    EXPECT_NEAR(sim.getVehicleState().speed, 18.0f, 0.5f);
    EXPECT_EQ(sim.getVehicleState().operationalState, OperationalState::DRIVING);
    EXPECT_EQ(sim.getVehicleState().gear, Gear::DRIVE);

    // 2nd second: speed increases to ~36 km/h
    sim.stepSimulation(1.0f);
    EXPECT_NEAR(sim.getVehicleState().speed, 36.0f, 0.5f);

    // 3rd second: speed increases to ~54 km/h
    sim.stepSimulation(1.0f);
    EXPECT_NEAR(sim.getVehicleState().speed, 54.0f, 0.5f);

    // 4th second: reaches cruise speed target (64 km/h)
    sim.stepSimulation(1.0f);
    EXPECT_FLOAT_EQ(sim.getVehicleState().speed, 64.0f);

    // Switch scenario to PARKED (target 0 km/h)
    sim.setScenario(SimulationScenario::PARKED);

    // Braking deceleration (28 km/h/s)
    sim.stepSimulation(1.0f);
    EXPECT_NEAR(sim.getVehicleState().speed, 36.0f, 0.5f);

    sim.stepSimulation(1.5f);
    EXPECT_FLOAT_EQ(sim.getVehicleState().speed, 0.0f);
    EXPECT_EQ(sim.getVehicleState().operationalState, OperationalState::PARKED);
    EXPECT_EQ(sim.getVehicleState().gear, Gear::PARK);
}

TEST(VehicleSimulatorTest, DeterministicNaturalCabinTemperatureSlew) {
    SimulatedVehicleBackend sim;
    const float initialTemp = sim.getVehicleState().cabinTemperature;
    EXPECT_FLOAT_EQ(initialTemp, 21.5f);

    // Set warmer target temperature (24.0°C) with active AC and fan speed 3
    sim.setTargetTemperature(24.0f);
    sim.setFanSpeed(3);
    sim.setACActive(true);

    // Step 1.0 second: moves gradually (e.g. +0.10°C) without unrealistic rapid jumps
    sim.stepSimulation(1.0f);
    const float after1s = sim.getVehicleState().cabinTemperature;
    EXPECT_GT(after1s, initialTemp);
    EXPECT_LT(after1s, initialTemp + 0.25f); // gradual change

    // Step 10.0 seconds: continues smooth approach toward 24.0°C
    sim.stepSimulation(10.0f);
    const float after11s = sim.getVehicleState().cabinTemperature;
    EXPECT_GT(after11s, after1s);
    EXPECT_LE(after11s, 24.0f);
}

TEST(VehicleSimulatorTest, DemoScenariosSwitching) {
    SimulatedVehicleBackend sim;

    // Scenario 1: PARKED
    sim.setScenario(SimulationScenario::PARKED);
    EXPECT_EQ(sim.getScenario(), SimulationScenario::PARKED);
    EXPECT_EQ(sim.getVehicleState().operationalState, OperationalState::PARKED);
    EXPECT_EQ(sim.getVehicleState().gear, Gear::PARK);

    // Scenario 2: DRIVING
    sim.setScenario("DRIVING");
    EXPECT_EQ(sim.getScenario(), SimulationScenario::DRIVING);
    EXPECT_EQ(sim.getVehicleState().operationalState, OperationalState::DRIVING);
    EXPECT_EQ(sim.getVehicleState().gear, Gear::DRIVE);
    EXPECT_FALSE(sim.getVehicleState().doors.frontLeftOpen);

    // Scenario 3: REVERSE
    sim.setScenario("REVERSE");
    EXPECT_EQ(sim.getScenario(), SimulationScenario::REVERSE);
    EXPECT_EQ(sim.getVehicleState().gear, Gear::REVERSE);
    EXPECT_FLOAT_EQ(sim.getVehicleState().speed, 4.0f);

    // Scenario 4: CHARGING
    sim.setScenario("CHARGING");
    EXPECT_EQ(sim.getScenario(), SimulationScenario::CHARGING);
    EXPECT_EQ(sim.getVehicleState().operationalState, OperationalState::CHARGING);
    EXPECT_EQ(sim.getVehicleState().chargingState, ChargingState::CHARGING);
    EXPECT_FLOAT_EQ(sim.getVehicleState().speed, 0.0f);

    // Step charging: verify SOC increases
    const float socBefore = sim.getVehicleState().batterySoc;
    sim.stepSimulation(10.0f);
    EXPECT_GT(sim.getVehicleState().batterySoc, socBefore);
    EXPECT_FLOAT_EQ(sim.getVehicleState().rangeKm, sim.getVehicleState().batterySoc * 5.0f);

    // Scenario 5: FAULT
    sim.setScenario("FAULT");
    EXPECT_EQ(sim.getScenario(), SimulationScenario::FAULT);
    EXPECT_EQ(sim.getVehicleState().operationalState, OperationalState::FAULT);
    EXPECT_FLOAT_EQ(sim.getVehicleState().speed, 0.0f);
}

TEST(VehicleSimulatorTest, ControlledFaultSimulationModes) {
    SimulatedVehicleBackend sim;

    // Default mode: NONE
    EXPECT_EQ(sim.getFaultMode(), FaultSimulationMode::NONE);
    EXPECT_EQ(sim.getCommunicationHealth(), CommunicationHealth::HEALTHY);

    // Mode 1: UNAVAILABLE_DATA
    sim.setFaultMode(FaultSimulationMode::UNAVAILABLE_DATA);
    EXPECT_EQ(sim.getFaultMode(), FaultSimulationMode::UNAVAILABLE_DATA);
    EXPECT_EQ(sim.getCommunicationHealth(), CommunicationHealth::DISCONNECTED);

    // Mode 2: STALE_DATA
    sim.setFaultMode("STALE");
    EXPECT_EQ(sim.getFaultMode(), FaultSimulationMode::STALE_DATA);
    EXPECT_EQ(sim.getCommunicationHealth(), CommunicationHealth::DEGRADED);

    const uint64_t timestampBefore = sim.getVehicleState().timestampMs;
    sim.stepSimulation(2.0f);
    EXPECT_EQ(sim.getVehicleState().timestampMs, timestampBefore); // frozen

    // Mode 3: INVALID_DATA
    bool faultReported = false;
    sim.registerFaultCallback([&faultReported](const FaultRecord& f) {
        faultReported = (f.type == FaultType::INVALID_RANGE);
    });

    sim.setFaultMode("INVALID");
    EXPECT_EQ(sim.getFaultMode(), FaultSimulationMode::INVALID_DATA);
    EXPECT_EQ(sim.getCommunicationHealth(), CommunicationHealth::DEGRADED);
    EXPECT_TRUE(faultReported);
    EXPECT_GT(sim.getVehicleState().speed, 250.0f); // out-of-range sensor reading

    // Restore to healthy
    sim.clearFaults();
    EXPECT_EQ(sim.getFaultMode(), FaultSimulationMode::NONE);
    EXPECT_EQ(sim.getCommunicationHealth(), CommunicationHealth::HEALTHY);
}

TEST(VehicleSimulatorTest, VehicleStateManagerIntegration) {
    SimulatedVehicleBackend sim;
    VehicleStateManager stateManager(&sim);
    SafetyPolicy safety;
    VehicleService vehicleService(&sim, &safety, &stateManager);

    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    EXPECT_FALSE(safety.isInMotion(stateManager.getVehicleState()));

    // Trigger DRIVING scenario via Service
    vehicleService.setScenario("DRIVING");

    // Advance simulation by 2 seconds
    sim.stepSimulation(2.0f);

    // Verify propagation through VehicleStateManager
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::DRIVING);
    EXPECT_EQ(stateManager.getGear(), Gear::DRIVE);
    EXPECT_GT(stateManager.getSpeed(), 20.0f);
    EXPECT_TRUE(safety.isInMotion(stateManager.getVehicleState()));

    // Verify SafetyPolicy restricts deep settings when simulator is in motion
    auto eval = safety.evaluateInteraction(InteractionCategory::DEEP_SETTINGS, stateManager.getVehicleState());
    EXPECT_FALSE(eval.isAllowed);
    EXPECT_FALSE(eval.restrictionReason.empty());
}

TEST(SafetyAwareUXTest, SafetyPolicyDirectMethods) {
    SimulatedVehicleBackend sim;
    VehicleStateManager stateManager(&sim);
    SafetyPolicy safety(&stateManager);

    // Initial state: PARKED (stationary)
    EXPECT_TRUE(safety.isVehicleConfigurationAllowed());
    EXPECT_TRUE(safety.isEssentialClimateControlAllowed());
    EXPECT_TRUE(safety.isMediaControlAllowed());
    EXPECT_TRUE(safety.isNavigationInteractionAllowed());

    // Switch scenario to DRIVING
    sim.setScenario(SimulationScenario::DRIVING);
    sim.stepSimulation(2.0f); // speed ramps up to ~36 km/h

    // In motion: vehicle configuration is restricted, essential climate/media/nav remain allowed
    EXPECT_FALSE(safety.isVehicleConfigurationAllowed());
    EXPECT_TRUE(safety.isEssentialClimateControlAllowed());
    EXPECT_TRUE(safety.isMediaControlAllowed());
    EXPECT_TRUE(safety.isNavigationInteractionAllowed());

    // Check standard restriction constants
    EXPECT_EQ(std::string(SafetyPolicy::RESTRICTION_MESSAGE), std::string("Unavailable while driving"));
    EXPECT_EQ(std::string(SafetyPolicy::RESTRICTION_ICON), std::string("🔒"));
    EXPECT_EQ(safety.getRestrictionReason(), "Unavailable while driving");
    EXPECT_EQ(safety.getRestrictionIcon(), "🔒");

    // Also test explicit state parameter overload
    VehicleState stationaryState{};
    stationaryState.speed = 0.0f;
    stationaryState.operationalState = OperationalState::PARKED;
    EXPECT_TRUE(safety.isVehicleConfigurationAllowed(stationaryState));

    VehicleState movingState{};
    movingState.speed = 45.0f;
    movingState.operationalState = OperationalState::DRIVING;
    EXPECT_FALSE(safety.isVehicleConfigurationAllowed(movingState));
    EXPECT_TRUE(safety.isEssentialClimateControlAllowed(movingState));
    EXPECT_TRUE(safety.isMediaControlAllowed(movingState));
    EXPECT_TRUE(safety.isNavigationInteractionAllowed(movingState));
}

TEST(SafetyAwareUXTest, TransitionParkedToDriving) {
    SimulatedVehicleBackend sim;
    VehicleStateManager stateManager(&sim);
    SafetyPolicy safety(&stateManager);

    // Phase 1: PARKED
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    EXPECT_FLOAT_EQ(stateManager.getSpeed(), 0.0f);
    EXPECT_FALSE(safety.isInMotion(stateManager.getVehicleState()));
    EXPECT_TRUE(safety.isVehicleConfigurationAllowed());

    // Phase 2: Transition to DRIVING
    sim.setScenario(SimulationScenario::DRIVING);
    sim.stepSimulation(1.0f);

    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::DRIVING);
    EXPECT_GT(stateManager.getSpeed(), 0.5f);
    EXPECT_TRUE(safety.isInMotion(stateManager.getVehicleState()));

    // Verify allowed vs restricted policy
    EXPECT_FALSE(safety.isVehicleConfigurationAllowed());
    EXPECT_TRUE(safety.isEssentialClimateControlAllowed());
    EXPECT_TRUE(safety.isMediaControlAllowed());
    EXPECT_TRUE(safety.isNavigationInteractionAllowed());

    // Verify interaction evaluation provides UX notice
    auto eval = safety.evaluateInteraction(InteractionCategory::DEEP_SETTINGS, stateManager.getVehicleState());
    EXPECT_FALSE(eval.isAllowed);
    EXPECT_EQ(eval.restrictionReason, "Unavailable while driving");
}

TEST(SafetyAwareUXTest, TransitionDrivingToParked) {
    SimulatedVehicleBackend sim;
    VehicleStateManager stateManager(&sim);
    SafetyPolicy safety(&stateManager);

    // Start in DRIVING scenario
    sim.setScenario(SimulationScenario::DRIVING);
    sim.stepSimulation(4.0f); // Cruising at 64 km/h
    EXPECT_FLOAT_EQ(stateManager.getSpeed(), 64.0f);
    EXPECT_FALSE(safety.isVehicleConfigurationAllowed());

    // Transition DRIVING -> PARKED
    sim.setScenario(SimulationScenario::PARKED);
    sim.stepSimulation(3.0f); // Decelerates to 0 km/h and parks

    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    EXPECT_FLOAT_EQ(stateManager.getSpeed(), 0.0f);
    EXPECT_FALSE(safety.isInMotion(stateManager.getVehicleState()));

    // Once parked, configuration is immediately restored
    EXPECT_TRUE(safety.isVehicleConfigurationAllowed());
}

TEST(SafetyAwareUXTest, TransitionParkedToCharging) {
    SimulatedVehicleBackend sim;
    VehicleStateManager stateManager(&sim);
    SafetyPolicy safety(&stateManager);

    // Start in PARKED
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);

    // Transition PARKED -> CHARGING
    sim.setScenario(SimulationScenario::CHARGING);
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::CHARGING);
    EXPECT_EQ(stateManager.getVehicleState().chargingState, ChargingState::CHARGING);
    EXPECT_FLOAT_EQ(stateManager.getSpeed(), 0.0f);

    // Vehicle is stationary while charging, climate and vehicle config permitted
    EXPECT_FALSE(safety.isInMotion(stateManager.getVehicleState()));
    EXPECT_TRUE(safety.isEssentialClimateControlAllowed());
    EXPECT_TRUE(safety.isVehicleConfigurationAllowed());
}

TEST(SafetyAwareUXTest, TransitionAnyStateToFault) {
    SimulatedVehicleBackend sim;
    VehicleStateManager stateManager(&sim);
    SafetyPolicy safety(&stateManager);

    // 1. PARKED -> FAULT
    sim.setScenario(SimulationScenario::PARKED);
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::PARKED);
    sim.setScenario(SimulationScenario::FAULT);
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::FAULT);
    EXPECT_TRUE(stateManager.hasFault());

    // 2. DRIVING -> FAULT
    sim.setScenario(SimulationScenario::DRIVING);
    sim.stepSimulation(2.0f);
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::DRIVING);
    sim.setScenario(SimulationScenario::FAULT);
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::FAULT);
    EXPECT_TRUE(stateManager.hasFault());
    EXPECT_FLOAT_EQ(stateManager.getSpeed(), 0.0f); // Fail-safe stopped
    EXPECT_FALSE(safety.isVehicleConfigurationAllowed()); // Configuration locked out on system fault

    // 3. CHARGING -> FAULT
    sim.setScenario(SimulationScenario::CHARGING);
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::CHARGING);
    sim.setScenario(SimulationScenario::FAULT);
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::FAULT);
    EXPECT_TRUE(stateManager.hasFault());
}

TEST(SafetyAwareUXTest, FaultStateTelemetryAndResponsiveness) {
    SimulatedVehicleBackend sim;
    VehicleStateManager stateManager(&sim);
    SafetyPolicy safety(&stateManager);
    VehicleService vehicleService(&sim, &safety, &stateManager);

    // Verify healthy state formatting
    EXPECT_EQ(vehicleService.getCommunicationHealth(), CommunicationHealth::HEALTHY);

    // Inject DISCONNECTED / UNAVAILABLE_DATA fault
    sim.setFaultMode(FaultSimulationMode::UNAVAILABLE_DATA);
    EXPECT_EQ(vehicleService.getCommunicationHealth(), CommunicationHealth::DISCONNECTED);

    // Verify UI responsiveness: service calls remain completely non-blocking and safe
    EXPECT_NO_THROW((void)vehicleService.getVehicleState());
    EXPECT_NO_THROW((void)safety.isVehicleConfigurationAllowed());
    EXPECT_NO_THROW((void)safety.isEssentialClimateControlAllowed());

    // Test INVALID_DATA mode: sensor out of range triggers fault transition and safe stop
    sim.setFaultMode(FaultSimulationMode::INVALID_DATA);
    EXPECT_EQ(vehicleService.getCommunicationHealth(), CommunicationHealth::DEGRADED);
    EXPECT_TRUE(stateManager.hasFault());
    EXPECT_EQ(stateManager.getOperationalState(), OperationalState::FAULT);
    EXPECT_FLOAT_EQ(vehicleService.getVehicleState().speed, 0.0f); // fail-safe safe-stop

    // Clear faults and verify full recovery
    sim.clearFaults();
    EXPECT_EQ(vehicleService.getCommunicationHealth(), CommunicationHealth::HEALTHY);
    EXPECT_FALSE(stateManager.hasFault());
}
