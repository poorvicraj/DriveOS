import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string title: "Midnight Drive"
    property string artist: "DriveOS Synthetics"
    property bool isPlaying: true
    property string elapsedFormatted: "1:42"
    property string durationFormatted: "3:50"
    property real progress: 0.44

    signal cardClicked()
    signal togglePlayPause()
    signal nextTrack()
    signal prevTrack()

    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: DesignSystem.borderMuted
    border.width: 1

    // Soft Ambient Card Shadow
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
        anchors.margins: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm

        // Header Row: Section Label + Audio Source Badge
        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingSm

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "🎵"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "NOW PLAYING"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textMuted
                    font.letterSpacing: 1.1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                height: 22
                radius: DesignSystem.radiusPill
                color: DesignSystem.surfaceWell
                border.color: DesignSystem.borderMuted
                border.width: 1
                implicitWidth: sourceText.implicitWidth + 14

                Text {
                    id: sourceText
                    anchors.centerIn: parent
                    text: "BLUETOOTH AUDIO"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeMicro
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textSecondary
                }
            }
        }

        // Body Row: Album Art + Track Info + Compact Playback Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: DesignSystem.spacingMd

            // Album Art Thumbnail
            Rectangle {
                width: 54
                height: 54
                radius: DesignSystem.radiusMd
                color: "#1E293B"
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(2, 132, 199, 0.4) }
                        GradientStop { position: 1.0; color: "#0F172A" }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "🎧"
                    font.pixelSize: 22
                }
            }

            // Track Details + Scrubber Bar
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Text {
                    text: root.title
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: root.artist
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    color: DesignSystem.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Progress Bar Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4
                        radius: 2
                        color: DesignSystem.borderMuted

                        Rectangle {
                            width: parent.width * Math.max(0.0, Math.min(1.0, root.progress))
                            height: parent.height
                            radius: 2
                            color: DesignSystem.accentCyan
                        }
                    }

                    Text {
                        text: root.elapsedFormatted + " / " + root.durationFormatted
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeMicro
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textMuted
                    }
                }
            }

            // Compact Playback Controls (Touch targets >= 48dp)
            Row {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                // Previous Track
                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: prevArea.pressed ? DesignSystem.borderMuted : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        font.pixelSize: 16
                        color: DesignSystem.textPrimary
                    }

                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevTrack()
                    }
                }

                // Play / Pause Button (Dominant Cobalt Pill)
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: playArea.pressed ? Qt.darker(DesignSystem.accentCyan, 1.1) : DesignSystem.accentCyan
                    scale: playArea.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast } }

                    Text {
                        anchors.centerIn: parent
                        text: root.isPlaying ? "❚❚" : "▶"
                        font.pixelSize: root.isPlaying ? 14 : 16
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePlayPause()
                    }
                }

                // Next Track
                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: nextArea.pressed ? DesignSystem.borderMuted : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        font.pixelSize: 16
                        color: DesignSystem.textPrimary
                    }

                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextTrack()
                    }
                }
            }
        }
    }

    // Card Body Click Handler (navigates to Media screen)
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: -0.5
        onClicked: root.cardClicked()
    }
}
