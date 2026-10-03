import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property real temperature: 22.0
    property real minTemp: 16.0
    property real maxTemp: 28.0
    property real step: 0.5
    property string label: "SETPOINT"
    property bool isRestricted: false

    signal targetAdjusted(real newTemp)

    implicitWidth: 260
    implicitHeight: 120
    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: DesignSystem.borderMuted
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm

        Text {
            text: root.label.toUpperCase()
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeMicro
            font.weight: DesignSystem.fontWeightBold
            color: DesignSystem.textMuted
            Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: DesignSystem.spacingMd

            // Decrement Button
            IconButton {
                iconText: "−"
                iconSize: 22
                buttonSize: DesignSystem.minTouchTarget
                enabled: root.temperature > root.minTemp && !root.isRestricted
                onClicked: {
                    root.temperature = Math.max(root.minTemp, root.temperature - root.step)
                    root.targetAdjusted(root.temperature)
                }
            }

            // Center Temperature Readout
            Item {
                Layout.fillWidth: true
                implicitHeight: DesignSystem.minTouchTarget

                Row {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        text: root.temperature.toFixed(1)
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeDisplay
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.accentCyan
                    }
                    Text {
                        text: "°C"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeSubtitle
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textSecondary
                        anchors.baseline: parent.children[0].baseline
                    }
                }
            }

            // Increment Button
            IconButton {
                iconText: "+"
                iconSize: 22
                buttonSize: DesignSystem.minTouchTarget
                enabled: root.temperature < root.maxTemp && !root.isRestricted
                onClicked: {
                    root.temperature = Math.min(root.maxTemp, root.temperature + root.step)
                    root.targetAdjusted(root.temperature)
                }
            }
        }
    }
}
