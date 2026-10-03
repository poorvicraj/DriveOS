import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string cabinTemp: "21.5°C"
    property string targetTemp: "22.0°C"
    property bool isAcActive: true
    property int fanLevel: 2

    signal cardClicked()
    signal increaseTemp()
    signal decreaseTemp()
    signal toggleAc()

    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: DesignSystem.borderMuted
    border.width: 1

    // Soft Ambient Card Shadow
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm

        // Header Row: Section Label + Status Badges
        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingSm

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "❄️"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "CLIMATE"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textMuted
                    font.letterSpacing: 1.1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // A/C Status Badge
            Rectangle {
                height: 24
                radius: DesignSystem.radiusPill
                color: root.isAcActive ? Qt.rgba(5, 150, 105, 0.10) : DesignSystem.surfaceWell
                border.color: root.isAcActive ? DesignSystem.accentEmerald : DesignSystem.borderMuted
                border.width: 1
                implicitWidth: acRow.implicitWidth + 16

                Row {
                    id: acRow
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: root.isAcActive ? DesignSystem.accentEmerald : DesignSystem.textDisabled
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.isAcActive ? "A/C ON" : "A/C OFF"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: root.isAcActive ? DesignSystem.accentEmerald : DesignSystem.textMuted
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Center Content Row: Temperature Readouts + Interactive Steppers
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: DesignSystem.spacingMd

            // Left: Large Cabin & Target Temperature
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Row {
                    spacing: 4
                    Layout.alignment: Qt.AlignLeft

                    Text {
                        text: root.cabinTemp
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeDisplay
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.textPrimary
                    }
                }

                Row {
                    spacing: 6
                    Layout.alignment: Qt.AlignLeft

                    Text {
                        text: "Target: " + root.targetTemp
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.accentCyan
                    }

                    Text {
                        text: "• Fan " + root.fanLevel
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textMuted
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Right: Interactive Quick Temperature Stepper (>=48dp touch targets)
            Row {
                spacing: DesignSystem.spacingSm
                Layout.alignment: Qt.AlignVCenter

                // Decrease Button (-)
                Rectangle {
                    width: 48
                    height: 48
                    radius: DesignSystem.radiusMd
                    color: minusArea.pressed ? DesignSystem.borderMuted : DesignSystem.surfaceWell
                    border.color: DesignSystem.borderMuted
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
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.decreaseTemp()
                    }
                }

                // Increase Button (+)
                Rectangle {
                    width: 48
                    height: 48
                    radius: DesignSystem.radiusMd
                    color: plusArea.pressed ? DesignSystem.borderMuted : DesignSystem.surfaceWell
                    border.color: DesignSystem.borderMuted
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
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.increaseTemp()
                    }
                }
            }
        }
    }

    // Card Body Click Handler (navigates to Climate screen)
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: -0.5
        onClicked: root.cardClicked()
    }
}
