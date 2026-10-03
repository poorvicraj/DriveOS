import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property real value: 50.0
    property real from: 0.0
    property real to: 100.0
    property real stepSize: 1.0
    property string label: ""
    property string valueSuffix: ""
    property color accentColor: DesignSystem.accentCyan
    property bool isRestricted: false

    signal moved(real val)

    implicitWidth: 260
    implicitHeight: root.label.length > 0 ? 64 : DesignSystem.minTouchTarget

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // Label and value readout row
        RowLayout {
            Layout.fillWidth: true
            visible: root.label.length > 0

            Text {
                text: root.label
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeCaption
                font.weight: DesignSystem.fontWeightMedium
                color: DesignSystem.textSecondary
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Math.round(root.value) + root.valueSuffix
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeBody
                font.weight: DesignSystem.fontWeightBold
                color: root.accentColor
            }
        }

        // Interactive Track Area
        Item {
            id: trackContainer
            Layout.fillWidth: true
            height: DesignSystem.minTouchTarget

            // Background Groove
            Rectangle {
                id: groove
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 8
                radius: 4
                color: DesignSystem.surfaceElevated
                border.color: DesignSystem.borderMuted
                border.width: 1

                // Active Fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, Math.min(groove.width, thumb.x + thumb.width / 2))
                    radius: 4
                    color: root.accentColor
                }
            }

            // Thumb
            Rectangle {
                id: thumb
                width: 28
                height: 28
                radius: 14
                anchors.verticalCenter: parent.verticalCenter
                x: {
                    const range = root.to - root.from
                    if (range <= 0) return 0
                    const ratio = (root.value - root.from) / range
                    return Math.max(0, Math.min(trackContainer.width - width, ratio * (trackContainer.width - width)))
                }
                color: DesignSystem.textPrimary
                border.color: root.accentColor
                border.width: 2

                scale: dragArea.pressed ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast } }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                cursorShape: enabled && !root.isRestricted ? Qt.PointingHandCursor : Qt.ArrowCursor

                function updateFromPosition(mousePos) {
                    if (!root.enabled || root.isRestricted) return
                    const usableWidth = trackContainer.width - thumb.width
                    if (usableWidth <= 0) return
                    const clampedX = Math.max(0, Math.min(usableWidth, mousePos.x - thumb.width / 2))
                    const ratio = clampedX / usableWidth
                    let rawVal = root.from + ratio * (root.to - root.from)
                    if (root.stepSize > 0) {
                        rawVal = Math.round(rawVal / root.stepSize) * root.stepSize
                    }
                    root.value = Math.max(root.from, Math.min(root.to, rawVal))
                    root.moved(root.value)
                }

                onPressed: function(mouse) { updateFromPosition(mouse) }
                onPositionChanged: function(mouse) {
                    if (pressed) {
                        updateFromPosition(mouse)
                    }
                }
            }
        }
    }
}
