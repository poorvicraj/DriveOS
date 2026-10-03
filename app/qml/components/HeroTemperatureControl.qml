import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    // =========================================================================
    // PROPERTIES
    // =========================================================================
    property real cabinTemperature: 21.5
    property string cabinTemperatureFormatted: "21.5°C"
    property real targetTemperature: 22.0
    property string targetTemperatureFormatted: "22.0°"
    property real passengerTemperature: 22.0
    property string passengerTemperatureFormatted: "22.0°"

    property real minTemperature: 16.0
    property real maxTemperature: 28.0
    property real step: 0.5

    property bool isHeating: targetTemperature > cabinTemperature
    property bool isCooling: targetTemperature < cabinTemperature
    property bool isSyncActive: true
    property bool isAcActive: true
    property bool isRestricted: false

    // Signals for UI interactions
    signal increaseRequested()
    signal decreaseRequested()
    signal passengerIncreaseRequested()
    signal passengerDecreaseRequested()
    signal syncToggled()

    implicitWidth: 440
    implicitHeight: 320
    radius: DesignSystem.radiusXl
    color: DesignSystem.surfaceCard
    border.color: isHeating ? Qt.rgba(0.85, 0.47, 0.02, 0.35) :
                  (isCooling ? Qt.rgba(0.01, 0.52, 0.78, 0.35) : DesignSystem.borderMuted)
    border.width: 1.5
    clip: true

    Behavior on border.color {
        ColorAnimation { duration: DesignSystem.durationNormal }
    }

    // =========================================================================
    // SUBTLE THERMAL ATMOSPHERE GLOW
    // =========================================================================
    Rectangle {
        id: thermalHalo
        anchors.centerIn: parent
        width: parent.width * 0.85
        height: parent.height * 0.85
        radius: width * 0.5
        opacity: 0.85

        color: root.isHeating ? Qt.rgba(0.85, 0.47, 0.02, 0.07) :
               (root.isCooling ? Qt.rgba(0.01, 0.52, 0.78, 0.07) : Qt.rgba(0.39, 0.45, 0.55, 0.04))

        Behavior on color {
            ColorAnimation { duration: DesignSystem.durationSlow }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingLg
        spacing: DesignSystem.spacingSm

        // =====================================================================
        // HEADER: Cabin Temp Badge & Thermal Status Indicator
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingSm

            // Current Cabin Temperature Pill
            Rectangle {
                implicitHeight: 28
                implicitWidth: cabinRow.implicitWidth + 20
                radius: DesignSystem.radiusPill
                color: DesignSystem.surfaceWell
                border.color: DesignSystem.borderMuted
                border.width: 1

                Row {
                    id: cabinRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "🌡️"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "CABIN " + root.cabinTemperatureFormatted
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.textSecondary
                        font.letterSpacing: 0.6
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Dynamic Thermal State Pill (Heating / Cooling / Balanced)
            Rectangle {
                implicitHeight: 26
                implicitWidth: thermalText.implicitWidth + 16
                radius: DesignSystem.radiusPill
                color: root.isHeating ? Qt.rgba(0.85, 0.47, 0.02, 0.12) :
                       (root.isCooling ? Qt.rgba(0.01, 0.52, 0.78, 0.12) : Qt.rgba(0.39, 0.45, 0.55, 0.10))
                border.color: root.isHeating ? Qt.rgba(0.85, 0.47, 0.02, 0.3) :
                              (root.isCooling ? Qt.rgba(0.01, 0.52, 0.78, 0.3) : DesignSystem.borderMuted)
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: root.isHeating ? DesignSystem.accentAmber :
                               (root.isCooling ? DesignSystem.accentCyan : DesignSystem.textMuted)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        id: thermalText
                        text: root.isHeating ? "HEATING ACTIVE" :
                              (root.isCooling ? "COOLING ACTIVE" : "TARGET MAINTAINED")
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: root.isHeating ? DesignSystem.accentAmber :
                               (root.isCooling ? DesignSystem.accentCyan : DesignSystem.textSecondary)
                        font.letterSpacing: 0.5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // =====================================================================
        // HERO INTERACTION: Tactile Minus + Large Numeric Readout + Tactile Plus
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: DesignSystem.spacingLg

            // -----------------------------------------------------------------
            // TACTILE DECREMENT BUTTON (−)
            // -----------------------------------------------------------------
            Item {
                implicitWidth: 64
                implicitHeight: 64
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: decBtnBg
                    anchors.fill: parent
                    radius: 32
                    color: decArea.pressed ? DesignSystem.surfaceWell :
                           (decArea.containsMouse ? DesignSystem.surfaceElevated : DesignSystem.surface)
                    border.color: decArea.containsMouse ? DesignSystem.accentCyan : DesignSystem.borderHighlight
                    border.width: 1.5
                    scale: decArea.pressed ? 0.93 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad }
                    }
                    Behavior on color {
                        ColorAnimation { duration: DesignSystem.durationInstant }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "−"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 32
                        font.weight: DesignSystem.fontWeightBold
                        color: (root.targetTemperature > root.minTemperature && !root.isRestricted) ?
                               DesignSystem.textPrimary : DesignSystem.textDisabled
                    }
                }

                MouseArea {
                    id: decArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.targetTemperature > root.minTemperature && !root.isRestricted

                    Timer {
                        id: decRepeatTimer
                        interval: 180
                        repeat: true
                        running: decArea.pressed
                        onTriggered: {
                            if (root.targetTemperature > root.minTemperature) {
                                root.decreaseRequested()
                            }
                        }
                    }

                    onClicked: {
                        if (root.targetTemperature > root.minTemperature) {
                            root.decreaseRequested()
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // CENTRAL DOMINANT TEMPERATURE READOUT
            // -----------------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                // Temperature Number Display
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2

                    Text {
                        id: tempValueText
                        text: root.targetTemperatureFormatted.replace("°", "")
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 68
                        font.weight: DesignSystem.fontWeightBold
                        color: root.isHeating ? DesignSystem.accentAmber :
                               (root.isCooling ? DesignSystem.accentCyan : DesignSystem.textPrimary)
                        font.letterSpacing: -1.5

                        Behavior on color {
                            ColorAnimation { duration: DesignSystem.durationNormal }
                        }

                        // Subtle pulse animation when temperature updates
                        onTextChanged: {
                            tempPulseAnim.restart()
                        }

                        NumberAnimation {
                            id: tempPulseAnim
                            target: tempValueText
                            property: "scale"
                            from: 1.06
                            to: 1.0
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        text: "°"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 42
                        font.weight: DesignSystem.fontWeightMedium
                        color: root.isHeating ? DesignSystem.accentAmber :
                               (root.isCooling ? DesignSystem.accentCyan : DesignSystem.textSecondary)
                        anchors.top: parent.top
                        anchors.topMargin: 8

                        Behavior on color {
                            ColorAnimation { duration: DesignSystem.durationNormal }
                        }
                    }
                }

                // Subtitle Label
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.isSyncActive ? "CABIN TARGET TEMP" : "DRIVER SETPOINT"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeMicro
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textMuted
                    font.letterSpacing: 1.2
                }
            }

            // -----------------------------------------------------------------
            // TACTILE INCREMENT BUTTON (+)
            // -----------------------------------------------------------------
            Item {
                implicitWidth: 64
                implicitHeight: 64
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: incBtnBg
                    anchors.fill: parent
                    radius: 32
                    color: incArea.pressed ? DesignSystem.surfaceWell :
                           (incArea.containsMouse ? DesignSystem.surfaceElevated : DesignSystem.surface)
                    border.color: incArea.containsMouse ? DesignSystem.accentCyan : DesignSystem.borderHighlight
                    border.width: 1.5
                    scale: incArea.pressed ? 0.93 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: DesignSystem.durationFast; easing.type: Easing.OutQuad }
                    }
                    Behavior on color {
                        ColorAnimation { duration: DesignSystem.durationInstant }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 28
                        font.weight: DesignSystem.fontWeightBold
                        color: (root.targetTemperature < root.maxTemperature && !root.isRestricted) ?
                               DesignSystem.textPrimary : DesignSystem.textDisabled
                    }
                }

                MouseArea {
                    id: incArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.targetTemperature < root.maxTemperature && !root.isRestricted

                    Timer {
                        id: incRepeatTimer
                        interval: 180
                        repeat: true
                        running: incArea.pressed
                        onTriggered: {
                            if (root.targetTemperature < root.maxTemperature) {
                                root.increaseRequested()
                            }
                        }
                    }

                    onClicked: {
                        if (root.targetTemperature < root.maxTemperature) {
                            root.increaseRequested()
                        }
                    }
                }
            }
        }

        // =====================================================================
        // FOOTER / SECONDARY ZONE STRIP: Dual-Zone Sync & Passenger Control
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: DesignSystem.radiusMd
            color: DesignSystem.surfaceWell
            border.color: DesignSystem.borderMuted
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: DesignSystem.spacingMd
                anchors.rightMargin: DesignSystem.spacingMd
                spacing: DesignSystem.spacingMd

                // Left: Dual Zone Sync Pill Button
                Rectangle {
                    implicitWidth: syncLabel.implicitWidth + 24
                    implicitHeight: 32
                    radius: DesignSystem.radiusPill
                    color: root.isSyncActive ? DesignSystem.accentCyan : DesignSystem.surface
                    border.color: root.isSyncActive ? DesignSystem.accentCyan : DesignSystem.borderHighlight
                    border.width: 1

                    Row {
                        id: syncLabel
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "⮂⮄"
                            font.pixelSize: 11
                            color: root.isSyncActive ? "#FFFFFF" : DesignSystem.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.isSyncActive ? "SYNC ON" : "DUAL ZONE"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: root.isSyncActive ? "#FFFFFF" : DesignSystem.textPrimary
                            font.letterSpacing: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.syncToggled()
                    }
                }

                Item { Layout.fillWidth: true }

                // Right: Passenger Zone Target Readout & Adjustment
                RowLayout {
                    spacing: DesignSystem.spacingSm
                    visible: true
                    opacity: root.isSyncActive ? 0.75 : 1.0

                    Text {
                        text: root.isSyncActive ? "PASSENGER (SYNCED):" : "PASSENGER:"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textMuted
                        font.letterSpacing: 0.4
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Stepper minus for passenger (enabled if sync is off)
                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        visible: !root.isSyncActive
                        color: passMinusArea.containsMouse ? DesignSystem.surfaceElevated : DesignSystem.surface
                        border.color: DesignSystem.borderHighlight
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 14
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textPrimary
                        }

                        MouseArea {
                            id: passMinusArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.passengerDecreaseRequested()
                        }
                    }

                    Text {
                        text: root.passengerTemperatureFormatted
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeBody
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.textPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Stepper plus for passenger (enabled if sync is off)
                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        visible: !root.isSyncActive
                        color: passPlusArea.containsMouse ? DesignSystem.surfaceElevated : DesignSystem.surface
                        border.color: DesignSystem.borderHighlight
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 14
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textPrimary
                        }

                        MouseArea {
                            id: passPlusArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.passengerIncreaseRequested()
                        }
                    }
                }
            }
        }
    }
}
