import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string destination: "Home → Mysuru Palace"
    property string eta: "18 min"
    property string distance: "12.4 km"
    property string maneuver: "In 450 m, turn right onto Cyberway"
    property string turnIcon: "↱"

    signal cardClicked()

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

        // Header Row: Section Label + Route Optimization Badge
        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingSm

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "🧭"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "NAVIGATION"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textMuted
                    font.letterSpacing: 1.1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                height: 22
                radius: DesignSystem.radiusPill
                color: Qt.rgba(5, 150, 105, 0.10)
                border.color: DesignSystem.accentEmerald
                border.width: 1
                implicitWidth: optRow.implicitWidth + 14

                Row {
                    id: optRow
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: DesignSystem.accentEmerald
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "FASTEST ROUTE"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.accentEmerald
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Body Row: Maneuver Icon + Guidance Information + Action Button
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: DesignSystem.spacingMd

            // Turn Maneuver Icon Badge
            Rectangle {
                width: 54
                height: 54
                radius: DesignSystem.radiusMd
                color: Qt.rgba(2, 132, 199, 0.10)
                border.color: Qt.rgba(2, 132, 199, 0.25)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: root.turnIcon
                        font.pixelSize: 22
                        color: DesignSystem.accentCyan
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "450 m"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 9
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.accentCyan
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // Route & Guidance Description
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                Text {
                    text: root.destination
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.maneuver
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    color: DesignSystem.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 6

                    Text {
                        text: root.eta + " (" + root.distance + ")"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.accentCyan
                    }

                    Text {
                        text: "• Traffic Clear"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.accentEmerald
                    }
                }
            }

            // Open Map Chevron Action
            Rectangle {
                width: 48
                height: 48
                radius: DesignSystem.radiusMd
                color: mapArea.pressed ? DesignSystem.borderMuted : DesignSystem.surfaceWell
                border.color: DesignSystem.borderMuted
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "➔"
                    font.pixelSize: 18
                    color: DesignSystem.accentCyan
                }

                MouseArea {
                    id: mapArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cardClicked()
                }
            }
        }
    }

    // Card Body Click Handler (navigates to Navigation screen)
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: -0.5
        onClicked: root.cardClicked()
    }
}
