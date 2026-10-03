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

    // Driving state flag (from navigationViewModel or shellViewModel)
    readonly property bool isDrivingMode: (vm && vm.isDriving) || (svm && svm.isDriving)

    // =========================================================================
    // 1. BACKDROP: PROCEDURAL VECTOR SIMULATED MAP CANVAS
    // =========================================================================
    SimulatedMapCanvas {
        id: mapBackdrop
        anchors.fill: parent

        destinationName: vm ? vm.destinationTitle : "Mysuru Palace"
        destinationIcon: vm ? vm.destinationIcon : "🏰"
        etaFormatted: vm ? vm.etaFormatted : "18 min"
        destX: vm ? vm.destX : 0.74
        destY: vm ? vm.destY : 0.26
        isNavigating: vm ? vm.isNavigating : true
        isDriving: root.isDrivingMode

        onRecenterRequested: {
            if (svm) {
                svm.userNotificationRequested("Navigation View", "Map centered on current vehicle telemetry position.");
            }
        }
    }

    // =========================================================================
    // 2. TOP CONTEXT HUD BAR (Speed Limit, GNSS, Outside Weather)
    // =========================================================================
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm
        z: 10

        // Speed Limit Sign
        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: "#FFFFFF"
            border.color: "#DC2626"
            border.width: 3.5

            Column {
                anchors.centerIn: parent
                spacing: -2
                Text {
                    text: "LIMIT"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: 7
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textSecondary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "60"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: 13
                    font.weight: DesignSystem.fontWeightBold
                    color: "#0F172A"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // GNSS Lock Badge
        Rectangle {
            height: 38
            radius: DesignSystem.radiusPill
            color: Qt.rgba(255, 255, 255, 0.92)
            border.color: DesignSystem.borderMuted
            border.width: 1
            implicitWidth: gnssRow.implicitWidth + 18

            Row {
                id: gnssRow
                anchors.centerIn: parent
                spacing: 5

                Rectangle {
                    width: 7; height: 7; radius: 3.5
                    color: DesignSystem.accentEmerald
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "3D GNSS LOCK"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeMicro
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textSecondary
                    font.letterSpacing: 0.6
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    // =========================================================================
    // 3. FLOATING GUIDANCE & DESTINATIONS PANEL (LEFT SIDE)
    // =========================================================================
    Item {
        id: leftFloatingPanel
        width: 380
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: DesignSystem.spacingMd
        z: 20

        ColumnLayout {
            anchors.fill: parent
            spacing: DesignSystem.spacingSm

            // -----------------------------------------------------------------
            // A. ACTIVE MANEUVER GUIDANCE CARD (Visible when route is active)
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 124
                visible: vm ? vm.isNavigating : true
                radius: DesignSystem.radiusXl
                color: DesignSystem.surfaceElevated
                border.color: DesignSystem.borderMuted
                border.width: 1

                // Drop shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    anchors.bottomMargin: -4
                    radius: parent.radius
                    color: DesignSystem.shadowAmbient
                    z: -1
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingMd

                    // Big Bold Turn Icon Box
                    Rectangle {
                        implicitWidth: 64
                        implicitHeight: 64
                        radius: DesignSystem.radiusMd
                        color: DesignSystem.accentCyan
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: vm ? vm.turnIcon : "↱"
                            font.pixelSize: 34
                            color: "#FFFFFF"
                        }
                    }

                    // Turn Maneuver Text & Lane Assist
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Layout.alignment: Qt.AlignVCenter

                        Row {
                            spacing: 6
                            Text {
                                text: "IN 450 METERS"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeDisplay - 16
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textPrimary
                                font.letterSpacing: -0.5
                            }
                        }

                        Text {
                            text: vm ? vm.maneuverInstruction : "In 450 m, turn right onto Palace Road"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeCaption
                            font.weight: DesignSystem.fontWeightMedium
                            color: DesignSystem.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        // Lane Guidance Icons
                        Row {
                            spacing: 4
                            Layout.topMargin: 2

                            Rectangle {
                                width: 22; height: 18; radius: 3
                                color: DesignSystem.surfaceWell
                                border.color: DesignSystem.borderMuted
                                border.width: 1
                                Text { anchors.centerIn: parent; text: "↑"; font.pixelSize: 11; color: DesignSystem.textMuted }
                            }
                            Rectangle {
                                width: 22; height: 18; radius: 3
                                color: DesignSystem.surfaceWell
                                border.color: DesignSystem.borderMuted
                                border.width: 1
                                Text { anchors.centerIn: parent; text: "↑"; font.pixelSize: 11; color: DesignSystem.textMuted }
                            }
                            Rectangle {
                                width: 22; height: 18; radius: 3
                                color: Qt.rgba(0.01, 0.52, 0.78, 0.18)
                                border.color: DesignSystem.accentCyan
                                border.width: 1
                                Text { anchors.centerIn: parent; text: "↱"; font.pixelSize: 11; font.weight: Font.Bold; color: DesignSystem.accentCyan }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // B. DESTINATION LIST CARD (Visible in Parked or when choosing destination)
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: DesignSystem.radiusXl
                color: DesignSystem.surfaceCard
                border.color: DesignSystem.borderMuted
                border.width: 1
                visible: !root.isDrivingMode // Collapsed during driving mode to minimize distraction!

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingSm

                    // Header: Search / Destinations Label
                    RowLayout {
                        Layout.fillWidth: true

                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "📍"
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "SELECT DESTINATION"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textSecondary
                                font.letterSpacing: 0.8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: (vm ? vm.destinations.length : 5) + " Mock Points"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightMedium
                            color: DesignSystem.textMuted
                        }
                    }

                    // Destination List
                    ListView {
                        id: destListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        model: vm ? vm.destinations : []

                        delegate: Rectangle {
                            id: destDelegate
                            width: destListView.width
                            height: 52
                            radius: DesignSystem.radiusMd

                            readonly property bool isCurrent: modelData ? Boolean(modelData.isSelected) : false

                            color: isCurrent ? Qt.rgba(0.01, 0.52, 0.78, 0.12) :
                                   (delegateArea.pressed ? DesignSystem.surfaceWell :
                                   (delegateArea.containsMouse ? DesignSystem.surfaceElevated : DesignSystem.surfaceWell))
                            border.color: isCurrent ? DesignSystem.accentCyan : DesignSystem.borderMuted
                            border.width: isCurrent ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: DesignSystem.spacingMd
                                anchors.rightMargin: DesignSystem.spacingMd
                                spacing: DesignSystem.spacingSm

                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 18
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: modelData.name
                                        font.family: DesignSystem.fontFamily
                                        font.pixelSize: DesignSystem.fontSizeBody
                                        font.weight: destDelegate.isCurrent ? DesignSystem.fontWeightBold : DesignSystem.fontWeightMedium
                                        color: destDelegate.isCurrent ? DesignSystem.accentCyan : DesignSystem.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.category + " • " + modelData.distance + " • " + modelData.eta
                                        font.family: DesignSystem.fontFamily
                                        font.pixelSize: DesignSystem.fontSizeMicro
                                        font.weight: DesignSystem.fontWeightMedium
                                        color: DesignSystem.textMuted
                                    }
                                }

                                // Selection Checkmark / Arrow
                                Text {
                                    text: destDelegate.isCurrent ? "✓" : "›"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: destDelegate.isCurrent ? 14 : 18
                                    font.weight: DesignSystem.fontWeightBold
                                    color: destDelegate.isCurrent ? DesignSystem.accentCyan : DesignSystem.textMuted
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

                    // ---------------------------------------------------------
                    // PRIMARY ACTION BUTTON (START / STOP NAVIGATION)
                    // ---------------------------------------------------------
                    Rectangle {
                        id: navActionBtn
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: DesignSystem.radiusMd

                        readonly property bool navigating: vm ? vm.isNavigating : true

                        color: navigating ? Qt.rgba(0.86, 0.15, 0.15, 0.12) : DesignSystem.accentCyan
                        border.color: navigating ? DesignSystem.accentRuby : DesignSystem.accentCyan
                        border.width: 1.5
                        scale: actionArea.pressed ? 0.97 : 1.0

                        Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: navActionBtn.navigating ? "⏹" : "▶"
                                font.pixelSize: 13
                                color: navActionBtn.navigating ? DesignSystem.accentRuby : "#FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: navActionBtn.navigating ? "END NAVIGATION ROUTE" : "START NAVIGATION"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeCaption
                                font.weight: DesignSystem.fontWeightBold
                                color: navActionBtn.navigating ? DesignSystem.accentRuby : "#FFFFFF"
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

            // -----------------------------------------------------------------
            // C. ACTIVE DRIVING MODE MINI CARD (When driving mode is active)
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 90
                radius: DesignSystem.radiusXl
                color: DesignSystem.surfaceCard
                border.color: DesignSystem.borderMuted
                border.width: 1
                visible: root.isDrivingMode // Active driving mode card

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingMd

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "🚘 ROAD FOCUS ACTIVE"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.accentCyan
                            font.letterSpacing: 0.6
                        }

                        Text {
                            text: vm ? vm.destinationTitle : "Mysuru Palace"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeSubtitle
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textPrimary
                            elide: Text.ElideRight
                        }

                        Text {
                            text: (vm ? vm.distanceFormatted : "8.4 km") + " remaining • " + (vm ? vm.etaFormatted : "18 min")
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeCaption
                            font.weight: DesignSystem.fontWeightMedium
                            color: DesignSystem.textSecondary
                        }
                    }

                    // End Navigation quick icon
                    Rectangle {
                        implicitWidth: 40; implicitHeight: 40
                        radius: 20
                        color: DesignSystem.surfaceWell
                        border.color: DesignSystem.borderMuted
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 14
                            color: DesignSystem.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (vm) vm.stopNavigation()
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // D. TRIP METRICS HUD (ETA, Remaining Distance, Arrival Clock)
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 88
                radius: DesignSystem.radiusXl
                color: DesignSystem.surfaceCard
                border.color: DesignSystem.borderMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingSm

                    // ETA Section
                    Column {
                        Layout.preferredWidth: 90
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
                            color: DesignSystem.textMuted
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 38
                        color: DesignSystem.borderMuted
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Distance Section
                    Column {
                        Layout.preferredWidth: 80
                        spacing: 1

                        Text {
                            text: vm ? vm.distanceFormatted : "8.4 km"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeSubtitle
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textPrimary
                        }
                        Text {
                            text: "DISTANCE"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textMuted
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 38
                        color: DesignSystem.borderMuted
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Arrival Clock Section
                    Column {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: vm ? vm.arrivalClockFormatted : "11:00 AM"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeSubtitle
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textPrimary
                        }
                        Text {
                            text: "ARRIVAL"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textMuted
                        }
                    }
                }
            }
        }
    }
}
