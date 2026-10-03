import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string title: "Driver Distraction Alert"
    property string message: "Action prohibited while vehicle is in motion."
    property string severity: "warning" // "warning", "critical", "info"

    signal dismissed()

    readonly property color bannerAccent: {
        switch (severity) {
        case "critical": return DesignSystem.accentRuby
        case "warning":  return DesignSystem.accentAmber
        default:         return DesignSystem.accentCyan
        }
    }

    implicitWidth: Math.min(680, parent ? parent.width - 48 : 600)
    implicitHeight: 56
    radius: DesignSystem.radiusMd
    color: DesignSystem.surfaceElevated
    border.color: bannerAccent
    border.width: 1

    Behavior on opacity { NumberAnimation { duration: DesignSystem.durationNormal } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: DesignSystem.spacingLg
        anchors.rightMargin: DesignSystem.spacingLg
        spacing: DesignSystem.spacingMd

        Text {
            text: root.severity === "critical" ? "⛔" : root.severity === "warning" ? "⚠️" : "ℹ️"
            font.pixelSize: 20
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: root.title
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeBody
                font.weight: DesignSystem.fontWeightBold
                color: root.bannerAccent
            }

            Text {
                text: root.message
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeCaption
                color: DesignSystem.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        IconButton {
            iconText: "✕"
            iconSize: 14
            buttonSize: 36
            onClicked: root.dismissed()
        }
    }
}
