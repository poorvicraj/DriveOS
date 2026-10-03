import QtQuick
import "../theme"

Rectangle {
    id: root

    property string iconText: "★"
    property real iconSize: DesignSystem.iconSizeMd
    property real buttonSize: DesignSystem.minTouchTarget
    property bool active: false
    property color accentColor: DesignSystem.accentCyan
    property bool isRestricted: false

    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    radius: DesignSystem.radiusMd

    color: !enabled || isRestricted
           ? DesignSystem.surface
           : active
             ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.22)
             : mouseArea.pressed
               ? DesignSystem.surfaceElevated
               : mouseArea.containsMouse
                 ? Qt.rgba(0.14, 0.19, 0.28, 0.85)
                 : DesignSystem.surfaceCard

    border.color: active
                  ? accentColor
                  : mouseArea.containsMouse && enabled && !isRestricted
                    ? DesignSystem.borderHighlight
                    : DesignSystem.borderMuted
    border.width: active ? 1.5 : 1

    scale: mouseArea.pressed && enabled && !isRestricted ? DesignSystem.scalePressed : 1.0
    opacity: !enabled || isRestricted ? DesignSystem.opacityDisabled : 1.0

    Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast; easing.type: DesignSystem.easingCurveSnappy } }
    Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }
    Behavior on border.color { ColorAnimation { duration: DesignSystem.durationFast } }

    Text {
        anchors.centerIn: parent
        text: root.iconText
        font.pixelSize: root.iconSize
        color: active
               ? root.accentColor
               : mouseArea.containsMouse && enabled && !isRestricted
                 ? DesignSystem.textPrimary
                 : DesignSystem.textSecondary
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
