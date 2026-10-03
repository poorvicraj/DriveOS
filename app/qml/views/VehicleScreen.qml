import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

Rectangle {
    id: root
    color: "transparent"

    // Helper references to ViewModels
    readonly property var vm: typeof vehicleViewModel !== "undefined" ? vehicleViewModel : null
    readonly property var svm: typeof shellViewModel !== "undefined" ? shellViewModel : null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingLg
        spacing: DesignSystem.spacingMd

        // =====================================================================
        // 1. TOP HEADER & INTERACTIVE VEHICLE STATE RIBBON
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: DesignSystem.spacingMd

            // Left: Title & Subtitle
            Row {
                spacing: DesignSystem.spacingSm
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "VEHICLE & CHASSIS"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    font.letterSpacing: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "• " + (vm ? vm.stateDescription : "Vehicle Overview & Control")
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeBody
                    font.weight: DesignSystem.fontWeightMedium
                    color: DesignSystem.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // Center: Interactive 5-State Selector (PARKED, DRIVING, REVERSE, CHARGING, FAULT)
            VehicleStateSelector {
                Layout.alignment: Qt.AlignVCenter
                currentState: vm ? vm.vehicleState : (svm ? svm.vehicleContextState : "PARKED")
                onStateSelected: function(newState) {
                    if (vm) vm.setVehicleState(newState)
                    if (svm) svm.setVehicleContextState(newState)
                }
            }

            Item { Layout.fillWidth: true }

            // Right: Powertrain & Ignition Status Badges
            Row {
                spacing: DesignSystem.spacingMd
                Layout.alignment: Qt.AlignVCenter

                // Ignition Pill
                Rectangle {
                    implicitHeight: 26
                    implicitWidth: ignRow.implicitWidth + 16
                    radius: DesignSystem.radiusPill
                    color: DesignSystem.surfaceWell
                    border.color: DesignSystem.borderMuted
                    border.width: 1

                    Row {
                        id: ignRow
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: DesignSystem.accentEmerald
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "IGNITION " + (vm ? vm.ignitionState : "ON")
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textSecondary
                            font.letterSpacing: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Health Badge
                Rectangle {
                    implicitHeight: 26
                    implicitWidth: healthRow.implicitWidth + 16
                    radius: DesignSystem.radiusPill
                    color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? Qt.rgba(0.86, 0.15, 0.15, 0.12) : Qt.rgba(0.02, 0.59, 0.41, 0.12)
                    border.color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby : DesignSystem.accentEmerald
                    border.width: 1

                    Row {
                        id: healthRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: (vm && (vm.hasActiveFaults || vm.hasFault)) ? "⚠️" : "●"
                            font.pixelSize: 10
                            color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby : DesignSystem.accentEmerald
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: (vm && (vm.hasActiveFaults || vm.hasFault)) ?
                                  (vm.diagnosticSummary !== "Systems normal" ? vm.diagnosticSummary.toUpperCase() : "TELEMETRY CAUTION") :
                                  "SYSTEMS NORMAL"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby : DesignSystem.accentEmerald
                            font.letterSpacing: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // =====================================================================
        // CONTEXTUAL VEHICLE STATE BANNER (Fault, Charging, Driving notice)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: DesignSystem.radiusMd
            visible: vm && (vm.hasActiveFaults || vm.hasFault || vm.isCharging || vm.isReverse || vm.isDriving)

            color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? Qt.rgba(0.86, 0.15, 0.15, 0.10) :
                   ((vm && vm.isCharging) ? Qt.rgba(0.02, 0.59, 0.41, 0.10) :
                   ((vm && vm.isReverse) ? Qt.rgba(0.85, 0.47, 0.02, 0.10) : Qt.rgba(0.01, 0.52, 0.78, 0.10)))

            border.color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby :
                          ((vm && vm.isCharging) ? DesignSystem.accentEmerald :
                          ((vm && vm.isReverse) ? DesignSystem.accentAmber : DesignSystem.accentCyan))
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: DesignSystem.spacingMd
                anchors.rightMargin: DesignSystem.spacingMd
                spacing: DesignSystem.spacingSm

                Text {
                    text: (vm && (vm.hasActiveFaults || vm.hasFault)) ? "⚠️" :
                          ((vm && vm.isCharging) ? "⚡" :
                          ((vm && vm.isReverse) ? "🔄" : "🚘"))
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: (vm && (vm.hasActiveFaults || vm.hasFault)) ?
                          ("Vehicle Status: ⚠ " + (vm.diagnosticSummary !== "Systems normal" ? vm.diagnosticSummary : "Vehicle data unavailable") + " — Safe degraded mode active.") :
                          ((vm && vm.isCharging) ?
                          "High-Voltage Battery Preconditioning: 45 kW DC Fast Charging active • Battery pack optimal at 25.0°C." :
                          ((vm && vm.isReverse) ?
                          "Reverse Maneuvering Mode: Rear ultrasonic sensors and dynamic trajectory guidelines active." :
                          "Drive Focus Active: Non-essential vehicle configuration settings are locked for road safety."))
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightMedium
                    color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby :
                           ((vm && vm.isCharging) ? DesignSystem.accentEmerald :
                           ((vm && vm.isReverse) ? DesignSystem.accentAmber : DesignSystem.accentCyan))
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    visible: vm && (vm.hasActiveFaults || vm.hasFault)
                    implicitHeight: 24
                    implicitWidth: 84
                    radius: DesignSystem.radiusPill
                    color: bannerClrArea.pressed ? Qt.rgba(0.86, 0.15, 0.15, 0.25) : Qt.rgba(0.86, 0.15, 0.15, 0.15)
                    border.color: DesignSystem.accentRuby
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "Clear DTCs"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.accentRuby
                    }

                    MouseArea {
                        id: bannerClrArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (vm) vm.clearFaults()
                    }
                }
            }
        }

        // =====================================================================
        // SECTION 1: VEHICLE OVERVIEW & STATUS CARD (Visual Hierarchy)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 250
            radius: DesignSystem.radiusXl
            color: DesignSystem.surfaceCard
            border.color: DesignSystem.borderMuted
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: DesignSystem.spacingMd
                spacing: DesignSystem.spacingLg

                // -------------------------------------------------------------
                // LEFT: Interactive Top-Down Chassis Visualization
                // -------------------------------------------------------------
                VehicleChassisCanvas {
                    Layout.preferredWidth: root.width * 0.38
                    Layout.fillHeight: true

                    frontLeftDoorOpen: vm ? vm.frontLeftDoorOpen : false
                    frontRightDoorOpen: vm ? vm.frontRightDoorOpen : false
                    rearLeftDoorOpen: vm ? vm.rearLeftDoorOpen : false
                    rearRightDoorOpen: vm ? vm.rearRightDoorOpen : false
                    autoHeadlights: vm ? vm.autoHeadlights : true
                    doorsLocked: vm ? vm.doorsLocked : true
                    isDriving: vm ? vm.isDriving : false
                    isCharging: vm ? vm.isCharging : false
                    hasFault: vm ? vm.hasFault : false

                    onDoorToggleRequested: function(doorName) {
                        if (vm) vm.toggleDoor(doorName)
                    }
                    onLockToggleRequested: {
                        if (vm) vm.toggleDoorLock()
                    }
                }

                // -------------------------------------------------------------
                // RIGHT: Structured Telemetry Hierarchy
                // -------------------------------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: DesignSystem.spacingSm

                    // 1. Hero Speed, Gear Strip & State Pill
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: DesignSystem.spacingMd

                        // Speed Readout
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: vm ? vm.speedFormatted : "0"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: 44
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textPrimary
                                font.letterSpacing: -1.0
                            }

                            Text {
                                text: "KM/H"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeCaption
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textMuted
                                anchors.baseline: parent.children[0].baseline
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Tactile Transmission Gear Strip
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: ["P", "R", "N", "D"]
                                Rectangle {
                                    width: 32; height: 32; radius: 6
                                    readonly property bool isCurrentGear: (vm ? vm.gear : "P") === modelData
                                    color: isCurrentGear ? DesignSystem.accentCyan : DesignSystem.surfaceWell
                                    border.color: isCurrentGear ? DesignSystem.accentCyan : DesignSystem.borderMuted
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.family: DesignSystem.fontFamily
                                        font.pixelSize: DesignSystem.fontSizeCaption
                                        font.weight: DesignSystem.fontWeightBold
                                        color: parent.isCurrentGear ? "#FFFFFF" : DesignSystem.textMuted
                                    }
                                }
                            }
                        }

                        // Vehicle State Badge
                        Rectangle {
                            implicitHeight: 32
                            implicitWidth: stateBadgeRow.implicitWidth + 20
                            radius: DesignSystem.radiusPill
                            Layout.alignment: Qt.AlignVCenter

                            property string st: vm ? vm.vehicleState : "PARKED"
                            color: st === "FAULT" ? Qt.rgba(0.86, 0.15, 0.15, 0.12) :
                                   (st === "CHARGING" ? Qt.rgba(0.02, 0.59, 0.41, 0.12) :
                                   (st === "REVERSE" ? Qt.rgba(0.85, 0.47, 0.02, 0.12) :
                                   (st === "DRIVING" ? Qt.rgba(0.01, 0.52, 0.78, 0.12) : DesignSystem.surfaceWell)))
                            border.color: st === "FAULT" ? DesignSystem.accentRuby :
                                          (st === "CHARGING" ? DesignSystem.accentEmerald :
                                          (st === "REVERSE" ? DesignSystem.accentAmber :
                                          (st === "DRIVING" ? DesignSystem.accentCyan : DesignSystem.borderMuted)))
                            border.width: 1

                            Row {
                                id: stateBadgeRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: parent.parent.st === "FAULT" ? "⚠️" :
                                          (parent.parent.st === "CHARGING" ? "⚡" :
                                          (parent.parent.st === "REVERSE" ? "🔄" :
                                          (parent.parent.st === "DRIVING" ? "🚘" : "🅿️")))
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: parent.parent.st
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeMicro
                                    font.weight: DesignSystem.fontWeightBold
                                    color: parent.parent.st === "FAULT" ? DesignSystem.accentRuby :
                                           (parent.parent.st === "CHARGING" ? DesignSystem.accentEmerald :
                                           (parent.parent.st === "REVERSE" ? DesignSystem.accentAmber :
                                           (parent.parent.st === "DRIVING" ? DesignSystem.accentCyan : DesignSystem.textSecondary)))
                                    font.letterSpacing: 0.6
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // 2. Battery & Estimated Range Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: DesignSystem.radiusLg
                        color: DesignSystem.surfaceWell
                        border.color: DesignSystem.borderMuted
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: DesignSystem.spacingMd
                            spacing: 6

                            // Label & Metric Values
                            RowLayout {
                                Layout.fillWidth: true

                                Row {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: "🔋"
                                        font.pixelSize: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "HIGH-VOLTAGE ENERGY STORAGE"
                                        font.family: DesignSystem.fontFamily
                                        font.pixelSize: DesignSystem.fontSizeMicro
                                        font.weight: DesignSystem.fontWeightBold
                                        color: DesignSystem.textSecondary
                                        font.letterSpacing: 0.6
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: (vm ? vm.batterySocFormatted : "84%") + " • " + (vm ? vm.rangeKmFormatted : "422 km")
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeBody
                                    font.weight: DesignSystem.fontWeightBold
                                    color: (vm && vm.isCharging) ? DesignSystem.accentEmerald : DesignSystem.textPrimary
                                }
                            }

                            // Dynamic Progress Bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 10
                                radius: 5
                                color: DesignSystem.borderMuted
                                clip: true

                                Rectangle {
                                    width: parent.width * (Math.min(100.0, Math.max(0.0, vm ? vm.batterySoc : 84.0)) / 100.0)
                                    height: parent.height
                                    radius: 5
                                    color: (vm && vm.isCharging) ? DesignSystem.accentEmerald : DesignSystem.accentCyan

                                    Behavior on width {
                                        NumberAnimation { duration: DesignSystem.durationNormal; easing.type: Easing.OutCubic }
                                    }
                                }
                            }

                            // Subtitle Metadata
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Pack Temp: " + (vm ? vm.batteryTemperatureFormatted : "24.5°C") + " • Health: 99.2%"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeMicro
                                    font.weight: DesignSystem.fontWeightMedium
                                    color: DesignSystem.textMuted
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: (vm && vm.doorsAllClosed) ? "✓ Closures Sealed" : "⚠️ Closure Open"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeMicro
                                    font.weight: DesignSystem.fontWeightBold
                                    color: (vm && vm.doorsAllClosed) ? DesignSystem.accentEmerald : DesignSystem.accentAmber
                                }
                            }

                            // Driver-facing Vehicle Status & Diagnostics
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Row {
                                    spacing: 5
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        text: (vm && (vm.hasActiveFaults || vm.hasFault)) ? "⚠" : "●"
                                        font.pixelSize: 10
                                        font.weight: DesignSystem.fontWeightBold
                                        color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby : DesignSystem.accentEmerald
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "Status: "
                                        font.family: DesignSystem.fontFamily
                                        font.pixelSize: DesignSystem.fontSizeMicro
                                        font.weight: DesignSystem.fontWeightBold
                                        color: DesignSystem.textSecondary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: (vm && (vm.hasActiveFaults || vm.hasFault)) ?
                                              vm.diagnosticSummary :
                                              "Systems normal"
                                        font.family: DesignSystem.fontFamily
                                        font.pixelSize: DesignSystem.fontSizeMicro
                                        font.weight: DesignSystem.fontWeightBold
                                        color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby : DesignSystem.accentEmerald
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: diagDrawer.expanded ? "Hide Debug ▲" : "DTC Tools ▼"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeMicro
                                    font.weight: DesignSystem.fontWeightBold
                                    color: DesignSystem.accentCyan

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: diagDrawer.expanded = !diagDrawer.expanded
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // SECTION 2: FOCUSED SETTINGS (Drive Mode, Lighting, Doors, Display)
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            spacing: DesignSystem.spacingLg

            // -----------------------------------------------------------------
            // CARD A: DRIVE MODE DYNAMICS (Comfort, Eco, Sport)
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.width * 0.33
                radius: DesignSystem.radiusXl
                color: DesignSystem.surfaceCard
                border.color: DesignSystem.borderMuted
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingSm

                    // Header
                    RowLayout {
                        Layout.fillWidth: true

                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "⚡"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "DRIVE DYNAMICS"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textSecondary
                                font.letterSpacing: 0.8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Restriction indicator if vehicle is in motion
                        Rectangle {
                            implicitHeight: 22
                            implicitWidth: restrRowA.implicitWidth + 12
                            radius: DesignSystem.radiusPill
                            visible: vm ? vm.isRestricted : false
                            color: Qt.rgba(0.85, 0.47, 0.02, 0.12)
                            border.color: DesignSystem.accentAmber
                            border.width: 1

                            Row {
                                id: restrRowA
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "🔒"
                                    font.pixelSize: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Unavailable while driving"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: 9
                                    font.weight: DesignSystem.fontWeightBold
                                    color: DesignSystem.accentAmber
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Text {
                            text: vm ? vm.driveMode : "COMFORT"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeCaption
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.accentCyan
                            visible: !(vm && vm.isRestricted)
                        }
                    }

                    // 3 Tactile Drive Mode Buttons
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        DriveModeButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            modeName: "ECO"
                            iconText: "🍃"
                            sublabel: "Smooth throttle • Range focus"
                            isSelected: (vm ? vm.driveMode : "COMFORT") === "ECO"
                            isRestricted: vm ? vm.isRestricted : false
                            onClicked: if (vm) vm.setDriveMode("ECO")
                        }

                        DriveModeButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            modeName: "COMFORT"
                            iconText: "🛡️"
                            sublabel: "Balanced chassis • Effortless ride"
                            isSelected: (vm ? vm.driveMode : "COMFORT") === "COMFORT"
                            isRestricted: vm ? vm.isRestricted : false
                            onClicked: if (vm) vm.setDriveMode("COMFORT")
                        }

                        DriveModeButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            modeName: "SPORT"
                            iconText: "⚡"
                            sublabel: "Instant torque • Stiff damping"
                            isSelected: (vm ? vm.driveMode : "COMFORT") === "SPORT"
                            isRestricted: vm ? vm.isRestricted : false
                            onClicked: if (vm) vm.setDriveMode("SPORT")
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // CARD B: LIGHTING & ACCESS CLOSURES (Auto Headlights, Auto Lock, One-Pedal)
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.width * 0.35
                radius: DesignSystem.radiusXl
                color: DesignSystem.surfaceCard
                border.color: DesignSystem.borderMuted
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingSm

                    // Header
                    RowLayout {
                        Layout.fillWidth: true

                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "💡"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "LIGHTING & ACCESS"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textSecondary
                                font.letterSpacing: 0.8
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Restriction indicator if vehicle is in motion
                        Rectangle {
                            implicitHeight: 22
                            implicitWidth: restrRow.implicitWidth + 12
                            radius: DesignSystem.radiusPill
                            visible: vm ? vm.isRestricted : false
                            color: Qt.rgba(0.85, 0.47, 0.02, 0.12)
                            border.color: DesignSystem.accentAmber
                            border.width: 1

                            Row {
                                id: restrRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "🔒"
                                    font.pixelSize: 9
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Unavailable while driving"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: 9
                                    font.weight: DesignSystem.fontWeightBold
                                    color: DesignSystem.accentAmber
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Toggles List
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6
                        opacity: (vm && vm.isRestricted) ? 0.50 : 1.0

                        VehicleSettingToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            label: "Auto Headlights"
                            sublabel: "Adaptive Matrix LED twilight assist"
                            iconText: "💡"
                            isChecked: vm ? vm.autoHeadlights : true
                            isRestricted: vm ? vm.isRestricted : false
                            onToggleRequested: if (vm) vm.toggleAutoHeadlights()
                        }

                        VehicleSettingToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            label: "Walk-Away Auto Lock"
                            sublabel: "Lock all doors automatically on exit"
                            iconText: "🔐"
                            isChecked: vm ? vm.autoLock : true
                            isRestricted: vm ? vm.isRestricted : false
                            onToggleRequested: if (vm) vm.toggleAutoLock()
                        }

                        VehicleSettingToggle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            label: "One-Pedal Drive"
                            sublabel: "Enhanced regenerative stop hold"
                            iconText: "🦶"
                            isChecked: vm ? vm.onePedalDrive : true
                            isRestricted: vm ? vm.isRestricted : false
                            onToggleRequested: if (vm) vm.toggleOnePedalDrive()
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // CARD C: DISPLAY BRIGHTNESS & AMBIENCE (Luminance Slider)
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.width * 0.32
                radius: DesignSystem.radiusXl
                color: DesignSystem.surfaceCard
                border.color: DesignSystem.borderMuted
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingSm

                    // Header
                    RowLayout {
                        Layout.fillWidth: true

                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "☀️"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "DISPLAY & AMBIENCE"
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
                            text: (vm ? vm.displayBrightness : 85) + "%"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeCaption
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.accentCyan
                        }
                    }

                    // Brightness Description
                    Text {
                        text: "Cockpit Center Display Luminance"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textSecondary
                    }

                    Item { Layout.fillHeight: true }

                    // Tactile Stepper + Slider Interaction Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: DesignSystem.spacingSm

                        // Minus Button
                        Rectangle {
                            implicitWidth: 44; implicitHeight: 44
                            radius: 22
                            color: minusArea.pressed ? DesignSystem.surfaceWell : DesignSystem.surface
                            border.color: minusArea.containsMouse ? DesignSystem.accentCyan : DesignSystem.borderHighlight
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "−"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: 22
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textPrimary
                            }

                            MouseArea {
                                id: minusArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: if (vm) vm.adjustDisplayBrightness(-5)
                            }
                        }

                        // Progress Slider Bar
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 14
                            radius: 7
                            color: DesignSystem.surfaceWell
                            border.color: DesignSystem.borderMuted
                            border.width: 1
                            clip: true

                            Rectangle {
                                width: parent.width * ((vm ? vm.displayBrightness : 85) / 100.0)
                                height: parent.height
                                radius: 7
                                color: DesignSystem.accentCyan

                                Behavior on width {
                                    NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: function(mouse) {
                                    var pct = Math.round((mouse.x / width) * 100.0);
                                    if (vm) vm.setDisplayBrightness(pct);
                                }
                            }
                        }

                        // Plus Button
                        Rectangle {
                            implicitWidth: 44; implicitHeight: 44
                            radius: 22
                            color: plusArea.pressed ? DesignSystem.surfaceWell : DesignSystem.surface
                            border.color: plusArea.containsMouse ? DesignSystem.accentCyan : DesignSystem.borderHighlight
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: 20
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textPrimary
                            }

                            MouseArea {
                                id: plusArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: if (vm) vm.adjustDisplayBrightness(5)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Subtitle Note
                    Text {
                        text: "Luminance adapts automatically to ambient cockpit twilight sensors."
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textMuted
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // =====================================================================
        // SECTION 3: COMPACT DEVELOPER DIAGNOSTICS & FAULT SIMULATION
        // =====================================================================
        Rectangle {
            id: diagDrawer
            property bool expanded: false
            Layout.fillWidth: true
            implicitHeight: expanded ? 78 : 0
            visible: expanded
            clip: true
            radius: DesignSystem.radiusLg
            color: DesignSystem.surfaceCard
            border.color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby : DesignSystem.borderMuted
            border.width: 1

            Behavior on implicitHeight {
                NumberAnimation { duration: DesignSystem.durationNormal; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: DesignSystem.spacingSm
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "🛠️ DIAGNOSTICS & FAULT INJECTION (UDS Prototype — In-Memory DTC Store)"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.textSecondary
                        font.letterSpacing: 0.5
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: (vm && (vm.hasActiveFaults || vm.hasFault)) ?
                              ("Active DTC: " + vm.diagnosticSummary) :
                              "● Systems normal — No active trouble codes"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentRuby : DesignSystem.accentEmerald
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Fault Injection Buttons
                    Repeater {
                        model: [
                            { name: "HVAC Timeout", key: "HVAC_SENSOR_TIMEOUT" },
                            { name: "Data Timeout", key: "VEHICLE_DATA_TIMEOUT" },
                            { name: "Door Fault", key: "DOOR_SENSOR_FAULT" },
                            { name: "CAN Timeout", key: "CAN_TIMEOUT" },
                            { name: "Invalid Signal", key: "INVALID_VEHICLE_SIGNAL" }
                        ]

                        Rectangle {
                            implicitHeight: 24
                            implicitWidth: injText.implicitWidth + 14
                            radius: DesignSystem.radiusPill
                            color: injArea.pressed ? DesignSystem.surfaceWell : DesignSystem.surface
                            border.color: injArea.containsMouse ? DesignSystem.accentCyan : DesignSystem.borderMuted
                            border.width: 1

                            Text {
                                id: injText
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightMedium
                                color: DesignSystem.textPrimary
                            }

                            MouseArea {
                                id: injArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (vm) vm.injectFault(modelData.key)
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Clear & Recovery Button
                    Rectangle {
                        implicitHeight: 24
                        implicitWidth: rstText.implicitWidth + 16
                        radius: DesignSystem.radiusPill
                        color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? Qt.rgba(0.02, 0.59, 0.41, 0.15) : DesignSystem.surfaceWell
                        border.color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentEmerald : DesignSystem.borderMuted
                        border.width: 1

                        Text {
                            id: rstText
                            anchors.centerIn: parent
                            text: "✓ Clear DTCs & Restore"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: (vm && (vm.hasActiveFaults || vm.hasFault)) ? DesignSystem.accentEmerald : DesignSystem.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (vm) vm.clearFaults()
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // INLINE SUB-COMPONENTS
    // =========================================================================

    // Component: Drive Mode Selector Button
    component DriveModeButton: Rectangle {
        id: dBtn
        property string modeName: "COMFORT"
        property string iconText: "🛡️"
        property string sublabel: ""
        property bool isSelected: false
        property bool isRestricted: false
        signal clicked()

        radius: DesignSystem.radiusMd
        color: isSelected ? Qt.rgba(0.01, 0.52, 0.78, 0.12) :
               (btnArea.pressed ? DesignSystem.surfaceWell :
               (btnArea.containsMouse ? DesignSystem.surfaceElevated : DesignSystem.surfaceWell))
        border.color: isSelected ? DesignSystem.accentCyan : DesignSystem.borderMuted
        border.width: isSelected ? 1.5 : 1
        scale: btnArea.pressed ? 0.97 : 1.0

        Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }
        Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacingSm
            spacing: DesignSystem.spacingSm

            Text {
                text: dBtn.iconText
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    spacing: 4
                    Text {
                        text: dBtn.modeName
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeBody
                        font.weight: DesignSystem.fontWeightBold
                        color: dBtn.isSelected ? DesignSystem.accentCyan : DesignSystem.textPrimary
                        font.letterSpacing: 0.5
                    }

                    Text {
                        text: "🔒"
                        font.pixelSize: 10
                        visible: dBtn.isRestricted
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Text {
                    text: dBtn.isRestricted ? "Unavailable while driving" : dBtn.sublabel
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeMicro
                    font.weight: DesignSystem.fontWeightMedium
                    color: dBtn.isRestricted ? DesignSystem.accentAmber : DesignSystem.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Radio Indicator Dot
            Rectangle {
                width: 14; height: 14; radius: 7
                color: dBtn.isSelected ? DesignSystem.accentCyan : "transparent"
                border.color: dBtn.isSelected ? DesignSystem.accentCyan : DesignSystem.borderHighlight
                border.width: 1.5
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 6; height: 6; radius: 3
                    color: "#FFFFFF"
                    visible: dBtn.isSelected
                }
            }
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: dBtn.isRestricted ? Qt.ForbiddenCursor : Qt.PointingHandCursor
            onClicked: {
                if (dBtn.isRestricted) {
                    if (vm) vm.restrictionNoticeTriggered("Unavailable while driving", "Drive dynamics cannot be adjusted while driving.");
                    return;
                }
                dBtn.clicked()
            }
        }
    }

    // Component: Vehicle Setting Toggle Switch (>=48dp touch height)
    component VehicleSettingToggle: Rectangle {
        id: sTog
        property string label: "Auto Headlights"
        property string sublabel: ""
        property string iconText: "💡"
        property bool isChecked: true
        property bool isRestricted: false
        signal toggleRequested()

        radius: DesignSystem.radiusMd
        color: togArea.pressed ? DesignSystem.surfaceWell : DesignSystem.surfaceWell
        border.color: DesignSystem.borderMuted
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacingSm
            spacing: DesignSystem.spacingSm

            Text {
                text: sTog.iconText
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    spacing: 4
                    Text {
                        text: sTog.label
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.textPrimary
                    }

                    Text {
                        text: "🔒"
                        font.pixelSize: 10
                        visible: sTog.isRestricted
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                Text {
                    text: sTog.isRestricted ? "Unavailable while driving" : sTog.sublabel
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeMicro
                    font.weight: DesignSystem.fontWeightMedium
                    color: sTog.isRestricted ? DesignSystem.accentAmber : DesignSystem.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Visual Toggle Switch
            Rectangle {
                width: 44; height: 26; radius: 13
                color: sTog.isRestricted ? DesignSystem.borderHighlight : (sTog.isChecked ? DesignSystem.accentCyan : DesignSystem.borderHighlight)
                Layout.alignment: Qt.AlignVCenter
                opacity: sTog.isRestricted ? 0.6 : 1.0

                Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }

                Rectangle {
                    width: 20; height: 20; radius: 10
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                    x: sTog.isChecked ? 21 : 3

                    Behavior on x {
                        NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad }
                    }
                }
            }
        }

        MouseArea {
            id: togArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: sTog.isRestricted ? Qt.ForbiddenCursor : Qt.PointingHandCursor
            onClicked: {
                if (sTog.isRestricted) {
                    if (vm) vm.restrictionNoticeTriggered("Unavailable while driving", "This configuration setting is locked while in motion for road safety.");
                    return;
                }
                sTog.toggleRequested()
            }
        }
    }
}
