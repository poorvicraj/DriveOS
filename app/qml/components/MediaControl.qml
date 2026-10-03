import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property bool isPlaying: true
    property string trackTitle: "Midnight Drive"
    property string artist: "Synthwave Horizons"
    property string albumArtIcon: "🎧"
    property real progressPercent: 0.35
    property int volumePercent: 65
    property bool isRestricted: false

    signal playPauseClicked()
    signal nextClicked()
    signal prevClicked()
    signal volumeChanged(int vol)

    implicitWidth: 640
    implicitHeight: 110
    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: DesignSystem.borderMuted
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm

        // Upper Section: Track Info + Playback Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingMd

            // Album Art
            Rectangle {
                width: 48
                height: 48
                radius: DesignSystem.radiusSm
                color: DesignSystem.surfaceElevated
                border.color: DesignSystem.borderDefault
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.albumArtIcon
                    font.pixelSize: 24
                }
            }

            // Track details
            Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: root.trackTitle
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeBody
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: root.artist
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    color: DesignSystem.textSecondary
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // Transport Buttons
            Row {
                spacing: DesignSystem.spacingSm

                IconButton {
                    iconText: "⏮"
                    iconSize: 18
                    buttonSize: DesignSystem.minTouchTarget
                    enabled: !root.isRestricted
                    onClicked: root.prevClicked()
                }

                IconButton {
                    iconText: root.isPlaying ? "⏸" : "▶"
                    iconSize: 20
                    buttonSize: DesignSystem.minTouchTarget
                    active: root.isPlaying
                    accentColor: DesignSystem.accentPurple
                    enabled: !root.isRestricted
                    onClicked: root.playPauseClicked()
                }

                IconButton {
                    iconText: "⏭"
                    iconSize: 18
                    buttonSize: DesignSystem.minTouchTarget
                    enabled: !root.isRestricted
                    onClicked: root.nextClicked()
                }
            }
        }

        // Progress Groove
        Rectangle {
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: DesignSystem.surfaceElevated

            Rectangle {
                width: parent.width * Math.max(0.0, Math.min(1.0, root.progressPercent))
                height: parent.height
                radius: 2
                color: DesignSystem.accentPurple
            }
        }
    }
}
