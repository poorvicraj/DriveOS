import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

Rectangle {
    id: root
    color: "transparent"

    // Helper references to ViewModels
    readonly property var vm: typeof climateViewModel !== "undefined" ? climateViewModel : null
    readonly property var svm: typeof shellViewModel !== "undefined" ? shellViewModel : null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingLg
        spacing: DesignSystem.spacingMd

        // =====================================================================
        // 1. TOP HEADER & CONTEXT RIBBON
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: DesignSystem.spacingMd

            // Left: Screen Title & Subtitle
            Row {
                spacing: DesignSystem.spacingSm
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "CLIMATE CONTROL"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    font.letterSpacing: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "• Dual-Zone Intelligent Thermal Management"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeBody
                    font.weight: DesignSystem.fontWeightMedium
                    color: DesignSystem.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // Center: Vehicle State Context Badge
            Rectangle {
                implicitHeight: 30
                implicitWidth: contextRow.implicitWidth + 24
                radius: DesignSystem.radiusPill
                Layout.alignment: Qt.AlignVCenter

                property string curState: svm ? svm.vehicleContextState : "PARKED"

                color: curState === "FAULT" ? Qt.rgba(0.86, 0.15, 0.15, 0.12) :
                       (curState === "CHARGING" ? Qt.rgba(0.02, 0.59, 0.41, 0.12) :
                       (curState === "DRIVING" ? Qt.rgba(0.01, 0.52, 0.78, 0.12) : DesignSystem.surfaceWell))

                border.color: curState === "FAULT" ? DesignSystem.accentRuby :
                              (curState === "CHARGING" ? DesignSystem.accentEmerald :
                              (curState === "DRIVING" ? DesignSystem.accentCyan : DesignSystem.borderMuted))
                border.width: 1

                Row {
                    id: contextRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: parent.parent.curState === "FAULT" ? "⚠️" :
                              (parent.parent.curState === "CHARGING" ? "⚡" :
                              (parent.parent.curState === "DRIVING" ? "🚘" : "🅿️"))
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: parent.parent.curState === "FAULT" ? "HVAC FAULT SAFE-MODE" :
                              (parent.parent.curState === "CHARGING" ? "PRE-CONDITIONING (GRID)" :
                              (parent.parent.curState === "DRIVING" ? "DRIVE FOCUS" : "PARKED • FULL ACCESS"))
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: parent.parent.curState === "FAULT" ? DesignSystem.accentRuby :
                               (parent.parent.curState === "CHARGING" ? DesignSystem.accentEmerald :
                               (parent.parent.curState === "DRIVING" ? DesignSystem.accentCyan : DesignSystem.textSecondary))
                        font.letterSpacing: 0.6
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Right: Ambient Weather Info
            Row {
                spacing: DesignSystem.spacingMd
                Layout.alignment: Qt.AlignVCenter

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "🌤️"
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Outside " + (vm ? vm.outsideTemperatureFormatted : "19°C")
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: 1
                    height: 16
                    color: DesignSystem.borderHighlight
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Humidity 45%"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightMedium
                    color: DesignSystem.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // =====================================================================
        // CONTEXTUAL VEHICLE STATE BANNER (Fault / Charging / Driving notice)
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            radius: DesignSystem.radiusMd
            visible: svm && (svm.vehicleContextState === "FAULT" || svm.vehicleContextState === "CHARGING")

            color: (svm && svm.vehicleContextState === "FAULT") ?
                   Qt.rgba(0.86, 0.15, 0.15, 0.10) : Qt.rgba(0.02, 0.59, 0.41, 0.10)
            border.color: (svm && svm.vehicleContextState === "FAULT") ?
                          DesignSystem.accentRuby : DesignSystem.accentEmerald
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: DesignSystem.spacingMd
                anchors.rightMargin: DesignSystem.spacingMd
                spacing: DesignSystem.spacingSm

                Text {
                    text: (svm && svm.vehicleContextState === "FAULT") ? "⚠️" : "⚡"
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: (svm && svm.vehicleContextState === "FAULT") ?
                          "System Notice: Climate Sensor Fault detected — System operating in safe thermal fallback. Manual fan speed & defrost overrides remain functional." :
                          "High-Voltage Battery Preconditioning: Cabin comfort maintained via external charging grid to protect driving range."
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightMedium
                    color: (svm && svm.vehicleContextState === "FAULT") ?
                           DesignSystem.accentRuby : DesignSystem.accentEmerald
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // =====================================================================
        // 2. PRIMARY HVAC TOGGLES BAR (Large Touch Buttons >= 48dp)
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: DesignSystem.spacingSm

            // 1. A/C Button
            HvacPillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                label: "A/C"
                sublabel: "Compressor"
                iconText: "❄️"
                isActive: vm ? vm.isAcActive : true
                activeAccent: DesignSystem.accentCyan
                onClicked: if (vm) vm.toggleAc()
            }

            // 2. AUTO Mode Button
            HvacPillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                label: "AUTO"
                sublabel: "Climate"
                iconText: "⚡"
                isActive: vm ? vm.isAutoMode : true
                activeAccent: DesignSystem.accentCyan
                onClicked: if (vm) vm.toggleAuto()
            }

            // 3. DUAL-ZONE SYNC Button
            HvacPillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                label: "SYNC"
                sublabel: "Dual-Zone"
                iconText: "⮂⮄"
                isActive: vm ? vm.isSyncActive : true
                activeAccent: DesignSystem.accentCyan
                onClicked: if (vm) vm.toggleSync()
            }

            // 4. AIR RECIRCULATION Button
            HvacPillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                label: "RECIRC"
                sublabel: "Interior Filter"
                iconText: "🔄"
                isActive: vm ? vm.isRecirculation : false
                activeAccent: DesignSystem.accentEmerald
                onClicked: if (vm) vm.toggleRecirculation()
            }

            // 5. MAX FRONT DEFROST Button
            HvacPillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                label: "FRONT"
                sublabel: "Max Defrost"
                iconText: "🪟"
                isActive: vm ? vm.isFrontDefrost : false
                activeAccent: DesignSystem.accentAmber
                onClicked: if (vm) vm.toggleFrontDefrost()
            }

            // 6. REAR DEFROST Button
            HvacPillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                label: "REAR"
                sublabel: "Heated Glass"
                iconText: "♨"
                isActive: vm ? vm.isRearDefrost : false
                activeAccent: DesignSystem.accentAmber
                onClicked: if (vm) vm.toggleRearDefrost()
            }
        }

        // =====================================================================
        // 3. MAIN COCKPIT WORKSPACE (Hero Control Left, Visualization & Flow Right)
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: DesignSystem.spacingLg

            // -----------------------------------------------------------------
            // LEFT COLUMN (~52%): Dominant Hero Temperature + Heated Seats
            // -----------------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.width * 0.52
                spacing: DesignSystem.spacingMd

                // Hero Central Temperature Control
                HeroTemperatureControl {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    cabinTemperature: vm ? vm.cabinTemperature : 21.5
                    cabinTemperatureFormatted: vm ? vm.cabinTemperatureFormatted : "21.5°C"
                    targetTemperature: vm ? vm.targetTemperature : 22.0
                    targetTemperatureFormatted: vm ? vm.targetTemperatureFormatted : "22.0°"
                    passengerTemperature: vm ? vm.passengerTemperature : 22.0
                    passengerTemperatureFormatted: vm ? vm.passengerTemperatureFormatted : "22.0°"

                    isHeating: vm ? vm.isHeating : false
                    isCooling: vm ? vm.isCooling : true
                    isSyncActive: vm ? vm.isSyncActive : true
                    isAcActive: vm ? vm.isAcActive : true

                    onIncreaseRequested: if (vm) vm.adjustTargetTemperature(0.5)
                    onDecreaseRequested: if (vm) vm.adjustTargetTemperature(-0.5)
                    onPassengerIncreaseRequested: if (vm) vm.adjustPassengerTemperature(0.5)
                    onPassengerDecreaseRequested: if (vm) vm.adjustPassengerTemperature(-0.5)
                    onSyncToggled: if (vm) vm.toggleSync()
                }

                // 3-Stage Driver & Passenger Heated Seats Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: DesignSystem.radiusXl
                    color: DesignSystem.surfaceCard
                    border.color: DesignSystem.borderMuted
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: DesignSystem.spacingMd
                        spacing: DesignSystem.spacingLg

                        // Driver Heated Seat Control
                        HeatedSeatButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            seatTitle: "DRIVER SEAT"
                            heatLevel: vm ? vm.driverSeatHeat : 0
                            onClicked: if (vm) vm.cycleDriverSeatHeat()
                        }

                        // Vertical Separator
                        Rectangle {
                            width: 1
                            Layout.fillHeight: true
                            color: DesignSystem.borderMuted
                        }

                        // Passenger Heated Seat Control
                        HeatedSeatButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            seatTitle: "PASSENGER SEAT"
                            heatLevel: vm ? vm.passengerSeatHeat : 0
                            onClicked: if (vm) vm.cyclePassengerSeatHeat()
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // RIGHT COLUMN (~48%): Cabin Airflow Canvas + Direction & Fan Speed
            // -----------------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: root.width * 0.48
                spacing: DesignSystem.spacingMd

                // Interactive Automotive Airflow Visualization
                ClimateAirflowCanvas {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    fanSpeed: vm ? vm.fanSpeed : 2
                    airflowMode: vm ? vm.airflowMode : "vent"
                    isHeating: vm ? vm.isHeating : false
                    isCooling: vm ? vm.isCooling : true
                    isAcActive: vm ? vm.isAcActive : true
                    isFrontDefrost: vm ? vm.isFrontDefrost : false
                    isRearDefrost: vm ? vm.isRearDefrost : false
                    cabinTemperatureFormatted: vm ? vm.cabinTemperatureFormatted : "21.5°C"
                    targetTemperatureFormatted: vm ? vm.targetTemperatureFormatted : "22.0°"
                }

                // Airflow Direction Selector Bar (4 Large Modes)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: DesignSystem.radiusLg
                    color: DesignSystem.surfaceCard
                    border.color: DesignSystem.borderMuted
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        AirflowModeTab {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconText: "🪟"
                            modeName: "WINDSHIELD"
                            isSelected: vm ? (vm.airflowMode === "windshield") : false
                            onClicked: if (vm) vm.setAirflowMode("windshield")
                        }

                        AirflowModeTab {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconText: "💨"
                            modeName: "DASH VENTS"
                            isSelected: vm ? (vm.airflowMode === "vent") : true
                            onClicked: if (vm) vm.setAirflowMode("vent")
                        }

                        AirflowModeTab {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconText: "🦶"
                            modeName: "FOOTWELL"
                            isSelected: vm ? (vm.airflowMode === "floor") : false
                            onClicked: if (vm) vm.setAirflowMode("floor")
                        }

                        AirflowModeTab {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            iconText: "🔀"
                            modeName: "BI-LEVEL"
                            isSelected: vm ? (vm.airflowMode === "bilevel") : false
                            onClicked: if (vm) vm.setAirflowMode("bilevel")
                        }
                    }
                }

                // Tactile Blower Fan Speed Multi-Segment Control
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 96
                    radius: DesignSystem.radiusXl
                    color: DesignSystem.surfaceCard
                    border.color: DesignSystem.borderMuted
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: DesignSystem.spacingMd
                        spacing: DesignSystem.spacingSm

                        // Header: Title & Active Level Readout
                        RowLayout {
                            Layout.fillWidth: true

                            Row {
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "🌀"
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "BLOWER FAN SPEED"
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
                                text: vm ? vm.fanSpeedFormatted : "Level 2"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeCaption
                                font.weight: DesignSystem.fontWeightBold
                                color: (vm && vm.fanSpeed > 0) ? DesignSystem.accentCyan : DesignSystem.textMuted
                            }
                        }

                        // 6-Segment Tactile Fan Selector (0 / Off, 1, 2, 3, 4, 5)
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 6

                            // Off Segment
                            FanSegmentButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                label: "OFF"
                                levelValue: 0
                                currentLevel: vm ? vm.fanSpeed : 2
                                onSelected: if (vm) vm.setFanSpeedLevel(0)
                            }

                            // Levels 1 to 5
                            Repeater {
                                model: 5
                                FanSegmentButton {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    label: "" + (index + 1)
                                    levelValue: index + 1
                                    currentLevel: vm ? vm.fanSpeed : 2
                                    onSelected: if (vm) vm.setFanSpeedLevel(index + 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // INLINE SUB-COMPONENTS (Clean encapsulation without clutter)
    // =========================================================================

    // Component: HVAC Primary Pill Toggle Button (>=48dp height)
    component HvacPillButton: Rectangle {
        id: pillBtn
        property string label: "A/C"
        property string sublabel: ""
        property string iconText: "❄️"
        property bool isActive: false
        property color activeAccent: DesignSystem.accentCyan
        signal clicked()

        radius: DesignSystem.radiusMd
        color: isActive ? activeAccent :
               (pillArea.pressed ? DesignSystem.surfaceWell :
               (pillArea.containsMouse ? DesignSystem.surfaceElevated : DesignSystem.surfaceCard))
        border.color: isActive ? activeAccent :
                      (pillArea.containsMouse ? DesignSystem.borderHighlight : DesignSystem.borderMuted)
        border.width: 1.5
        scale: pillArea.pressed ? 0.96 : 1.0

        Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }
        Behavior on border.color { ColorAnimation { duration: DesignSystem.durationFast } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: pillBtn.iconText
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: pillBtn.label
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeBody
                    font.weight: DesignSystem.fontWeightBold
                    color: pillBtn.isActive ? "#FFFFFF" : DesignSystem.textPrimary
                    font.letterSpacing: 0.6
                }

                Text {
                    text: pillBtn.sublabel
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: 10
                    font.weight: DesignSystem.fontWeightMedium
                    color: pillBtn.isActive ? Qt.rgba(1, 1, 1, 0.85) : DesignSystem.textMuted
                    visible: pillBtn.sublabel.length > 0
                }
            }
        }

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pillBtn.clicked()
        }
    }

    // Component: 3-Stage Heated Seat Selector
    component HeatedSeatButton: Rectangle {
        id: seatBtn
        property string seatTitle: "DRIVER SEAT"
        property int heatLevel: 0 // 0: Off, 1: Low, 2: Med, 3: High
        signal clicked()

        radius: DesignSystem.radiusLg
        color: seatArea.pressed ? DesignSystem.surfaceWell :
               (seatArea.containsMouse ? DesignSystem.surfaceElevated : DesignSystem.surfaceWell)
        border.color: heatLevel > 0 ? DesignSystem.accentAmber : DesignSystem.borderMuted
        border.width: heatLevel > 0 ? 1.5 : 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: DesignSystem.spacingSm
            spacing: DesignSystem.spacingMd

            // Left: Seat Graphic Icon
            Text {
                text: "💺"
                font.pixelSize: 22
                Layout.alignment: Qt.AlignVCenter
            }

            // Center: Title & Level Description
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: seatBtn.seatTitle
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeMicro
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textSecondary
                    font.letterSpacing: 0.6
                }

                Text {
                    text: seatBtn.heatLevel === 0 ? "HEAT OFF" :
                          (seatBtn.heatLevel === 1 ? "STAGE 1 • LOW" :
                          (seatBtn.heatLevel === 2 ? "STAGE 2 • MED" : "STAGE 3 • HIGH"))
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightBold
                    color: seatBtn.heatLevel > 0 ? DesignSystem.accentAmber : DesignSystem.textMuted
                }
            }

            // Right: 3-Bar Heated LED Indicator
            Row {
                spacing: 3
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: 3
                    Rectangle {
                        width: 8
                        height: 18
                        radius: 3
                        color: index < seatBtn.heatLevel ? DesignSystem.accentAmber : DesignSystem.borderHighlight
                        border.color: index < seatBtn.heatLevel ? DesignSystem.accentAmber : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }
                    }
                }
            }
        }

        MouseArea {
            id: seatArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: seatBtn.clicked()
        }
    }

    // Component: Airflow Direction Selector Tab
    component AirflowModeTab: Rectangle {
        id: modeTab
        property string iconText: "💨"
        property string modeName: "DASH VENTS"
        property bool isSelected: false
        signal clicked()

        radius: DesignSystem.radiusMd
        color: isSelected ? DesignSystem.accentCyan :
               (tabArea.pressed ? DesignSystem.surfaceWell :
               (tabArea.containsMouse ? DesignSystem.surfaceWell : "transparent"))
        scale: tabArea.pressed ? 0.96 : 1.0

        Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }
        Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: modeTab.iconText
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: modeTab.modeName
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeMicro
                font.weight: DesignSystem.fontWeightBold
                color: modeTab.isSelected ? "#FFFFFF" : DesignSystem.textPrimary
                font.letterSpacing: 0.5
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: tabArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: modeTab.clicked()
        }
    }

    // Component: Blower Fan Speed Segment Button
    component FanSegmentButton: Rectangle {
        id: fanSeg
        property string label: "1"
        property int levelValue: 1
        property int currentLevel: 2
        signal selected()

        readonly property bool isLevelActive: levelValue === 0 ? (currentLevel === 0) : (currentLevel >= levelValue)
        readonly property bool isCurrentExact: currentLevel === levelValue

        radius: DesignSystem.radiusSm
        color: isCurrentExact ? DesignSystem.accentCyan :
               (isLevelActive ? Qt.rgba(0.01, 0.52, 0.78, 0.22) : DesignSystem.surfaceWell)
        border.color: isCurrentExact ? DesignSystem.accentCyan :
                      (isLevelActive ? Qt.rgba(0.01, 0.52, 0.78, 0.40) : DesignSystem.borderMuted)
        border.width: isCurrentExact ? 1.5 : 1
        scale: fanArea.pressed ? 0.95 : 1.0

        Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }
        Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad } }

        Text {
            anchors.centerIn: parent
            text: fanSeg.label
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeCaption
            font.weight: DesignSystem.fontWeightBold
            color: fanSeg.isCurrentExact ? "#FFFFFF" :
                   (fanSeg.isLevelActive ? DesignSystem.accentCyan : DesignSystem.textMuted)
        }

        MouseArea {
            id: fanArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fanSeg.selected()
        }
    }
}
