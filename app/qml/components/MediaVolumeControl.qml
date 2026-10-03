import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: root

    property int volume: 65
    property bool isMuted: false

    signal volumeAdjusted(int level)
    signal toggleMuteRequested()

    spacing: DesignSystem.spacingSm

    // Mute / Speaker Icon Button (48x48 dp touch target)
    Rectangle {
        width: 44
        height: 44
        radius: DesignSystem.radiusSm
        color: muteArea.pressed ? DesignSystem.borderMuted : DesignSystem.surfaceWell
        border.color: DesignSystem.borderMuted
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: root.isMuted || root.volume === 0 ? "🔇" : (root.volume > 50 ? "🔊" : "🔉")
            font.pixelSize: 18
        }

        MouseArea {
            id: muteArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMuteRequested()
        }
    }

    // Volume Track
    Item {
        id: volTrack
        Layout.fillWidth: true
        Layout.preferredWidth: 160
        height: 44

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: DesignSystem.borderMuted

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * (root.isMuted ? 0.0 : Math.max(0.0, Math.min(1.0, root.volume / 100.0)))
                radius: 3
                color: root.isMuted ? DesignSystem.textDisabled : DesignSystem.accentCyan
            }
        }

        // Thumb Knob
        Rectangle {
            width: 16
            height: 16
            radius: 8
            color: "#FFFFFF"
            border.color: root.isMuted ? DesignSystem.textDisabled : DesignSystem.accentCyan
            border.width: 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(volTrack.width - width, (volTrack.width * (root.isMuted ? 0.0 : Math.max(0.0, Math.min(1.0, root.volume / 100.0)))) - (width / 2)))
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function handleVol(mousePos) {
                var level = Math.round(Math.max(0.0, Math.min(1.0, mousePos.x / volTrack.width)) * 100);
                root.volumeAdjusted(level);
            }

            onPressed: function(mouse) { handleVol(mouse); }
            onPositionChanged: function(mouse) {
                if (pressed) handleVol(mouse);
            }
        }
    }

    // Numerical Readout
    Text {
        text: (root.isMuted ? 0 : root.volume) + "%"
        font.family: DesignSystem.fontFamily
        font.pixelSize: DesignSystem.fontSizeCaption
        font.weight: DesignSystem.fontWeightBold
        color: DesignSystem.textSecondary
        Layout.preferredWidth: 38
        horizontalAlignment: Text.AlignRight
    }
}
