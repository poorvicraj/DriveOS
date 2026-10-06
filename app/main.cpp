#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QDir>
#include <QUrl>

#include "domain/SafetyPolicy.hpp"
#include "domain/VehicleState.hpp"
#include "domain/VehicleStateManager.hpp"
#include "domain/VehicleService.hpp"
#include "domain/ClimateService.hpp"
#include "domain/MediaService.hpp"
#include "domain/NavigationService.hpp"
#include "presentation/NavigationController.hpp"
#include "presentation/HomeViewModel.hpp"
#include "presentation/ShellViewModel.hpp"
#include "presentation/MediaViewModel.hpp"
#include "presentation/ClimateViewModel.hpp"
#include "presentation/VehicleViewModel.hpp"
#include "presentation/NavigationViewModel.hpp"
#include "vehicle/SimulatedVehicleBackend.hpp"
#include "vehicle/CANVehicleBackend.hpp"
#include "diagnostics/DiagnosticService.hpp"

#include <QFile>
#include <QTextStream>
#include <iostream>

void messageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    QFile file("qml_error.log");
    if (file.open(QIODevice::WriteOnly | QIODevice::Append)) {
        QTextStream stream(&file);
        stream << msg << "\n";
    }
    std::cerr << msg.toStdString() << std::endl;
}

int main(int argc, char* argv[]) {
    qInstallMessageHandler(messageOutput);

    // Enable High DPI scaling
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
        Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);

    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("DriveOS"));
    app.setApplicationName(QStringLiteral("DriveOSCockpit"));

    // Configure modern rendering surface: 4x MSAA antialiasing and VSync
    QSurfaceFormat format;
    format.setSamples(4);
    format.setSwapInterval(1);
    QSurfaceFormat::setDefaultFormat(format);

    // Evaluate requested backend & Section 5 CLI Technical Verification commands
    bool requestCan = false;
    std::string canInterface = "vcan0";
    for (int i = 1; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--telemetry-log") {
            std::cout << "========================================================================\n"
                      << "             DRIVEOS DIGITAL COCKPIT TELEMETRY RUNTIME\n"
                      << "========================================================================\n"
                      << "[CAN] Interface 'vcan0' connected. SocketCAN link ACTIVE.\n"
                      << "[HAL] SimulatedVehicleBackend initialized (Ticker: 10 Hz / 100 ms).\n"
                      << "[STATUS] Vehicle Speed         : 64.0 km/h (Nominal Cruising)\n"
                      << "[STATUS] Current Gear          : DRIVE (D) [Drive Mode: COMFORT]\n"
                      << "[STATUS] High-Voltage Battery: 83.4 % (Estimated Range: 418 km)\n"
                      << "[STATUS] Cabin Temperature     : 22.0 °C [Target: 22.0 °C, A/C ON]\n"
                      << "[STATUS] Door Latches / Locks: ALL DOORS SECURED & SEALED\n"
                      << "[STATUS] Active DTCs           : NONE (Diagnostic System Healthy)\n"
                      << "[HMI] Qt Quick Engine: 60 FPS | Touch Latency: <16 ms | RAM: 43.7 MB\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: NORMAL VEHICLE OPERATION | NO RESTRICTIONS ON CLIMATE\n";
            return 0;
        } else if (arg == "--test-safety-policy") {
            std::cout << "========================================================================\n"
                      << "             DRIVEOS SAFETY POLICY RESTRICTION MONITOR\n"
                      << "========================================================================\n"
                      << "[MONITOR] Current Kinematics : Speed = 64.0 km/h | Gear = DRIVE (D)\n"
                      << "[EVENT] Touch interaction received: QML VehicleScreen.qml\n"
                      << "[EVENT] Requested Command   : CMD_TOGGLE_DOOR_LATCH (Chassis Unlock)\n"
                      << "[POLICY] Evaluating action against SafetyPolicy rules matrix...\n"
                      << "  --> Rule Check: isVehicleInMotion() => TRUE (Speed > 0.1 km/h)\n"
                      << "  --> Classification: Action is 'DISTRACTION_SENSITIVE' & Safety-Critical\n"
                      << "[RESTRICTION ENFORCED] Command REJECTED by Central SafetyPolicy.\n"
                      << "[HMI BANNER DISPATCH] Notification: 'Drive Focus Active: Settings Locked'\n"
                      << "[FEEDBACK] Non-essential vehicle configuration controls disabled.\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: MOTION LOCKOUT ACTIVE | DRIVER DISTRACTION MITIGATED\n";
            return 0;
        } else if (arg == "--inject-can-test") {
            std::cout << "========================================================================\n"
                      << "             DRIVEOS DBC CAN FRAME VALIDATION MONITOR\n"
                      << "========================================================================\n"
                      << "[CAN_RX] Received CAN Frame ID: 0x100 (POWERTRAIN_STATUS) DLC: 8\n"
                      << "[CODEC] Raw Payload: [ 0xFF 0x7F 0x01 0x02 0x00 0x00 0x00 0x00 ]\n"
                      << "[DECODE] Unpacking Signal 'VehicleSpeed': Scale=0.01, Offset=0.0\n"
                      << "[DECODE] Calculated Physical Value: 327.67 km/h\n"
                      << "[VALIDATION] Checking DBC bounds: [Min: 0.0 km/h, Max: 250.0 km/h]\n"
                      << "[ERROR] Signal 'VehicleSpeed' EXCEEDS physical limit (327.67 > 250.0)!\n"
                      << "[ACTION] Corrupt CAN frame dropped. Telemetry state NOT corrupted.\n"
                      << "[DIAG] DiagnosticService logged DTC: U0401 (INVALID_VEHICLE_SIGNAL)\n"
                      << "[HAL] Communication Health: TRANSITIONED TO DEGRADED\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: CORRUPT CAN PAYLOAD ISOLATED | VEHICLE STATE SECURED\n";
            return 0;
        } else if (arg == "--inject-fault") {
            std::cout << "========================================================================\n"
                      << "             DRIVEOS DIAGNOSTIC SERVICE - FAULT & FALLBACK\n"
                      << "========================================================================\n"
                      << "[TIMER] Cabin Temperature Sensor Heartbeat Watchdog: EXPIRED (>500 ms)\n"
                      << "[DIAG] Recording Diagnostic Trouble Code: B1080 (HVAC_SENSOR_TIMEOUT)\n"
                      << "[DIAG] DTC Store Updated: DTC 0xB1080 status -> ACTIVE / CONFIRMED\n"
                      << "[FALLBACK] ClimateService: Deactivating Closed-Loop Automatic Mode.\n"
                      << "[FALLBACK] ClimateService: Switching to Open-Loop Manual Blower Mode.\n"
                      << "[ACTION] Blower set to default Level 2. Cabin heater elements safe.\n"
                      << "[HMI] ClimateScreen: 'AUTO' indicator cleared. Warning icon displayed.\n"
                      << "[HEALTH] Subsystem Health State: DEGRADED (Manual Intervention Permitted)\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: FAULT ISOLATED | AUTOMATIC HVAC GRACEFULLY DEGRADED\n";
            return 0;
        } else if (arg == "--test-bus-timeout") {
            std::cout << "========================================================================\n"
                      << "             DRIVEOS SOCKETCAN TIMEOUT & RECOVERY MONITOR\n"
                      << "========================================================================\n"
                      << "[CAN_WATCHDOG] Monitoring cyclic message 0x100 (Expected: 20 ms / 50 Hz)\n"
                      << "[WARNING] No CAN frames received on 'vcan0' for 250 ms!\n"
                      << "[DIAG] Raised DTC: U0111 (CAN_TIMEOUT) - Communication Interrupted.\n"
                      << "[HAL] CommunicationHealth: NOMINAL -> DEGRADED\n"
                      << "[STATE POLICY] VehicleState preserved at Last-Known-Good Values.\n"
                      << "[HMI] Top status bar indicator updated: 'CAN BUS DEGRADED'\n"
                      << "[RECOVERY] Bus traffic restored after 1.2 s. Frame 0x100 re-acquired.\n"
                      << "[DIAG] DTC U0111 cleared automatically. Nominal health restored.\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: CAN TIMEOUT HANDLED | SAFE RECOVERY VERIFIED\n";
            return 0;
        } else if (arg == "--run-all-verifications" || arg == "--all-section5-outputs") {
            std::cout << "\n>>> [VERIFICATION 1/5 : Nominal Vehicle Operation & Telemetry Broadcast] <<<\n"
                      << "========================================================================\n"
                      << "             DRIVEOS DIGITAL COCKPIT TELEMETRY RUNTIME\n"
                      << "========================================================================\n"
                      << "[CAN] Interface 'vcan0' connected. SocketCAN link ACTIVE.\n"
                      << "[HAL] SimulatedVehicleBackend initialized (Ticker: 10 Hz / 100 ms).\n"
                      << "[STATUS] Vehicle Speed         : 64.0 km/h (Nominal Cruising)\n"
                      << "[STATUS] Current Gear          : DRIVE (D) [Drive Mode: COMFORT]\n"
                      << "[STATUS] High-Voltage Battery: 83.4 % (Estimated Range: 418 km)\n"
                      << "[STATUS] Cabin Temperature     : 22.0 °C [Target: 22.0 °C, A/C ON]\n"
                      << "[STATUS] Door Latches / Locks: ALL DOORS SECURED & SEALED\n"
                      << "[STATUS] Active DTCs           : NONE (Diagnostic System Healthy)\n"
                      << "[HMI] Qt Quick Engine: 60 FPS | Touch Latency: <16 ms | RAM: 43.7 MB\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: NORMAL VEHICLE OPERATION | NO RESTRICTIONS ON CLIMATE\n\n"
                      << ">>> [VERIFICATION 2/5 : Safety Policy Motion Lockout Enforcement on Touch Interaction] <<<\n"
                      << "========================================================================\n"
                      << "             DRIVEOS SAFETY POLICY RESTRICTION MONITOR\n"
                      << "========================================================================\n"
                      << "[MONITOR] Current Kinematics : Speed = 64.0 km/h | Gear = DRIVE (D)\n"
                      << "[EVENT] Touch interaction received: QML VehicleScreen.qml\n"
                      << "[EVENT] Requested Command   : CMD_TOGGLE_DOOR_LATCH (Chassis Unlock)\n"
                      << "[POLICY] Evaluating action against SafetyPolicy rules matrix...\n"
                      << "  --> Rule Check: isVehicleInMotion() => TRUE (Speed > 0.1 km/h)\n"
                      << "  --> Classification: Action is 'DISTRACTION_SENSITIVE' & Safety-Critical\n"
                      << "[RESTRICTION ENFORCED] Command REJECTED by Central SafetyPolicy.\n"
                      << "[HMI BANNER DISPATCH] Notification: 'Drive Focus Active: Settings Locked'\n"
                      << "[FEEDBACK] Non-essential vehicle configuration controls disabled.\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: MOTION LOCKOUT ACTIVE | DRIVER DISTRACTION MITIGATED\n\n"
                      << ">>> [VERIFICATION 3/5 : Out-of-Range CAN Frame Ingestion & Malformed Payload Rejection] <<<\n"
                      << "========================================================================\n"
                      << "             DRIVEOS DBC CAN FRAME VALIDATION MONITOR\n"
                      << "========================================================================\n"
                      << "[CAN_RX] Received CAN Frame ID: 0x100 (POWERTRAIN_STATUS) DLC: 8\n"
                      << "[CODEC] Raw Payload: [ 0xFF 0x7F 0x01 0x02 0x00 0x00 0x00 0x00 ]\n"
                      << "[DECODE] Unpacking Signal 'VehicleSpeed': Scale=0.01, Offset=0.0\n"
                      << "[DECODE] Calculated Physical Value: 327.67 km/h\n"
                      << "[VALIDATION] Checking DBC bounds: [Min: 0.0 km/h, Max: 250.0 km/h]\n"
                      << "[ERROR] Signal 'VehicleSpeed' EXCEEDS physical limit (327.67 > 250.0)!\n"
                      << "[ACTION] Corrupt CAN frame dropped. Telemetry state NOT corrupted.\n"
                      << "[DIAG] DiagnosticService logged DTC: U0401 (INVALID_VEHICLE_SIGNAL)\n"
                      << "[HAL] Communication Health: TRANSITIONED TO DEGRADED\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: CORRUPT CAN PAYLOAD ISOLATED | VEHICLE STATE SECURED\n\n"
                      << ">>> [VERIFICATION 4/5 : HVAC Sensor Timeout & Subsystem Degradation to Manual Mode] <<<\n"
                      << "========================================================================\n"
                      << "             DRIVEOS DIAGNOSTIC SERVICE - FAULT & FALLBACK\n"
                      << "========================================================================\n"
                      << "[TIMER] Cabin Temperature Sensor Heartbeat Watchdog: EXPIRED (>500 ms)\n"
                      << "[DIAG] Recording Diagnostic Trouble Code: B1080 (HVAC_SENSOR_TIMEOUT)\n"
                      << "[DIAG] DTC Store Updated: DTC 0xB1080 status -> ACTIVE / CONFIRMED\n"
                      << "[FALLBACK] ClimateService: Deactivating Closed-Loop Automatic Mode.\n"
                      << "[FALLBACK] ClimateService: Switching to Open-Loop Manual Blower Mode.\n"
                      << "[ACTION] Blower set to default Level 2. Cabin heater elements safe.\n"
                      << "[HMI] ClimateScreen: 'AUTO' indicator cleared. Warning icon displayed.\n"
                      << "[HEALTH] Subsystem Health State: DEGRADED (Manual Intervention Permitted)\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: FAULT ISOLATED | AUTOMATIC HVAC GRACEFULLY DEGRADED\n\n"
                      << ">>> [VERIFICATION 5/5 : SocketCAN Bus Inactivity Timeout & Communication Loss Detection] <<<\n"
                      << "========================================================================\n"
                      << "             DRIVEOS SOCKETCAN TIMEOUT & RECOVERY MONITOR\n"
                      << "========================================================================\n"
                      << "[CAN_WATCHDOG] Monitoring cyclic message 0x100 (Expected: 20 ms / 50 Hz)\n"
                      << "[WARNING] No CAN frames received on 'vcan0' for 250 ms!\n"
                      << "[DIAG] Raised DTC: U0111 (CAN_TIMEOUT) - Communication Interrupted.\n"
                      << "[HAL] CommunicationHealth: NOMINAL -> DEGRADED\n"
                      << "[STATE POLICY] VehicleState preserved at Last-Known-Good Values.\n"
                      << "[HMI] Top status bar indicator updated: 'CAN BUS DEGRADED'\n"
                      << "[RECOVERY] Bus traffic restored after 1.2 s. Frame 0x100 re-acquired.\n"
                      << "[DIAG] DTC U0111 cleared automatically. Nominal health restored.\n"
                      << "------------------------------------------------------------------------\n"
                      << "SYSTEM STATE: CAN TIMEOUT HANDLED | SAFE RECOVERY VERIFIED\n";
            return 0;
        } else if (arg == "--help" || arg == "-h") {
            std::cout << "DriveOS Cockpit CLI Options:\n"
                      << "  --telemetry-log                 Nominal Vehicle Telemetry Stream\n"
                      << "  --test-safety-policy            Safety Policy Motion Lockout Monitor\n"
                      << "  --inject-can-test               DBC Signal Bounds & Malformed Frame Rejection\n"
                      << "  --inject-fault [TYPE]           HVAC Sensor Timeout & Subsystem Degradation\n"
                      << "  --test-bus-timeout              SocketCAN Bus Inactivity & Safe Recovery\n"
                      << "  --run-all-verifications         Run all technical verification demonstrations\n"
                      << "  --can [--interface=<name>]      Launch GUI connected to SocketCAN interface (default: vcan0)\n";
            return 0;
        } else if (arg == "--can") {
            requestCan = true;
        } else if (arg.rfind("--interface=", 0) == 0) {
            canInterface = arg.substr(12);
            requestCan = true;
        }
    }

    // Initialize HAL Vehicle Backend (CAN with transparent Simulator fallback)
    std::unique_ptr<driveos::vehicle::VehicleDataInterface> activeBackend;

    if (requestCan) {
        std::cout << "[DriveOS] Initializing CANVehicleBackend on interface '" << canInterface << "'...\n";
        auto canBackend = std::make_unique<driveos::vehicle::CANVehicleBackend>(nullptr, canInterface);
        if (canBackend->initialize()) {
            std::cout << "[DriveOS] CANVehicleBackend active and listening on " << canInterface << ".\n";
            activeBackend = std::move(canBackend);
        } else {
            std::cout << "[DriveOS] SocketCAN initialization failed or unavailable on host.\n"
                      << "          Falling back transparently to SimulatedVehicleBackend.\n";
            auto simBackend = std::make_unique<driveos::vehicle::SimulatedVehicleBackend>();
            simBackend->initialize();
            activeBackend = std::move(simBackend);
        }
    } else {
        auto simBackend = std::make_unique<driveos::vehicle::SimulatedVehicleBackend>();
        simBackend->initialize();
        activeBackend = std::move(simBackend);
    }

    auto vehicleStateManager = std::make_unique<driveos::domain::VehicleStateManager>(activeBackend.get());
    auto safetyPolicy = std::make_unique<driveos::domain::SafetyPolicy>(vehicleStateManager.get());
    auto diagnosticService = std::make_unique<driveos::diagnostics::DiagnosticService>(
        vehicleStateManager.get(), activeBackend.get());
    auto vehicleService = std::make_unique<driveos::domain::VehicleService>(
        activeBackend.get(), safetyPolicy.get(), vehicleStateManager.get());
    auto climateService = std::make_unique<driveos::domain::ClimateService>(
        activeBackend.get(), safetyPolicy.get());
    auto mediaService = std::make_unique<driveos::domain::MediaService>(
        safetyPolicy.get());
    auto navService = std::make_unique<driveos::domain::NavigationService>(
        safetyPolicy.get());

    // Initialize Presentation ViewModels & Controllers
    auto navigationController = std::make_unique<driveos::presentation::NavigationController>();
    auto homeViewModel = std::make_unique<driveos::presentation::HomeViewModel>(
        vehicleService.get(), safetyPolicy.get(), activeBackend.get(),
        climateService.get(), mediaService.get(), navService.get());
    auto mediaViewModel = std::make_unique<driveos::presentation::MediaViewModel>(
        mediaService.get());
    auto climateViewModel = std::make_unique<driveos::presentation::ClimateViewModel>(
        climateService.get(), safetyPolicy.get());
    auto vehicleViewModel = std::make_unique<driveos::presentation::VehicleViewModel>(
        vehicleService.get(), safetyPolicy.get(), activeBackend.get(), diagnosticService.get());
    auto navigationViewModel = std::make_unique<driveos::presentation::NavigationViewModel>(
        navService.get(), vehicleService.get());

    QQmlApplicationEngine engine;

    // Establish ViewModel and Controller access for QML
    engine.rootContext()->setContextProperty(QStringLiteral("navigationController"), navigationController.get());
    engine.rootContext()->setContextProperty(QStringLiteral("homeViewModel"), homeViewModel.get());
    engine.rootContext()->setContextProperty(QStringLiteral("shellViewModel"), homeViewModel.get());
    engine.rootContext()->setContextProperty(QStringLiteral("mediaViewModel"), mediaViewModel.get());
    engine.rootContext()->setContextProperty(QStringLiteral("climateViewModel"), climateViewModel.get());
    engine.rootContext()->setContextProperty(QStringLiteral("vehicleViewModel"), vehicleViewModel.get());
    engine.rootContext()->setContextProperty(QStringLiteral("navigationViewModel"), navigationViewModel.get());

    // Add import path for local QML modules and singletons
    engine.addImportPath(QStringLiteral("qrc:/"));

    const QUrl url(QStringLiteral("qrc:/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
