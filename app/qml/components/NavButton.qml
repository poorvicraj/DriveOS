import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: root

    property string label: ""
    property string iconText: ""
    property bool isActive: false
    property bool isRestricted: false

    signal clicked()

    implicitWidth: 160
    implicitHeight: 64

    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingXs
        radius: DesignSystem.radiusMd
        color: root.isActive ? Qt.rgba(0.0, 0.898, 1.0, 0.12) :
               mouseArea.containsPress ? Qt.rgba(1, 1, 1, 0.08) :
               mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
        border.color: root.isActive ? DesignSystem.borderActive : "transparent"
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: DesignSystem.durationFast }
        }

        Row {
            anchors.centerIn: parent
            spacing: DesignSystem.spacingSm

            Text {
                text: root.iconText
                font.pixelSize: DesignSystem.fontSizeTitle
                color: root.isActive ? DesignSystem.accentCyan :
                       root.isRestricted ? DesignSystem.textDisabled : DesignSystem.textSecondary
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.label
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeBody
                font.weight: root.isActive ? DesignSystem.fontWeightBold : DesignSystem.fontWeightRegular
                color: root.isActive ? DesignSystem.textPrimary :
                       root.isRestricted ? DesignSystem.textDisabled : DesignSystem.textSecondary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.isRestricted

        onClicked: {
            root.clicked()
        }
    }
}
