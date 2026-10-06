import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string brandTitle: "DRIVEOS"
    property string brandSubtitle: "Cockpit HMI"
    property string gear: "P"
    property string speedFormatted: "0"
    property string batteryFormatted: "85%"
    property bool isDriving: false
    property bool hasFault: false
    property bool canGoBack: false
    property string backendName: "VDI / SIMULATOR READY"

    signal backClicked()
    signal togglePerformanceHud()

    implicitHeight: 68
    color: DesignSystem.surfaceGlass
    border.color: DesignSystem.borderMuted
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: DesignSystem.spacingLg
        anchors.rightMargin: DesignSystem.spacingLg
        spacing: DesignSystem.spacingMd

        // Left Section: Back Button + Brand
        RowLayout {
            spacing: DesignSystem.spacingMd
            Layout.alignment: Qt.AlignVCenter

            IconButton {
                visible: root.canGoBack
                iconText: "◀"
                iconSize: 14
                buttonSize: 38
                Layout.alignment: Qt.AlignVCenter
                onClicked: root.backClicked()
            }

            Row {
                spacing: DesignSystem.spacingSm
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: root.brandTitle
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.accentCyan
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "| " + root.brandSubtitle
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeBody
                    color: DesignSystem.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Center Section: Primary Glanceable Telemetry (Gear + Speed + Battery)
        RowLayout {
            spacing: DesignSystem.spacingXl
            Layout.alignment: Qt.AlignVCenter

            // Shift Selector
            Rectangle {
                width: 36
                height: 36
                radius: DesignSystem.radiusSm
                Layout.alignment: Qt.AlignVCenter
                color: root.gear === "D"
                       ? Qt.rgba(0.0, 0.898, 1.0, 0.16)
                       : DesignSystem.surfaceElevated
                border.color: root.gear === "D"
                              ? DesignSystem.accentCyan
                              : DesignSystem.borderDefault
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.gear
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: root.gear === "D" ? DesignSystem.accentCyan : DesignSystem.textPrimary
                }
            }

            // Speedometer Readout
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: root.speedFormatted
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeTitle
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "KM/H"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightMedium
                    color: DesignSystem.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Battery Badge
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "🔋"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.batteryFormatted
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeBody
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.accentEmerald
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Right Section: Status Pills
        RowLayout {
            spacing: DesignSystem.spacingMd
            Layout.alignment: Qt.AlignVCenter

            // Fault Alert Pill
            StatusBadge {
                visible: root.hasFault
                text: "FAULT ACTIVE"
                status: "critical"
                Layout.alignment: Qt.AlignVCenter
            }

            // In Motion Alert Pill
            StatusBadge {
                visible: root.isDriving && !root.hasFault
                text: "IN MOTION"
                status: "critical"
                Layout.alignment: Qt.AlignVCenter
            }

            // Backend Status Pill
            StatusBadge {
                text: root.hasFault ? "DIAGNOSTIC MODE" : root.backendName
                status: root.hasFault ? "warning" : "healthy"
                Layout.alignment: Qt.AlignVCenter
            }

            // Real-Time Performance & Metrics Chip
            Rectangle {
                implicitHeight: 32
                implicitWidth: fpsRow.implicitWidth + 20
                radius: DesignSystem.radiusSm
                color: fpsMouseArea.containsMouse ? Qt.rgba(0.0, 0.898, 1.0, 0.18) : Qt.rgba(0.0, 0.898, 1.0, 0.08)
                border.color: fpsMouseArea.containsMouse ? DesignSystem.accentCyan : Qt.rgba(0.0, 0.898, 1.0, 0.3)
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: fpsRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "⚡"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "60 FPS"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.accentCyan
                    }
                }

                MouseArea {
                    id: fpsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePerformanceHud()
                }
            }
        }
    }
}
