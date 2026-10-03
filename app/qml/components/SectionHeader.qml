import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: root

    property string title: ""
    property string subtitle: ""
    property string badgeText: ""
    property color badgeColor: DesignSystem.accentCyan

    implicitWidth: 360
    implicitHeight: Math.max(DesignSystem.minTouchTarget, textColumn.implicitHeight)
    spacing: DesignSystem.spacingMd

    Column {
        id: textColumn
        Layout.fillWidth: true
        spacing: 2

        Text {
            text: root.title
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeTitle
            font.weight: DesignSystem.fontWeightBold
            color: DesignSystem.textPrimary
        }

        Text {
            visible: root.subtitle.length > 0
            text: root.subtitle
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeCaption
            color: DesignSystem.textSecondary
        }
    }

    Rectangle {
        visible: root.badgeText.length > 0
        implicitWidth: badgeTextItem.implicitWidth + DesignSystem.spacingMd * 2
        implicitHeight: 26
        radius: DesignSystem.radiusPill
        color: Qt.rgba(root.badgeColor.r, root.badgeColor.g, root.badgeColor.b, 0.14)
        border.color: root.badgeColor
        border.width: 1

        Text {
            id: badgeTextItem
            anchors.centerIn: parent
            text: root.badgeText.toUpperCase()
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeMicro
            font.weight: DesignSystem.fontWeightBold
            color: root.badgeColor
        }
    }
}
