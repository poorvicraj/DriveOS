#include <gtest/gtest.h>
#include "can/CanTypes.hpp"
#include "can/CanFrameCodec.hpp"
#include "can/MockCanTransport.hpp"
#include "can/SocketCanTransport.hpp"
#include "vehicle/CANVehicleBackend.hpp"
#include <cmath>
#include <atomic>
#include <chrono>
#include <thread>

using namespace driveos;
using namespace driveos::can;
using namespace driveos::domain;
using namespace driveos::vehicle;

TEST(CanCodecTest, EncodeAndDecodePowertrainStatus) {
    CanFrameCodec codec;
    VehicleState state{};

    // Encode known kinematics: Speed=88.5 km/h, Mode=SPORT, Gear=DRIVE
    CanFrame frame = codec.encodePowertrainStatus(88.5f, DriveMode::SPORT, Gear::DRIVE);
    EXPECT_EQ(frame.canId, CanId::POWERTRAIN_STATUS);
    EXPECT_EQ(frame.dlc, 8);

    // Verify raw bit representation: 88.5 / 0.1 = 885 = 0x0375
    // Byte 0 = 0x75 (117), Byte 1 = 0x03 (3)
    // Mode SPORT (2), Gear DRIVE (3) -> byte 2: (3 << 2) | 2 = 14 = 0x0E
    EXPECT_EQ(frame.data[0], 0x75);
    EXPECT_EQ(frame.data[1], 0x03);
    EXPECT_EQ(frame.data[2], 0x0E);

    // Decode frame into clean vehicle state
    auto res = codec.decodeFrame(frame, state);
    EXPECT_TRUE(res.success);
    EXPECT_NEAR(state.speed, 88.5f, 0.05f);
    EXPECT_EQ(state.driveMode, DriveMode::SPORT);
    EXPECT_EQ(state.gear, Gear::DRIVE);
}

TEST(CanCodecTest, EncodeAndDecodeBatteryStatus) {
    CanFrameCodec codec;
    VehicleState state{};

    // SOC=84.5%, Range=420 km, Charging=CHARGING, BatteryTemp=27.0 °C
    CanFrame frame = codec.encodeBatteryStatus(84.5f, 420.0f, ChargingState::CHARGING, 27.0f);
    EXPECT_EQ(frame.canId, CanId::BATTERY_STATUS);
    EXPECT_EQ(frame.dlc, 8);

    // Raw SOC: 84.5 / 0.5 = 169
    EXPECT_EQ(frame.data[0], 169);
    // Raw Range: 420 = 0x01A4 -> byte 1: 0xA4, byte 2: 0x01
    EXPECT_EQ(frame.data[1], 0xA4);
    EXPECT_EQ(frame.data[2], 0x01);
    // ChargingState = CHARGING (2)
    EXPECT_EQ(frame.data[3], 2);
    // Battery Temp: 27.0 - (-40.0) = 67
    EXPECT_EQ(frame.data[4], 67);

    auto res = codec.decodeFrame(frame, state);
    EXPECT_TRUE(res.success);
    EXPECT_NEAR(state.batterySoc, 84.5f, 0.25f);
    EXPECT_FLOAT_EQ(state.rangeKm, 420.0f);
    EXPECT_EQ(state.chargingState, ChargingState::CHARGING);
    EXPECT_FLOAT_EQ(state.batteryTemperature, 27.0f);
}

TEST(CanCodecTest, EncodeAndDecodeClimateStatus) {
    CanFrameCodec codec;
    VehicleState state{};

    // Cabin=22.5 °C, Outside=18.0 °C, AC=true, Fan=3, Target=21.5 °C
    CanFrame frame = codec.encodeClimateStatus(22.5f, 18.0f, true, 3, 21.5f);
    EXPECT_EQ(frame.canId, CanId::CLIMATE_STATUS);
    EXPECT_EQ(frame.dlc, 8);

    // Raw Cabin: (22.5 - (-20)) / 0.5 = 85
    EXPECT_EQ(frame.data[0], 85);
    // Raw Outside: (18.0 - (-40)) / 0.5 = 116
    EXPECT_EQ(frame.data[1], 116);
    // AC (1) | Fan 3 (0b011 << 1) = 1 | 6 = 7
    EXPECT_EQ(frame.data[2], 7);
    // Raw Target: 21.5 / 0.5 = 43
    EXPECT_EQ(frame.data[3], 43);

    auto res = codec.decodeFrame(frame, state);
    EXPECT_TRUE(res.success);
    EXPECT_FLOAT_EQ(state.cabinTemperature, 22.5f);
    EXPECT_FLOAT_EQ(state.outsideTemperature, 18.0f);
    EXPECT_TRUE(state.acActive);
    EXPECT_EQ(state.fanSpeed, 3);
    EXPECT_FLOAT_EQ(state.targetTemperature, 21.5f);
}

TEST(CanCodecTest, EncodeAndDecodeClimateCommand) {
    CanFrameCodec codec;

    CanFrame frame = codec.encodeClimateCommand(true, 4, 23.0f);
    EXPECT_EQ(frame.canId, CanId::CLIMATE_COMMAND);
    EXPECT_EQ(frame.dlc, 8);

    // Byte 0: AC (1) | (4 << 1) = 1 | 8 = 9
    EXPECT_EQ(frame.data[0], 9);
    // Byte 1: 23.0 / 0.5 = 46
    EXPECT_EQ(frame.data[1], 46);
}

TEST(CanCodecTest, EncodeAndDecodeVehicleCommand) {
    CanFrameCodec codec;

    CanFrame frame = codec.encodeVehicleCommand(DriveMode::SPORT, true);
    EXPECT_EQ(frame.canId, CanId::VEHICLE_COMMAND);
    EXPECT_EQ(frame.dlc, 8);

    // Byte 0: Mode SPORT (2) | (Lock 1 << 2) = 2 | 4 = 6
    EXPECT_EQ(frame.data[0], 6);
}

TEST(CanCodecTest, EncodeAndDecodeBodyAndConfigStatus) {
    CanFrameCodec codec;
    VehicleState state{};

    DoorState doors{};
    doors.frontLeftOpen = true;
    doors.rearRightOpen = true;

    CanFrame bodyFrame = codec.encodeBodyStatus(doors, true, 2);
    EXPECT_EQ(bodyFrame.canId, CanId::BODY_STATUS);
    // Byte 0: FL (1) | RR (8) | Lock (16) | (2 << 5) = 1 + 8 + 16 + 64 = 89
    EXPECT_EQ(bodyFrame.data[0], 89);

    auto resBody = codec.decodeFrame(bodyFrame, state);
    EXPECT_TRUE(resBody.success);
    EXPECT_TRUE(state.doors.frontLeftOpen);
    EXPECT_FALSE(state.doors.frontRightOpen);
    EXPECT_FALSE(state.doors.rearLeftOpen);
    EXPECT_TRUE(state.doors.rearRightOpen);

    CanFrame cfgFrame = codec.encodeVehicleConfig(IgnitionState::ON, OperationalState::DRIVING);
    EXPECT_EQ(cfgFrame.canId, CanId::VEHICLE_CONFIG);
    // Byte 0: Ignition ON (2) | (DRIVING 1 << 2) = 2 | 4 = 6
    EXPECT_EQ(cfgFrame.data[0], 6);

    auto resCfg = codec.decodeFrame(cfgFrame, state);
    EXPECT_TRUE(resCfg.success);
    EXPECT_EQ(state.ignitionState, IgnitionState::ON);
    EXPECT_EQ(state.operationalState, OperationalState::DRIVING);
}

TEST(CanCodecTest, RejectMalformedDlc) {
    CanFrameCodec codec;
    VehicleState state{};

    CanFrame truncatedFrame{};
    truncatedFrame.canId = CanId::POWERTRAIN_STATUS;
    truncatedFrame.dlc = 4; // Corrupted DLC < 8

    auto res = codec.decodeFrame(truncatedFrame, state);
    EXPECT_FALSE(res.success);
    EXPECT_FALSE(res.errorMessage.empty());
}

TEST(CanCodecTest, RejectOutOfRangeSignalValues) {
    CanFrameCodec codec;
    VehicleState state{};

    // 1. Speed exceeding physical limit (> 250 km/h)
    CanFrame badSpeedFrame{};
    badSpeedFrame.canId = CanId::POWERTRAIN_STATUS;
    badSpeedFrame.dlc = 8;
    // 300.0 km/h = 3000 = 0x0BB8
    badSpeedFrame.data[0] = 0xB8;
    badSpeedFrame.data[1] = 0x0B;
    badSpeedFrame.data[2] = 0x01; // NORMAL, PARK

    auto resSpeed = codec.decodeFrame(badSpeedFrame, state);
    EXPECT_FALSE(resSpeed.success);
    EXPECT_FALSE(resSpeed.errorMessage.empty());

    // 2. Battery SOC exceeding physical limit (> 100%)
    CanFrame badSocFrame{};
    badSocFrame.canId = CanId::BATTERY_STATUS;
    badSocFrame.dlc = 8;
    badSocFrame.data[0] = 220; // 220 * 0.5 = 110%

    auto resSoc = codec.decodeFrame(badSocFrame, state);
    EXPECT_FALSE(resSoc.success);
    EXPECT_FALSE(resSoc.errorMessage.empty());

    // 3. Invalid Enum value (e.g. DriveMode = 3, only 0,1,2 defined)
    CanFrame badEnumFrame{};
    badEnumFrame.canId = CanId::POWERTRAIN_STATUS;
    badEnumFrame.dlc = 8;
    badEnumFrame.data[0] = 0;
    badEnumFrame.data[1] = 0;
    badEnumFrame.data[2] = 0x03; // DriveMode = 3 (out of range)

    auto resEnum = codec.decodeFrame(badEnumFrame, state);
    EXPECT_FALSE(resEnum.success);
}

TEST(CanBackendTest, InitialStateAndLifecycle) {
    auto mockTransport = std::make_unique<MockCanTransport>();
    MockCanTransport* transportPtr = mockTransport.get();
    CANVehicleBackend backend(std::move(mockTransport));

    // Initial state before initialize()
    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::DISCONNECTED);

    // Initialize backend
    bool ok = backend.initialize();
    EXPECT_TRUE(ok);
    EXPECT_TRUE(transportPtr->isConnected());
    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::HEALTHY);

    // Shutdown backend
    backend.shutdown();
    EXPECT_FALSE(transportPtr->isConnected());
    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::DISCONNECTED);
}

TEST(CanBackendTest, CyclicFrameReceptionAndStateDispatch) {
    auto mockTransport = std::make_unique<MockCanTransport>();
    MockCanTransport* transportPtr = mockTransport.get();
    CANVehicleBackend backend(std::move(mockTransport));
    backend.initialize();

    bool stateReceived = false;
    float receivedSpeed = 0.0f;
    backend.registerStateCallback([&](const VehicleState& st) {
        stateReceived = true;
        receivedSpeed = st.speed;
    });

    CanFrameCodec codec;
    CanFrame frame = codec.encodePowertrainStatus(65.0f, DriveMode::NORMAL, Gear::DRIVE);
    frame.timestampMs = 1000;

    // Inject frame into transport
    transportPtr->injectFrame(frame);

    EXPECT_TRUE(stateReceived);
    EXPECT_FLOAT_EQ(receivedSpeed, 65.0f);
    EXPECT_FLOAT_EQ(backend.getVehicleState().speed, 65.0f);
    EXPECT_EQ(backend.getVehicleState().driveMode, DriveMode::NORMAL);
    EXPECT_EQ(backend.getVehicleState().gear, Gear::DRIVE);
    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::HEALTHY);
}

TEST(CanBackendTest, CommunicationTimeoutDetection) {
    auto mockTransport = std::make_unique<MockCanTransport>();
    MockCanTransport* transportPtr = mockTransport.get();
    CANVehicleBackend backend(std::move(mockTransport));
    backend.initialize();
    backend.setTimeoutThresholdMs(300); // 300ms timeout threshold

    CommunicationHealth observedHealth = CommunicationHealth::HEALTHY;
    backend.registerHealthCallback([&](CommunicationHealth h) {
        observedHealth = h;
    });

    CanFrameCodec codec;
    CanFrame frame = codec.encodePowertrainStatus(50.0f, DriveMode::NORMAL, Gear::DRIVE);
    frame.timestampMs = 1000;
    transportPtr->injectFrame(frame);

    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::HEALTHY);

    // Advance time by 200ms (< 300ms threshold): should remain HEALTHY
    backend.checkTimeout(1200);
    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::HEALTHY);

    // Advance time by 400ms (> 300ms threshold from 1000ms): triggers timeout!
    backend.checkTimeout(1400);
    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::DISCONNECTED);
    EXPECT_EQ(observedHealth, CommunicationHealth::DISCONNECTED);

    // Re-inject valid frame: recovers to HEALTHY
    frame.timestampMs = 1450;
    transportPtr->injectFrame(frame);
    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::HEALTHY);
    EXPECT_EQ(observedHealth, CommunicationHealth::HEALTHY);
}

TEST(CanBackendTest, InvalidDataTriggersFaultAndDegradation) {
    auto mockTransport = std::make_unique<MockCanTransport>();
    MockCanTransport* transportPtr = mockTransport.get();
    CANVehicleBackend backend(std::move(mockTransport));
    backend.initialize();

    bool faultReported = false;
    FaultRecord observedFault{};
    backend.registerFaultCallback([&](const FaultRecord& f) {
        faultReported = true;
        observedFault = f;
    });

    // Inject corrupted frame (Speed out of range)
    CanFrame badFrame{};
    badFrame.canId = CanId::POWERTRAIN_STATUS;
    badFrame.dlc = 8;
    badFrame.data[0] = 0xB8;
    badFrame.data[1] = 0x0B; // 300 km/h

    transportPtr->injectFrame(badFrame);

    EXPECT_TRUE(faultReported);
    EXPECT_EQ(observedFault.type, FaultType::INVALID_RANGE);
    EXPECT_EQ(observedFault.subsystem, "CAN_DECODER");
    EXPECT_EQ(backend.getCommunicationHealth(), CommunicationHealth::DEGRADED);
}

TEST(CanBackendTest, ActuationCommandsTransmitExpectedFrames) {
    auto mockTransport = std::make_unique<MockCanTransport>();
    MockCanTransport* transportPtr = mockTransport.get();
    CANVehicleBackend backend(std::move(mockTransport));
    backend.initialize();

    // 1. Test setTargetTemperature command
    backend.setTargetTemperature(23.5f);
    EXPECT_GE(transportPtr->getSentFrameCount(), 1u);
    CanFrame sentClimate = transportPtr->getLastSentFrame();
    EXPECT_EQ(sentClimate.canId, CanId::CLIMATE_COMMAND);
    // 23.5 / 0.5 = 47 in byte 1
    EXPECT_EQ(sentClimate.data[1], 47);

    // 2. Test setDriveMode command
    transportPtr->clearSentFrames();
    backend.setDriveMode(DriveMode::SPORT);
    EXPECT_GE(transportPtr->getSentFrameCount(), 1u);
    CanFrame sentMode = transportPtr->getLastSentFrame();
    EXPECT_EQ(sentMode.canId, CanId::VEHICLE_COMMAND);
    EXPECT_EQ(sentMode.data[0] & 0x03, static_cast<uint8_t>(DriveMode::SPORT));

    // 3. Test setDoorLock command
    transportPtr->clearSentFrames();
    backend.setDoorLock(true);
    EXPECT_GE(transportPtr->getSentFrameCount(), 1u);
    CanFrame sentLock = transportPtr->getLastSentFrame();
    EXPECT_EQ(sentLock.canId, CanId::VEHICLE_COMMAND);
    EXPECT_EQ((sentLock.data[0] >> 2) & 0x01, 1);
}

TEST(CanTransportTest, SocketCanTransportGracefulHostFallback) {
    SocketCanTransport socketTransport("vcan0");
#if defined(__linux__)
    // On Linux without root or without vcan0 created, it may fail cleanly
    bool ok = socketTransport.open("vcan0");
    if (!ok) {
        EXPECT_FALSE(socketTransport.isConnected());
    }
#else
    // On Windows host: must return false gracefully and report disconnected
    bool ok = socketTransport.open("vcan0");
    EXPECT_FALSE(ok);
    EXPECT_FALSE(socketTransport.isConnected());
    EXPECT_FALSE(socketTransport.sendFrame(CanFrame{}));
#endif
    socketTransport.close();
}

TEST(CanTransportTest, SocketCanLiveVcan0Loopback) {
#if defined(__linux__)
    SocketCanTransport txTransport("vcan0");
    SocketCanTransport rxTransport("vcan0");
    if (txTransport.open("vcan0") && rxTransport.open("vcan0")) {
        EXPECT_TRUE(txTransport.isConnected());
        EXPECT_TRUE(rxTransport.isConnected());

        std::atomic<bool> frameReceived{false};
        CanFrame receivedFrame{};
        rxTransport.registerFrameCallback([&](const CanFrame& f) {
            receivedFrame = f;
            frameReceived = true;
        });

        CanFrame testFrame{};
        testFrame.canId = 0x123;
        testFrame.dlc = 8;
        testFrame.data[0] = 0xDE;
        testFrame.data[1] = 0xAD;
        testFrame.data[2] = 0xBE;
        testFrame.data[3] = 0xEF;

        EXPECT_TRUE(txTransport.sendFrame(testFrame));

        for (int i = 0; i < 50 && !frameReceived.load(); ++i) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }

        EXPECT_TRUE(frameReceived.load());
        EXPECT_EQ(receivedFrame.canId, 0x123u);
        EXPECT_EQ(receivedFrame.data[0], 0xDE);
        EXPECT_EQ(receivedFrame.data[1], 0xAD);

        txTransport.close();
        rxTransport.close();
    }
#endif
}
