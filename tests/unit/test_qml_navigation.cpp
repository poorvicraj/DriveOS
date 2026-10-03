#include "presentation/NavigationController.hpp"
#include "presentation/HomeViewModel.hpp"
#include "presentation/ClimateViewModel.hpp"
#include "presentation/VehicleViewModel.hpp"
#include "presentation/MediaViewModel.hpp"
#include "presentation/NavigationViewModel.hpp"
#include "domain/ClimateService.hpp"
#include "domain/VehicleService.hpp"
#include "domain/MediaService.hpp"
#include "domain/NavigationService.hpp"
#include "domain/SafetyPolicy.hpp"
#include "domain/VehicleStateManager.hpp"
#include "diagnostics/DiagnosticService.hpp"
#include "vehicle/SimulatedVehicleBackend.hpp"

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickWindow>
#include <gtest/gtest.h>

using namespace driveos::presentation;
using namespace driveos::domain;
using namespace driveos::vehicle;
using namespace driveos::diagnostics;

// =============================================================================
// 1. NavigationController Routing & Back-Stack Tests
// =============================================================================

TEST(QmlNavigationTestSuite, InitialNavigationState) {
    NavigationController nav;
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Home);
    EXPECT_EQ(nav.currentScreenName(), QStringLiteral("Home"));
    EXPECT_FALSE(nav.canGoBack());
}

TEST(QmlNavigationTestSuite, RouteHomeToMedia) {
    NavigationController nav;

    nav.navigateTo(NavigationController::Screen::Media);
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Media);
    EXPECT_EQ(nav.currentScreenName(), QStringLiteral("Media"));
    EXPECT_TRUE(nav.canGoBack());
}

TEST(QmlNavigationTestSuite, RouteHomeToClimate) {
    NavigationController nav;

    nav.navigateTo(NavigationController::Screen::Climate);
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Climate);
    EXPECT_EQ(nav.currentScreenName(), QStringLiteral("Climate"));
    EXPECT_TRUE(nav.canGoBack());
}

TEST(QmlNavigationTestSuite, RouteHomeToVehicle) {
    NavigationController nav;

    nav.navigateTo(NavigationController::Screen::Vehicle);
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Vehicle);
    EXPECT_EQ(nav.currentScreenName(), QStringLiteral("Vehicle"));
    EXPECT_TRUE(nav.canGoBack());
}

TEST(QmlNavigationTestSuite, RouteHomeToNavigation) {
    NavigationController nav;

    nav.navigateTo(NavigationController::Screen::Navigation);
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Navigation);
    EXPECT_EQ(nav.currentScreenName(), QStringLiteral("Navigation"));
    EXPECT_TRUE(nav.canGoBack());
}

TEST(QmlNavigationTestSuite, RouteByNameAndBackHistoryStack) {
    NavigationController nav;

    // Sequential forward navigation
    nav.navigateToName(QStringLiteral("MediaScreen"));
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Media);

    nav.navigateToName(QStringLiteral("ClimateScreen"));
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Climate);

    nav.navigateToName(QStringLiteral("VehicleScreen"));
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Vehicle);

    nav.navigateToName(QStringLiteral("NavigationScreen"));
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Navigation);

    // Unwind history stack via back navigation
    EXPECT_TRUE(nav.canGoBack());
    nav.goBack();
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Vehicle);

    nav.goBack();
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Climate);

    nav.goBack();
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Media);

    nav.goBack();
    EXPECT_EQ(nav.currentScreen(), NavigationController::Screen::Home);
    EXPECT_FALSE(nav.canGoBack());
}

// =============================================================================
// 2. QML Engine Instantiation & AppShell Loading Test
// =============================================================================

TEST(QmlNavigationTestSuite, QmlEngineLoadsAppShellAndControlsRespond) {
    SimulatedVehicleBackend backend;
    backend.initialize();
    VehicleStateManager stateManager(&backend);
    SafetyPolicy safetyPolicy(&stateManager);
    DiagnosticService diagService(&stateManager, &backend);

    VehicleService vehicleService(&backend, &safetyPolicy, &stateManager);
    ClimateService climateService(&backend, &safetyPolicy);
    MediaService mediaService(&safetyPolicy);
    NavigationService navService(&safetyPolicy);

    NavigationController navCtrl;
    HomeViewModel homeVM(&vehicleService, &safetyPolicy, &backend,
                         &climateService, &mediaService, &navService);
    ClimateViewModel climateVM(&climateService, &safetyPolicy);
    VehicleViewModel vehicleVM(&vehicleService, &safetyPolicy, &backend, &diagService);
    MediaViewModel mediaVM(&mediaService);
    NavigationViewModel navVM(&navService, &vehicleService);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("navigationController"), &navCtrl);
    engine.rootContext()->setContextProperty(QStringLiteral("homeViewModel"), &homeVM);
    engine.rootContext()->setContextProperty(QStringLiteral("shellViewModel"), &homeVM);
    engine.rootContext()->setContextProperty(QStringLiteral("mediaViewModel"), &mediaVM);
    engine.rootContext()->setContextProperty(QStringLiteral("climateViewModel"), &climateVM);
    engine.rootContext()->setContextProperty(QStringLiteral("vehicleViewModel"), &vehicleVM);
    engine.rootContext()->setContextProperty(QStringLiteral("navigationViewModel"), &navVM);

    engine.addImportPath(QStringLiteral("qrc:/"));

    // Load QML hierarchy
    engine.load(QUrl(QStringLiteral("qrc:/Main.qml")));

    const auto rootObjects = engine.rootObjects();
    ASSERT_FALSE(rootObjects.isEmpty());

    QObject* rootWindow = rootObjects.first();
    ASSERT_NE(rootWindow, nullptr);

    // Verify initial screen route is Home
    EXPECT_EQ(navCtrl.currentScreen(), NavigationController::Screen::Home);

    // Verify screen transition to Media via NavigationController
    navCtrl.navigateTo(NavigationController::Screen::Media);
    EXPECT_EQ(navCtrl.currentScreen(), NavigationController::Screen::Media);

    // Verify screen transition to Climate via NavigationController
    navCtrl.navigateTo(NavigationController::Screen::Climate);
    EXPECT_EQ(navCtrl.currentScreen(), NavigationController::Screen::Climate);

    // Verify controls respond to interactions: adjust temperature
    const float initialTemp = climateVM.targetTemperature();
    climateVM.adjustTargetTemperature(1.0f);
    EXPECT_NEAR(climateVM.targetTemperature(), initialTemp + 1.0f, 0.1f);

    // Verify screen transition to Vehicle via NavigationController
    navCtrl.navigateTo(NavigationController::Screen::Vehicle);
    EXPECT_EQ(navCtrl.currentScreen(), NavigationController::Screen::Vehicle);

    // Verify vehicle state change and diagnostic reporting respond
    vehicleVM.setVehicleState(QStringLiteral("DRIVING"));
    EXPECT_EQ(vehicleVM.vehicleState(), QStringLiteral("DRIVING"));
    EXPECT_TRUE(vehicleVM.isDriving());

    // Clean up
    vehicleVM.setVehicleState(QStringLiteral("PARKED"));
}
