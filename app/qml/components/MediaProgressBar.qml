import QtQuick
import "../theme"

Item {
    id: root

    property real progress: 0.0          // 0.0 to 1.0
    property string elapsedText: "0:00"
    property string remainingText: "-0:00"
    property bool isSeeking: false

    signal seekRequested(real progressFrac)

    implicitHeight: 36
    implicitWidth: 320

    Column {
        anchors.fill: parent
        spacing: 6

        // Interactive Track Area
        Item {
            id: trackContainer
            width: parent.width
            height: 20

            // Background Track
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: DesignSystem.borderMuted

                // Active Progress Fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0.0, Math.min(1.0, root.progress))
                    radius: 3
                    color: DesignSystem.accentCyan
                }
            }

            // Draggable Thumb Knob
            Rectangle {
                id: thumb
                width: 18
                height: 18
                radius: 9
                color: "#FFFFFF"
                border.color: DesignSystem.accentCyan
                border.width: 2.5
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, Math.min(trackContainer.width - width, (trackContainer.width * Math.max(0.0, Math.min(1.0, root.progress))) - (width / 2)))

                // Soft Thumb Shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    radius: parent.radius
                    color: Qt.rgba(15, 23, 42, 0.15)
                    z: -1
                }
            }

            // Mouse / Touch Interaction Area (touch box comfortably large)
            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function handleSeek(mousePos) {
                    var frac = Math.max(0.0, Math.min(1.0, mousePos.x / trackContainer.width));
                    root.seekRequested(frac);
                }

                onPressed: function(mouse) {
                    root.isSeeking = true;
                    handleSeek(mouse);
                }

                onPositionChanged: function(mouse) {
                    if (pressed) {
                        handleSeek(mouse);
                    }
                }

                onReleased: {
                    root.isSeeking = false;
                }
            }
        }

        // Timestamp Readouts Row
        Item {
            width: parent.width
            height: 14

            Text {
                anchors.left: parent.left
                text: root.elapsedText
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeCaption
                font.weight: DesignSystem.fontWeightMedium
                color: DesignSystem.textSecondary
            }

            Text {
                anchors.right: parent.right
                text: root.remainingText
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeCaption
                font.weight: DesignSystem.fontWeightMedium
                color: DesignSystem.textMuted
            }
        }
    }
}
