#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSurfaceFormat>

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

    // Evaluate requested backend: Check command-line options
    bool requestCan = false;
    std::string canInterface = "vcan0";
    for (int i = 1; i < argc; ++i) {
        const std::string arg = argv[i];
        if (arg == "--can") {
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
