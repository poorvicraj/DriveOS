import QtQuick
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root

    property string text: ""
    property string iconText: ""
    property bool isRestricted: false
    property real minWidth: 120

    signal clicked()

    implicitWidth: Math.max(minWidth, contentRow.implicitWidth + DesignSystem.spacingLg * 2)
    implicitHeight: DesignSystem.buttonHeight
    radius: DesignSystem.radiusMd

    color: !enabled || isRestricted
           ? DesignSystem.surface
           : mouseArea.pressed
             ? DesignSystem.surfaceElevated
             : mouseArea.containsMouse
               ? Qt.rgba(0.14, 0.19, 0.28, 0.95)
               : DesignSystem.surfaceCard

    border.color: mouseArea.containsMouse && enabled && !isRestricted
                  ? DesignSystem.accentCyan
                  : DesignSystem.borderDefault
    border.width: 1

    scale: mouseArea.pressed && enabled && !isRestricted ? DesignSystem.scalePressed : 1.0
    opacity: !enabled || isRestricted ? DesignSystem.opacityDisabled : 1.0

    Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast; easing.type: DesignSystem.easingCurveSnappy } }
    Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }
    Behavior on border.color { ColorAnimation { duration: DesignSystem.durationFast } }
    Behavior on opacity { NumberAnimation { duration: DesignSystem.durationFast } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: DesignSystem.spacingSm

        Text {
            visible: root.iconText.length > 0
            text: root.iconText
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeBody
            font.weight: DesignSystem.fontWeightMedium
            color: mouseArea.containsMouse && enabled && !isRestricted
                   ? DesignSystem.textPrimary
                   : DesignSystem.textSecondary
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: enabled && !root.isRestricted ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.enabled && !root.isRestricted) {
                root.clicked()
            }
        }
    }
}
