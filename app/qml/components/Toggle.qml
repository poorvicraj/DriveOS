import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property bool checked: false
    property string label: ""
    property string sublabel: ""
    property color accentColor: DesignSystem.accentCyan
    property bool isRestricted: false

    signal toggled(bool checked)

    implicitHeight: Math.max(DesignSystem.minTouchTarget, contentLayout.implicitHeight)
    implicitWidth: contentLayout.implicitWidth

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: DesignSystem.spacingMd

        Column {
            Layout.fillWidth: true
            visible: root.label.length > 0
            spacing: 2

            Text {
                text: root.label
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeBody
                font.weight: DesignSystem.fontWeightMedium
                color: root.enabled && !root.isRestricted
                       ? DesignSystem.textPrimary
                       : DesignSystem.textDisabled
            }

            Text {
                visible: root.sublabel.length > 0
                text: root.sublabel
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeCaption
                color: DesignSystem.textMuted
            }
        }

        // Pill Track
        Rectangle {
            id: track
            width: 54
            height: 30
            radius: DesignSystem.radiusPill
            color: root.checked
                   ? root.accentColor
                   : DesignSystem.surfaceElevated
            border.color: root.checked
                          ? "transparent"
                          : DesignSystem.borderHighlight
            border.width: 1

            Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }

            // Thumb
            Rectangle {
                id: thumb
                width: 24
                height: 24
                radius: 12
                y: 3
                x: root.checked ? track.width - width - 3 : 3
                color: root.checked ? DesignSystem.textInverse : DesignSystem.textPrimary

                scale: toggleMouse.pressed ? 0.92 : 1.0

                Behavior on x {
                    NumberAnimation {
                        duration: DesignSystem.durationFast
                        easing.type: DesignSystem.easingCurveStandard
                    }
                }
                Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }
                Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast } }
            }
        }
    }

    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        cursorShape: enabled && !root.isRestricted ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.enabled && !root.isRestricted) {
                root.checked = !root.checked
                root.toggled(root.checked)
            }
        }
    }
}
