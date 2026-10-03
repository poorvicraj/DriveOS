import QtQuick
import "../theme"

Rectangle {
    id: root

    property string text: "HEALTHY"
    property string status: "healthy" // "healthy", "warning", "critical", "info", "neutral"
    property bool showDot: true

    readonly property color statusColor: {
        switch (status) {
        case "healthy":  return DesignSystem.accentEmerald
        case "warning":  return DesignSystem.accentAmber
        case "critical": return DesignSystem.accentRuby
        case "info":     return DesignSystem.accentCyan
        default:         return DesignSystem.textSecondary
        }
    }

    implicitHeight: 28
    implicitWidth: badgeRow.implicitWidth + DesignSystem.spacingMd * 2
    radius: DesignSystem.radiusPill

    color: Qt.rgba(statusColor.r, statusColor.g, statusColor.b, 0.12)
    border.color: statusColor
    border.width: 1

    Row {
        id: badgeRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            visible: root.showDot
            width: 6
            height: 6
            radius: 3
            color: root.statusColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text.toUpperCase()
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeMicro
            font.weight: DesignSystem.fontWeightBold
            color: root.statusColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
