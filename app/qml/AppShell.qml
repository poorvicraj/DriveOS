import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme"
import "components"
import "views"

Rectangle {
    id: root
    anchors.fill: parent
    color: DesignSystem.background

    // Floating Warning / Distraction Toast Banner
    WarningBanner {
        id: distractionBanner
        anchors.top: parent.top
        anchors.topMargin: visible ? DesignSystem.spacingMd : -100
        anchors.horizontalCenter: parent.horizontalCenter
        z: 99
        visible: false
        opacity: visible ? 1.0 : 0.0
        severity: "warning"

        Behavior on anchors.topMargin { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }

        Timer {
            id: bannerTimer
            interval: 3800
            onTriggered: distractionBanner.visible = false
        }

        onDismissed: distractionBanner.visible = false
    }

    Connections {
        target: typeof shellViewModel !== "undefined" ? shellViewModel : null
        function onUserNotificationRequested(title, message) {
            distractionBanner.title = title
            distractionBanner.message = message
            distractionBanner.visible = true
            bannerTimer.restart()
        }
    }

    // Persistent Top Application Header
    AppHeader {
        id: appHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 10
        canGoBack: typeof navigationController !== "undefined" && navigationController.canGoBack
        gear: typeof shellViewModel !== "undefined" ? shellViewModel.gear : "P"
        speedFormatted: typeof shellViewModel !== "undefined" ? shellViewModel.speedFormatted : "0"
        batteryFormatted: typeof shellViewModel !== "undefined" ? shellViewModel.batterySocFormatted : "85%"
        isDriving: typeof shellViewModel !== "undefined" && shellViewModel.isDriving
        hasFault: typeof shellViewModel !== "undefined" && shellViewModel.hasFault
        backendName: typeof shellViewModel !== "undefined" ? shellViewModel.backendName : "VDI / SIMULATOR READY"

        onBackClicked: {
            if (typeof navigationController !== "undefined") {
                navigationController.goBack()
            }
        }

        onTogglePerformanceHud: {
            performanceHud.visible = !performanceHud.visible
        }
    }

    // Central Viewport with Fluid Page Transitions
    Item {
        id: contentContainer
        anchors.top: appHeader.bottom
        anchors.bottom: bottomNav.top
        anchors.left: parent.left
        anchors.right: parent.right

        // Screen 0: Home
        HomeScreen {
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (typeof navigationController !== "undefined" && navigationController.currentScreen === 0) ? 1.0 : 0.0
            scale: (typeof navigationController !== "undefined" && navigationController.currentScreen === 0) ? 1.0 : 0.98
            Behavior on opacity { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
            Behavior on scale { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
        }

        // Screen 1: Media
        MediaScreen {
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (typeof navigationController !== "undefined" && navigationController.currentScreen === 1) ? 1.0 : 0.0
            scale: (typeof navigationController !== "undefined" && navigationController.currentScreen === 1) ? 1.0 : 0.98
            Behavior on opacity { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
            Behavior on scale { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
        }

        // Screen 2: Climate
        ClimateScreen {
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (typeof navigationController !== "undefined" && navigationController.currentScreen === 2) ? 1.0 : 0.0
            scale: (typeof navigationController !== "undefined" && navigationController.currentScreen === 2) ? 1.0 : 0.98
            Behavior on opacity { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
            Behavior on scale { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
        }

        // Screen 3: Vehicle Settings
        VehicleScreen {
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (typeof navigationController !== "undefined" && navigationController.currentScreen === 3) ? 1.0 : 0.0
            scale: (typeof navigationController !== "undefined" && navigationController.currentScreen === 3) ? 1.0 : 0.98
            Behavior on opacity { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
            Behavior on scale { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
        }

        // Screen 4: Navigation
        NavigationScreen {
            anchors.fill: parent
            visible: opacity > 0.01
            opacity: (typeof navigationController !== "undefined" && navigationController.currentScreen === 4) ? 1.0 : 0.0
            scale: (typeof navigationController !== "undefined" && navigationController.currentScreen === 4) ? 1.0 : 0.98
            Behavior on opacity { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
            Behavior on scale { NumberAnimation { duration: DesignSystem.durationNormal; easing.type: DesignSystem.easingCurveStandard } }
        }
    }

    // Persistent Bottom Sliding Pill Navigation Dock
    BottomNavigation {
        id: bottomNav
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        z: 10
        currentIndex: typeof navigationController !== "undefined" ? navigationController.currentScreen : 0
        onTabSelected: function(index) {
            if (typeof navigationController !== "undefined") {
                navigationController.navigateTo(index)
            }
        }
    }

    // Keyboard Hotkey (F12) to toggle Real-Time Performance & Metrics HUD
    Shortcut {
        sequence: "F12"
        onActivated: performanceHud.visible = !performanceHud.visible
    }

    // Performance & Engineering Metrics Overlay HUD
    Rectangle {
        id: performanceHudOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        z: 100
        visible: performanceHud.visible
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            onClicked: performanceHud.visible = false
        }

        PerformanceHUD {
            id: performanceHud
            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 860)
            height: Math.min(parent.height - 48, 520)
            visible: false
            onClosed: performanceHud.visible = false
        }
    }
}
