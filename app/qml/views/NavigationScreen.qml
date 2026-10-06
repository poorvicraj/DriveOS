import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

Rectangle {
    id: root
    color: DesignSystem.background

    // Helper references to ViewModels
    readonly property var vm: typeof navigationViewModel !== "undefined" ? navigationViewModel : null
    readonly property var svm: typeof shellViewModel !== "undefined" ? shellViewModel : null
    readonly property var vvm: typeof vehicleViewModel !== "undefined" ? vehicleViewModel : null

    // Real-Life Driving Simulation Engine (Active by default for live road traversal)
    property bool isSimulatingDrive: true
    property real simRouteProgress: vm ? vm.routeProgress : 0.25

    // Driving state flag (from navigationViewModel, shellViewModel, or active simulation)
    readonly property bool isDrivingMode: (vm && vm.isDriving) || (svm && svm.isDriving) || root.isSimulatingDrive

    // Current vehicle speed for telemetry and over-speed warnings
    readonly property real currentSpeed: root.isSimulatingDrive ?
        (vm ? (vm.speedLimit > 20 ? vm.speedLimit - 6 : 45) : 54) :
        (vvm ? vvm.speed : (svm ? svm.speed : 0))

    // Search and category filter state
    property string activeCategoryFilter: "All"
    property string searchQuery: ""
    property string customApiKey: "" // Optional Google Maps API key / Mapbox Token

    // =========================================================================
    // REAL-TIME DRIVE SIMULATION TIMER
    // =========================================================================
    Timer {
        id: driveSimTimer
        interval: 40 // ~25 updates per second for butter-smooth movement along road
        running: root.isSimulatingDrive && (vm ? vm.isNavigating : true)
        repeat: true
        onTriggered: {
            root.simRouteProgress += 0.0006; // Realistic cruising progression along road
            if (root.simRouteProgress > 1.0) {
                root.simRouteProgress = 0.0;
            }
            if (vm) {
                vm.setRouteProgress(root.simRouteProgress);
            }
        }
    }

    // =========================================================================
    // 1. BACKDROP: REAL SATELLITE & SLIPPY TILE NAVIGATION ENGINE
    // =========================================================================
    SimulatedMapCanvas {
        id: mapBackdrop
        anchors.fill: parent
        customApiKey: root.customApiKey

        destinationName: vm ? vm.destinationTitle : "Mysuru Palace"
        destinationIcon: vm ? vm.destinationIcon : "🏰"
        destinationAddress: vm ? vm.destinationAddress : "Sayyaji Rao Rd, Mysuru"
        etaFormatted: vm ? vm.etaFormatted : "18 min"
        destX: vm ? vm.destX : 0.74
        destY: vm ? vm.destY : 0.26
        isNavigating: vm ? vm.isNavigating : true
        isDriving: root.isDrivingMode

        // Real Geographic Coordinates & Moving Vehicle Telemetry
        currentLatitude: vm ? vm.currentLatitude : 12.3410
        currentLongitude: vm ? vm.currentLongitude : 76.6268
        currentHeading: vm ? vm.currentHeading : 45.0
        destinationLatitude: vm ? vm.destinationLatitude : 12.3052
        destinationLongitude: vm ? vm.destinationLongitude : 76.6552
        routeWaypoints: vm ? vm.routeWaypoints : []
        allDestinations: vm ? vm.destinations : []
        speedLimit: vm ? vm.speedLimit : 60
        mapLayerType: vm ? vm.mapLayerType : "satellite"
        is3DMode: vm ? vm.is3DMode : false

        // User Location Pin (Distinct from moving vehicle)
        userLatitude: vm ? vm.userLatitude : 12.3551
        userLongitude: vm ? vm.userLongitude : 76.6186
        userLocationTitle: vm ? vm.userLocationTitle : "Current Location of the User"
        userLocationAddress: vm ? vm.userLocationAddress : "GSSSIETW Campus, KRS Road, Mysuru"

        // Dijkstra Shortest Path Telemetry
        pathfindingAlgorithm: vm ? vm.pathfindingAlgorithm : "Dijkstra's Shortest Path Algorithm"
        shortestPathNodeCount: vm ? vm.shortestPathNodeCount : 8
        shortestPathDistanceKm: vm ? vm.shortestPathDistanceKm : 8.4
        vehicleSpeed: root.currentSpeed

        onDestinationSelected: (index) => {
            if (vm) vm.selectDestination(index);
        }

        onRecenterRequested: {
            if (svm) {
                svm.userNotificationRequested("Vehicle Tracking", "Camera tracking moving vehicle along shortest path.");
            }
        }

        onRecenterOnUserRequested: {
            if (svm) {
                svm.userNotificationRequested("User Location", "Camera centered on User Current Location (GSSSIETW Campus).");
            }
        }
    }

    // =========================================================================
    // =========================================================================
    // 2. TOP CONTEXT HUD BAR (Dark Solid High-Contrast Styling)
    // =========================================================================
    Column {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm
        z: 400

        // Top Control Row: Simulation Toggle, Speed Limit Sign, and 3D GNSS Status
        Row {
            anchors.right: parent.right
            spacing: DesignSystem.spacingSm

            // Real-Life Drive Simulation Toggle Button
            Rectangle {
                height: 42
                radius: DesignSystem.radiusPill
                color: root.isSimulatingDrive ? "#0C4A6E" : "#0A0F1D"
                border.color: root.isSimulatingDrive ? DesignSystem.accentCyan : Qt.rgba(255, 255, 255, 0.22)
                border.width: root.isSimulatingDrive ? 2 : 1
                implicitWidth: simRow.implicitWidth + 24

                Row {
                    id: simRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: root.isSimulatingDrive ? "⏸" : "▶"
                        font.pixelSize: 13
                        color: root.isSimulatingDrive ? "#38BDF8" : "#FFFFFF"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.isSimulatingDrive ? "DRIVING SIMULATION ACTIVE" : "SIMULATE DRIVE"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        font.letterSpacing: 0.8
                        color: root.isSimulatingDrive ? "#FFFFFF" : "#CBD5E1"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isSimulatingDrive = !root.isSimulatingDrive;
                    }
                }
            }

            // Speed Limit Sign with dynamic over-speed warning
            Rectangle {
                width: 42
                height: 42
                radius: 21
                color: "#FFFFFF"
                border.color: (root.currentSpeed > (vm ? vm.speedLimit : 60)) ? "#EF4444" : "#DC2626"
                border.width: (root.currentSpeed > (vm ? vm.speedLimit : 60)) ? 4.5 : 3.5

                // Flashing aura when speeding
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.currentSpeed > (vm ? vm.speedLimit : 60)
                    NumberAnimation { from: 1.0; to: 0.6; duration: 500 }
                    NumberAnimation { from: 0.6; to: 1.0; duration: 500 }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: -3

                    Text {
                        text: "SPEED"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 7
                        font.weight: DesignSystem.fontWeightBold
                        color: "#64748B"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: vm ? String(vm.speedLimit) : "60"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 15
                        font.weight: DesignSystem.fontWeightBold
                        color: "#0F172A"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // 3D GNSS RTK Lock Badge
            Rectangle {
                height: 42
                radius: DesignSystem.radiusPill
                color: "#0A0F1D"
                border.color: Qt.rgba(255, 255, 255, 0.22)
                border.width: 1
                implicitWidth: gnssRow.implicitWidth + 20

                Row {
                    id: gnssRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: DesignSystem.accentEmerald
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            NumberAnimation { from: 1.0; to: 0.4; duration: 900 }
                            NumberAnimation { from: 0.4; to: 1.0; duration: 900 }
                        }
                    }

                    Text {
                        text: "3D GNSS • 18 SATS"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: "#FFFFFF"
                        font.letterSpacing: 0.6
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Sub-Stack directly UNDER the 3D GNSS badge: Shortest Path & User Current Location
        Column {
            anchors.right: parent.right
            spacing: DesignSystem.spacingSm

            // Dijkstra Shortest Path Engine Badge
            Rectangle {
                id: dijkstraBadge
                anchors.right: parent.right
                height: 38
                radius: DesignSystem.radiusPill
                color: dijkstraMa.containsMouse ? "#141E33" : "#0A0F1D"
                border.color: dijkstraMa.containsMouse ? "#38BDF8" : DesignSystem.accentCyan
                border.width: 1.5
                implicitWidth: dijkstraRow.implicitWidth + 22

                Row {
                    id: dijkstraRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "🔀"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            text: "SHORTEST PATH (DIJKSTRA)"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 9
                            font.weight: DesignSystem.fontWeightBold
                            color: dijkstraMa.containsMouse ? "#7DD3FC" : DesignSystem.accentCyan
                        }

                        Text {
                            text: (vm ? vm.shortestPathDistanceKm.toFixed(1) : "8.4") + " km • " + (vm ? vm.shortestPathNodeCount : 8) + " Road Nodes"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 10
                            font.weight: DesignSystem.fontWeightBold
                            color: "#FFFFFF"
                        }
                    }
                }

                MouseArea {
                    id: dijkstraMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mapBackdrop.recenterOnVehicle();
                        if (svm) {
                            svm.userNotificationRequested("Shortest Path", "Centered camera on Dijkstra route trajectory.");
                        }
                    }
                }
            }

            // User Location Pin Indicator Badge
            Rectangle {
                id: userLocBadge
                anchors.right: parent.right
                height: 38
                radius: DesignSystem.radiusPill
                color: userLocMa.containsMouse ? "#141E33" : "#0A0F1D"
                border.color: userLocMa.containsMouse ? "#34D399" : "#10B981"
                border.width: 1.5
                implicitWidth: userLocRow.implicitWidth + 22

                Row {
                    id: userLocRow
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        text: "📍"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            text: "USER CURRENT LOCATION"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 9
                            font.weight: DesignSystem.fontWeightBold
                            color: userLocMa.containsMouse ? "#6EE7B7" : "#34D399"
                        }

                        Text {
                            text: vm ? vm.userLocationAddress : "GSSSIETW Campus, Mysuru"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 10
                            font.weight: DesignSystem.fontWeightBold
                            color: "#FFFFFF"
                        }
                    }
                }

                MouseArea {
                    id: userLocMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        mapBackdrop.isUserPanning = true;
                        mapBackdrop.cameraLat = mapBackdrop.userLatitude;
                        mapBackdrop.cameraLon = mapBackdrop.userLongitude;
                        if (svm) {
                            svm.userNotificationRequested("User Location", "Camera centered on User Current Location.");
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 3. MOVABLE COCKPIT NAVIGATION HUB (Draggable, Solid Dark, High-Contrast UI)
    // =========================================================================
    Item {
        id: movableCockpitPanel
        z: 400

        // Movable coordinates & state
        property real panelX: 16
        property real panelY: 16
        property bool isDragging: false
        property bool isMinimized: false

        x: panelX
        y: panelY
        width: isMinimized ? 390 : 424
        height: isMinimized ? 92 : Math.min(root.height - 32, 690)

        // Smooth glide transition when snapping or docking
        Behavior on x {
            enabled: !movableCockpitPanel.isDragging
            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
        }
        Behavior on y {
            enabled: !movableCockpitPanel.isDragging
            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
        }
        Behavior on width {
            NumberAnimation { duration: 240; easing.type: Easing.OutQuad }
        }
        Behavior on height {
            NumberAnimation { duration: 240; easing.type: Easing.OutQuad }
        }

        // =====================================================================
        // VIEW A: MINIMIZED FLOATING HUD PILL (Full panoramic map view)
        // =====================================================================
        Rectangle {
            id: minimizedPill
            anchors.fill: parent
            visible: movableCockpitPanel.isMinimized
            radius: DesignSystem.radiusXl
            color: "#0A0F1D"
            border.color: movableCockpitPanel.isDragging ? DesignSystem.accentCyan : Qt.rgba(56, 189, 248, 0.55)
            border.width: 1.5

            // Drop shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: parent.radius + 4
                color: Qt.rgba(0, 0, 0, 0.60)
                z: -1
            }

            // Draggable Gripper Area
            MouseArea {
                anchors.fill: parent
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: movableCockpitPanel
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 12
                drag.maximumX: Math.max(12, root.width - movableCockpitPanel.width - 12)
                drag.minimumY: 12
                drag.maximumY: Math.max(12, root.height - movableCockpitPanel.height - 12)
                onPressed: movableCockpitPanel.isDragging = true
                onReleased: {
                    movableCockpitPanel.isDragging = false;
                    movableCockpitPanel.panelX = movableCockpitPanel.x;
                    movableCockpitPanel.panelY = movableCockpitPanel.y;
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: DesignSystem.spacingSm
                spacing: DesignSystem.spacingSm

                // Drag indicator grip
                Text {
                    text: "⠿"
                    font.pixelSize: 18
                    color: DesignSystem.accentCyan
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 6
                }

                // Turn Icon Box
                Rectangle {
                    implicitWidth: 50
                    implicitHeight: 50
                    radius: DesignSystem.radiusMd
                    color: "#0284C7"
                    border.color: "#38BDF8"
                    border.width: 1.5
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: vm ? vm.turnIcon : "↱"
                        font.pixelSize: 28
                        color: "#FFFFFF"
                    }
                }

                // Turn & ETA Info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: vm ? vm.maneuverInstruction : "In 450 m, turn right onto Palace Road"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightBold
                        color: "#FFFFFF"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: (vm ? vm.etaFormatted : "18 min") + " • " + (vm ? vm.distanceFormatted : "8.4 km") + " remaining"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.accentCyan
                    }
                }

                // Expand Button
                Rectangle {
                    implicitWidth: 38
                    implicitHeight: 38
                    radius: 19
                    color: "#1E293B"
                    border.color: Qt.rgba(255, 255, 255, 0.25)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 6

                    Text {
                        anchors.centerIn: parent
                        text: "⤢"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: movableCockpitPanel.isMinimized = false
                    }
                }
            }
        }

        // =====================================================================
        // VIEW B: EXPANDED COCKPIT HUB (Rich Dark, Maximum Contrast)
        // =====================================================================
        Rectangle {
            id: expandedCard
            anchors.fill: parent
            visible: !movableCockpitPanel.isMinimized
            radius: DesignSystem.radiusXl
            color: "#0A0F1D"
            border.color: movableCockpitPanel.isDragging ? DesignSystem.accentCyan : Qt.rgba(255, 255, 255, 0.22)
            border.width: movableCockpitPanel.isDragging ? 2 : 1.5

            // Drop shadow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: parent.radius + 4
                color: Qt.rgba(0, 0, 0, 0.65)
                z: -1
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: DesignSystem.spacingMd
                spacing: DesignSystem.spacingSm

                // -------------------------------------------------------------
                // 1. MOVABLE CONTROL BAR & DOCKING CONTROLS HEADER
                // -------------------------------------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: DesignSystem.radiusMd
                    color: movableCockpitPanel.isDragging ? "#0C4A6E" : "#111827"
                    border.color: movableCockpitPanel.isDragging ? DesignSystem.accentCyan : "#1F2937"
                    border.width: 1

                    // Drag area for the header
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        drag.target: movableCockpitPanel
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 12
                        drag.maximumX: Math.max(12, root.width - movableCockpitPanel.width - 12)
                        drag.minimumY: 12
                        drag.maximumY: Math.max(12, root.height - movableCockpitPanel.height - 12)
                        onPressed: movableCockpitPanel.isDragging = true
                        onReleased: {
                            movableCockpitPanel.isDragging = false;
                            movableCockpitPanel.panelX = movableCockpitPanel.x;
                            movableCockpitPanel.panelY = movableCockpitPanel.y;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: DesignSystem.spacingSm
                        anchors.rightMargin: DesignSystem.spacingSm

                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "⠿"
                                font.pixelSize: 15
                                color: DesignSystem.accentCyan
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: movableCockpitPanel.isDragging ? "DRAGGING COCKPIT UI..." : "DRAG TO REPOSITION"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                font.letterSpacing: 0.8
                                color: movableCockpitPanel.isDragging ? "#FFFFFF" : "#E2E8F0"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Dock Left preset
                        Rectangle {
                            width: 60
                            height: 24
                            radius: 12
                            color: "#1F2937"
                            border.color: "#374151"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⇥ Left"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: 9
                                font.weight: DesignSystem.fontWeightBold
                                color: "#F8FAFC"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    movableCockpitPanel.panelX = 16;
                                    movableCockpitPanel.panelY = 16;
                                }
                            }
                        }

                        // Dock Right preset
                        Rectangle {
                            width: 64
                            height: 24
                            radius: 12
                            color: "#1F2937"
                            border.color: "#374151"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "⇤ Right"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: 9
                                font.weight: DesignSystem.fontWeightBold
                                color: "#F8FAFC"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    movableCockpitPanel.panelX = root.width - movableCockpitPanel.width - 16;
                                    movableCockpitPanel.panelY = 16;
                                }
                            }
                        }

                        // Minimize to floating pill
                        Rectangle {
                            width: 28
                            height: 24
                            radius: 12
                            color: "#1F2937"
                            border.color: "#374151"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "−"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: 14
                                font.weight: DesignSystem.fontWeightBold
                                color: "#F8FAFC"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: movableCockpitPanel.isMinimized = true
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 2. ACTIVE MANEUVER GUIDANCE CARD (Dark Solid Contrast)
                // -------------------------------------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 124
                    visible: vm ? vm.isNavigating : true
                    radius: DesignSystem.radiusLg
                    color: "#0F172A"
                    border.color: Qt.rgba(56, 189, 248, 0.35)
                    border.width: 1.5

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: DesignSystem.spacingMd
                        spacing: DesignSystem.spacingMd

                        // Turn Maneuver Direction Box
                        Rectangle {
                            implicitWidth: 64
                            implicitHeight: 64
                            radius: DesignSystem.radiusMd
                            color: "#0284C7"
                            border.color: "#38BDF8"
                            border.width: 1.5
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: vm ? vm.turnIcon : "↱"
                                font.pixelSize: 36
                                color: "#FFFFFF"
                            }
                        }

                        // Turn Maneuver Text & Lane Assist
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "IN 450 METERS"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: 18
                                font.weight: DesignSystem.fontWeightBold
                                color: "#FFFFFF"
                                font.letterSpacing: 0.5
                            }

                            Text {
                                text: vm ? vm.maneuverInstruction : "In 450 m, turn right onto Palace Road"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeBody
                                font.weight: DesignSystem.fontWeightBold
                                color: "#F1F5F9"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Lane Guidance Icons
                            Row {
                                spacing: 5
                                Layout.topMargin: 4

                                Rectangle {
                                    width: 22; height: 18; radius: 3
                                    color: "#1E293B"
                                    border.color: "#334155"
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: "↑"; font.pixelSize: 11; color: "#94A3B8" }
                                }
                                Rectangle {
                                    width: 22; height: 18; radius: 3
                                    color: "#1E293B"
                                    border.color: "#334155"
                                    border.width: 1
                                    Text { anchors.centerIn: parent; text: "↑"; font.pixelSize: 11; color: "#94A3B8" }
                                }
                                Rectangle {
                                    width: 22; height: 18; radius: 3
                                    color: "#0284C7"
                                    border.color: "#38BDF8"
                                    border.width: 1.5
                                    Text { anchors.centerIn: parent; text: "↱"; font.pixelSize: 11; font.weight: Font.Bold; color: "#FFFFFF" }
                                }

                                Item { width: 6; height: 1 }

                                Text {
                                    text: "3 Lanes • Stay in Right Lane"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeMicro
                                    font.weight: DesignSystem.fontWeightBold
                                    color: DesignSystem.accentCyan
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 3. REAL PLACES & DESTINATIONS EXPLORER (Dark Solid Contrast)
                // -------------------------------------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: DesignSystem.radiusLg
                    color: "#0F172A"
                    border.color: Qt.rgba(255, 255, 255, 0.16)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: DesignSystem.spacingSm
                        spacing: DesignSystem.spacingSm

                        // Header: Real Places / Destinations
                        RowLayout {
                            Layout.fillWidth: true

                            Row {
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "🧭"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "REAL PLACES & DESTINATIONS"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeMicro
                                    font.weight: DesignSystem.fontWeightBold
                                    color: "#F1F5F9"
                                    font.letterSpacing: 0.8
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: (vm ? vm.destinations.length : 8) + " Places"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.accentCyan
                            }
                        }

                        // Category Filter Pills
                        Row {
                            spacing: 5
                            Layout.fillWidth: true

                            Repeater {
                                model: ["All", "Landmark", "Charging", "Education", "Work"]

                                Rectangle {
                                    height: 26
                                    implicitWidth: catText.implicitWidth + 16
                                    radius: 13
                                    color: (root.activeCategoryFilter === modelData) ? "#0284C7" : "#1E293B"
                                    border.color: (root.activeCategoryFilter === modelData) ? "#38BDF8" : "#334155"
                                    border.width: (root.activeCategoryFilter === modelData) ? 1.5 : 1

                                    Text {
                                        id: catText
                                        anchors.centerIn: parent
                                        text: modelData === "All" ? "All" : (modelData === "Charging" ? "⚡ Charging" : (modelData === "Landmark" ? "🏰 Places" : (modelData === "Education" ? "🏫 Tech" : "🏢 Work")))
                                        font.family: DesignSystem.fontFamily
                                        font.pixelSize: 10
                                        font.weight: DesignSystem.fontWeightBold
                                        color: "#FFFFFF"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.activeCategoryFilter = modelData
                                    }
                                }
                            }
                        }

                        // Destination List
                        ListView {
                            id: destListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 5

                            // Dynamic model filtering based on category
                            model: {
                                var all = vm ? vm.destinations : [];
                                if (root.activeCategoryFilter === "All") return all;
                                var filtered = [];
                                for (var i = 0; i < all.length; ++i) {
                                    if (all[i].category === root.activeCategoryFilter) {
                                        filtered.push(all[i]);
                                    }
                                }
                                return filtered;
                            }

                            delegate: Rectangle {
                                id: destDelegate
                                width: destListView.width
                                height: 56
                                radius: DesignSystem.radiusMd

                                readonly property bool isCurrent: modelData ? Boolean(modelData.isSelected) : false

                                color: isCurrent ? "#0C4A6E" :
                                       (delegateArea.pressed ? "#1E293B" :
                                       (delegateArea.containsMouse ? "#1A2536" : "#131C2E"))
                                border.color: isCurrent ? "#38BDF8" : "#1E293B"
                                border.width: isCurrent ? 2 : 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: DesignSystem.spacingSm
                                    anchors.rightMargin: DesignSystem.spacingSm
                                    spacing: DesignSystem.spacingSm

                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 22
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Layout.alignment: Qt.AlignVCenter

                                        Text {
                                            text: modelData.name
                                            font.family: DesignSystem.fontFamily
                                            font.pixelSize: DesignSystem.fontSizeCaption
                                            font.weight: DesignSystem.fontWeightBold
                                            color: "#FFFFFF"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: (modelData.address || modelData.category) + " • " + modelData.distance + " • " + modelData.eta
                                            font.family: DesignSystem.fontFamily
                                            font.pixelSize: 11
                                            font.weight: DesignSystem.fontWeightMedium
                                            color: destDelegate.isCurrent ? "#BAE6FD" : "#CBD5E1"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Selection Checkmark / Arrow
                                    Text {
                                        text: destDelegate.isCurrent ? "✓" : "›"
                                        font.family: DesignSystem.fontFamily
                                        font.pixelSize: destDelegate.isCurrent ? 16 : 18
                                        font.weight: DesignSystem.fontWeightBold
                                        color: destDelegate.isCurrent ? "#38BDF8" : "#94A3B8"
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                MouseArea {
                                    id: delegateArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (vm) vm.selectDestination(modelData.index);
                                    }
                                }
                            }
                        }

                        // -----------------------------------------------------
                        // PRIMARY ACTION BUTTON (START / STOP NAVIGATION)
                        // -----------------------------------------------------
                        Rectangle {
                            id: navActionBtn
                            Layout.fillWidth: true
                            implicitHeight: 46
                            radius: DesignSystem.radiusMd

                            readonly property bool navigating: vm ? vm.isNavigating : true

                            color: navigating ? "#7F1D1D" : "#0284C7"
                            border.color: navigating ? "#EF4444" : "#38BDF8"
                            border.width: 1.5
                            scale: actionArea.pressed ? 0.98 : 1.0

                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: navActionBtn.navigating ? "⏹" : "▶"
                                    font.pixelSize: 14
                                    color: "#FFFFFF"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: navActionBtn.navigating ? "END NAVIGATION ROUTE" : "START SATELLITE NAVIGATION"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeCaption
                                    font.weight: DesignSystem.fontWeightBold
                                    color: "#FFFFFF"
                                    font.letterSpacing: 0.8
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: actionArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (vm) vm.toggleNavigation();
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 4. TRIP METRICS HUD (ETA, Distance, Arrival, Battery)
                // -------------------------------------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 86
                    radius: DesignSystem.radiusLg
                    color: "#0F172A"
                    border.color: Qt.rgba(255, 255, 255, 0.16)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: DesignSystem.spacingSm
                        spacing: DesignSystem.spacingSm

                        // ETA Section
                        Column {
                            Layout.preferredWidth: 88
                            spacing: 1

                            Text {
                                text: vm ? vm.etaFormatted : "18 min"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeTitle
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.accentEmerald
                            }
                            Text {
                                text: "EST. TIME"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: "#CBD5E1"
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 36
                            color: Qt.rgba(255, 255, 255, 0.20)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Distance Section
                        Column {
                            Layout.preferredWidth: 82
                            spacing: 1

                            Text {
                                text: vm ? vm.distanceFormatted : "8.4 km"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeSubtitle
                                font.weight: DesignSystem.fontWeightBold
                                color: "#FFFFFF"
                            }
                            Text {
                                text: "DISTANCE"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: "#CBD5E1"
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 36
                            color: Qt.rgba(255, 255, 255, 0.20)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Arrival Clock & Battery Section
                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: vm ? vm.arrivalClockFormatted : "11:00 AM"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeSubtitle
                                font.weight: DesignSystem.fontWeightBold
                                color: "#FFFFFF"
                            }
                            Text {
                                text: "ARRIVAL • 🔋 " + (vm ? String(vm.batteryArrivalSoc) : "82") + "% SOC"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.accentCyan
                            }
                        }
                    }
                }
            }
        }
    }
}
