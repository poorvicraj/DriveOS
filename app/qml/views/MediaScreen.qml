import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

Rectangle {
    id: root
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingLg
        spacing: DesignSystem.spacingMd

        // =====================================================================
        // TOP CONTEXT RIBBON: Media Title, Audio Source Selector & Quality Pill
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: DesignSystem.spacingMd

            // Left Section: Section Identity
            Row {
                spacing: DesignSystem.spacingSm
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "MEDIA"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    font.letterSpacing: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "• " + (typeof mediaViewModel !== "undefined" ? mediaViewModel.audioSource : "Bluetooth Audio")
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeBody
                    font.weight: DesignSystem.fontWeightMedium
                    color: DesignSystem.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // Center Section: Audio Source Selector
            MediaSourceSelector {
                Layout.alignment: Qt.AlignVCenter
                currentSource: typeof mediaViewModel !== "undefined" ? mediaViewModel.audioSource : "Bluetooth Audio"
                onSourceSelected: function(newSource) {
                    if (typeof mediaViewModel !== "undefined") {
                        mediaViewModel.setAudioSource(newSource)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Right Section: Audio Fidelity & Soundstage Badges
            Row {
                spacing: DesignSystem.spacingSm
                Layout.alignment: Qt.AlignVCenter

                // Hi-Res Badge
                Rectangle {
                    height: 24
                    radius: DesignSystem.radiusPill
                    color: Qt.rgba(2, 132, 199, 0.10)
                    border.color: DesignSystem.accentCyan
                    border.width: 1
                    implicitWidth: hiresText.implicitWidth + 14

                    Text {
                        id: hiresText
                        anchors.centerIn: parent
                        text: "96kHz • 24-BIT FLAC"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.accentCyan
                    }
                }

                // Dolby Atmos Badge
                Rectangle {
                    height: 24
                    radius: DesignSystem.radiusPill
                    color: DesignSystem.surfaceWell
                    border.color: DesignSystem.borderMuted
                    border.width: 1
                    implicitWidth: atmosText.implicitWidth + 14

                    Text {
                        id: atmosText
                        anchors.centerIn: parent
                        text: "DOLBY ATMOS"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.textSecondary
                    }
                }
            }
        }

        // =====================================================================
        // EMPTY STATE VIEW (When no media connected / testing empty state)
        // =====================================================================
        Item {
            visible: typeof mediaViewModel !== "undefined" && !mediaViewModel.hasMedia
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: DesignSystem.radiusLg
                color: DesignSystem.surfaceCard
                border.color: DesignSystem.borderMuted
                border.width: 1

                EmptyState {
                    anchors.centerIn: parent
                    title: "No Media Connected"
                    message: "Connect a mobile device via Bluetooth, plug in a USB audio storage drive, or switch to FM Radio to stream media."
                    iconText: "🎧"
                    actionText: "Reconnect Media Demo"
                    onActionClicked: {
                        if (typeof mediaViewModel !== "undefined") {
                            mediaViewModel.toggleEmptyState()
                        }
                    }
                }
            }
        }

        // =====================================================================
        // MAIN COCKPIT MEDIA VIEW (Now Playing + Up Next Queue)
        // =====================================================================
        RowLayout {
            visible: typeof mediaViewModel === "undefined" || mediaViewModel.hasMedia
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: DesignSystem.spacingLg

            // -----------------------------------------------------------------
            // LEFT COLUMN: Now Playing Showcase & Primary Controls
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: root.width * 0.56
                radius: DesignSystem.radiusLg
                color: DesignSystem.surfaceCard
                border.color: DesignSystem.borderMuted
                border.width: 1

                // Ambient Shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    anchors.bottomMargin: -4
                    radius: parent.radius
                    color: DesignSystem.shadowAmbient
                    z: -1
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: DesignSystem.spacingLg
                    spacing: DesignSystem.spacingMd

                    // Upper Section: Album Artwork + Track Information
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: DesignSystem.spacingLg

                        // High-Fidelity Album Artwork Canvas
                        AlbumArtCanvas {
                            Layout.preferredWidth: 210
                            Layout.preferredHeight: 210
                            coverColor: typeof mediaViewModel !== "undefined" ? mediaViewModel.coverColor : "#0284C7"
                            coverIcon: typeof mediaViewModel !== "undefined" ? mediaViewModel.coverIcon : "🎧"
                            title: typeof mediaViewModel !== "undefined" ? mediaViewModel.title : "Midnight Drive"
                            artist: typeof mediaViewModel !== "undefined" ? mediaViewModel.artist : "DriveOS Synthetics"
                            isPlaying: typeof mediaViewModel !== "undefined" && mediaViewModel.isPlaying
                        }

                        // Track Metadata
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 6

                            // Genre Tag
                            Text {
                                text: (typeof mediaViewModel !== "undefined" && mediaViewModel.genre.length > 0)
                                      ? (mediaViewModel.genre.toUpperCase() + " • COCKPIT AUDIO")
                                      : "AUTOMOTIVE AUDIO"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.accentCyan
                                font.letterSpacing: 1.2
                            }

                            // Song Title
                            Text {
                                text: typeof mediaViewModel !== "undefined" ? mediaViewModel.title : "Midnight Drive"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: 28
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Artist
                            Text {
                                text: typeof mediaViewModel !== "undefined" ? mediaViewModel.artist : "DriveOS Synthetics"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeSubtitle
                                font.weight: DesignSystem.fontWeightMedium
                                color: DesignSystem.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Album
                            Text {
                                text: "Album: " + (typeof mediaViewModel !== "undefined" ? mediaViewModel.album : "Neon Cockpit")
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeBody
                                color: DesignSystem.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Item { height: 4 }

                            // Audio Output Status
                            Row {
                                spacing: 6
                                Text {
                                    text: "🔊 Output:"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeCaption
                                    color: DesignSystem.textMuted
                                }
                                Text {
                                    text: "12-Speaker Cabin Surround Stage"
                                    font.family: DesignSystem.fontFamily
                                    font.pixelSize: DesignSystem.fontSizeCaption
                                    font.weight: DesignSystem.fontWeightBold
                                    color: DesignSystem.accentEmerald
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Middle Section: Interactive Progress Timeline Scrubber
                    MediaProgressBar {
                        Layout.fillWidth: true
                        progress: typeof mediaViewModel !== "undefined" ? mediaViewModel.progress : 0.44
                        elapsedText: typeof mediaViewModel !== "undefined" ? mediaViewModel.elapsedFormatted : "1:42"
                        remainingText: typeof mediaViewModel !== "undefined" ? mediaViewModel.remainingFormatted : "-2:08"

                        onSeekRequested: function(progressFrac) {
                            if (typeof mediaViewModel !== "undefined") {
                                mediaViewModel.seek(progressFrac)
                            }
                        }
                    }

                    Item { height: 4 }

                    // Lower Section: Primary Playback Controls & Volume Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: DesignSystem.spacingMd

                        // Primary Playback Controls
                        Row {
                            spacing: DesignSystem.spacingMd
                            Layout.alignment: Qt.AlignVCenter

                            // Shuffle Mode Button
                            Rectangle {
                                width: 48
                                height: 48
                                radius: 24
                                color: (typeof mediaViewModel !== "undefined" && mediaViewModel.isShuffle)
                                       ? Qt.rgba(2, 132, 199, 0.12)
                                       : (shuffArea.pressed ? DesignSystem.borderMuted : DesignSystem.surfaceWell)
                                border.color: (typeof mediaViewModel !== "undefined" && mediaViewModel.isShuffle)
                                              ? DesignSystem.accentCyan
                                              : DesignSystem.borderMuted
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "🔀"
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    id: shuffArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof mediaViewModel !== "undefined") {
                                            mediaViewModel.toggleShuffle()
                                        }
                                    }
                                }
                            }

                            // Previous Track Button (56x56 dp)
                            Rectangle {
                                width: 54
                                height: 54
                                radius: 27
                                color: prevArea.pressed ? DesignSystem.borderMuted : DesignSystem.surfaceWell
                                border.color: DesignSystem.borderMuted
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏮"
                                    font.pixelSize: 20
                                    color: DesignSystem.textPrimary
                                }

                                MouseArea {
                                    id: prevArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof mediaViewModel !== "undefined") {
                                            mediaViewModel.previousTrack()
                                        }
                                    }
                                }
                            }

                            // Primary Play / Pause Button (72x72 dp dominant circular button)
                            Rectangle {
                                width: 68
                                height: 68
                                radius: 34
                                color: playArea.pressed ? Qt.darker(DesignSystem.accentCyan, 1.1) : DesignSystem.accentCyan
                                scale: playArea.pressed ? 0.94 : 1.0
                                Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast } }
                                anchors.verticalCenter: parent.verticalCenter

                                // Soft Button Ambient Glow
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.topMargin: 4
                                    radius: parent.radius
                                    color: Qt.rgba(2, 132, 199, 0.25)
                                    z: -1
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: (typeof mediaViewModel !== "undefined" && mediaViewModel.isPlaying) ? "❚❚" : "▶"
                                    font.pixelSize: (typeof mediaViewModel !== "undefined" && mediaViewModel.isPlaying) ? 20 : 24
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    id: playArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof mediaViewModel !== "undefined") {
                                            mediaViewModel.togglePlayPause()
                                        }
                                    }
                                }
                            }

                            // Next Track Button (56x56 dp)
                            Rectangle {
                                width: 54
                                height: 54
                                radius: 27
                                color: nextArea.pressed ? DesignSystem.borderMuted : DesignSystem.surfaceWell
                                border.color: DesignSystem.borderMuted
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "⏭"
                                    font.pixelSize: 20
                                    color: DesignSystem.textPrimary
                                }

                                MouseArea {
                                    id: nextArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof mediaViewModel !== "undefined") {
                                            mediaViewModel.nextTrack()
                                        }
                                    }
                                }
                            }

                            // Repeat Mode Button
                            Rectangle {
                                width: 48
                                height: 48
                                radius: 24
                                color: (typeof mediaViewModel !== "undefined" && mediaViewModel.isRepeat)
                                       ? Qt.rgba(2, 132, 199, 0.12)
                                       : (repArea.pressed ? DesignSystem.borderMuted : DesignSystem.surfaceWell)
                                border.color: (typeof mediaViewModel !== "undefined" && mediaViewModel.isRepeat)
                                              ? DesignSystem.accentCyan
                                              : DesignSystem.borderMuted
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "🔁"
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    id: repArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof mediaViewModel !== "undefined") {
                                            mediaViewModel.toggleRepeat()
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Volume Control Integration
                        MediaVolumeControl {
                            Layout.alignment: Qt.AlignVCenter
                            volume: typeof mediaViewModel !== "undefined" ? mediaViewModel.volume : 65
                            isMuted: typeof mediaViewModel !== "undefined" && mediaViewModel.isMuted
                            onVolumeAdjusted: function(level) {
                                if (typeof mediaViewModel !== "undefined") {
                                    mediaViewModel.setVolumeLevel(level)
                                }
                            }
                            onToggleMuteRequested: {
                                if (typeof mediaViewModel !== "undefined") {
                                    mediaViewModel.toggleMute()
                                }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // RIGHT COLUMN: Up Next Queue & Library Access
            // -----------------------------------------------------------------
            MediaQueueList {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: root.width * 0.44

                queueModel: typeof mediaViewModel !== "undefined" ? mediaViewModel.queueList : []
                currentTrackIndex: typeof mediaViewModel !== "undefined" ? mediaViewModel.currentTrackIndex : 0
                isPlaying: typeof mediaViewModel !== "undefined" && mediaViewModel.isPlaying

                onTrackSelected: function(index) {
                    if (typeof mediaViewModel !== "undefined") {
                        mediaViewModel.playTrackAtIndex(index)
                    }
                }

                onToggleEmptyStateRequested: {
                    if (typeof mediaViewModel !== "undefined") {
                        mediaViewModel.toggleEmptyState()
                    }
                }
            }
        }
    }
}
