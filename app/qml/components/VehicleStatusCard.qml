import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string subsystemName: "POWERTRAIN"
    property string statusText: "NORMAL"
    property bool isHealthy: true
    property string iconText: "⚡"
    property string detailsText: "All inverters and thermal loops nominal."

    implicitWidth: 320
    implicitHeight: 110
    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: isHealthy ? DesignSystem.borderMuted : DesignSystem.accentRuby
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm

        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingSm

            Text {
                text: root.iconText
                font.pixelSize: 20
            }

            Text {
                text: root.subsystemName.toUpperCase()
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeBody
                font.weight: DesignSystem.fontWeightBold
                color: DesignSystem.textPrimary
                Layout.fillWidth: true
            }

            StatusBadge {
                text: root.statusText
                status: root.isHealthy ? "healthy" : "critical"
            }
        }

        Text {
            text: root.detailsText
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeCaption
            color: DesignSystem.textSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
