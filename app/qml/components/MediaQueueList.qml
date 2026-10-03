import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property var queueModel: []
    property int currentTrackIndex: 0
    property bool isPlaying: true

    signal trackSelected(int index)
    signal toggleEmptyStateRequested()

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

        // Header: Title + Track Count + Demo Toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingSm

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "📋"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "UP NEXT IN QUEUE"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textMuted
                    font.letterSpacing: 1.1
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.queueModel.length + " Tracks"
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeCaption
                font.weight: DesignSystem.fontWeightMedium
                color: DesignSystem.textSecondary
                Layout.alignment: Qt.AlignVCenter
            }

            // Discreet Demo Empty State Toggle
            Rectangle {
                height: 24
                radius: DesignSystem.radiusSm
                color: DesignSystem.surfaceWell
                border.color: DesignSystem.borderMuted
                border.width: 1
                implicitWidth: simText.implicitWidth + 12

                Text {
                    id: simText
                    anchors.centerIn: parent
                    text: "Test Empty"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeMicro
                    font.weight: DesignSystem.fontWeightMedium
                    color: DesignSystem.textMuted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleEmptyStateRequested()
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: DesignSystem.borderMuted
        }

        // Scrollable Queue Items List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.queueModel

            delegate: Rectangle {
                id: delegateRect
                width: listView.width
                height: 60
                radius: DesignSystem.radiusMd

                readonly property bool isCurrentTrack: modelData ? Boolean(modelData.isCurrent) : false

                color: {
                    if (delegateRect.isCurrentTrack) {
                        return Qt.rgba(2, 132, 199, 0.08)
                    }
                    return itemArea.pressed ? DesignSystem.borderMuted : (itemArea.containsMouse ? DesignSystem.surfaceWell : "transparent")
                }
                border.color: delegateRect.isCurrentTrack ? DesignSystem.accentCyan : "transparent"
                border.width: delegateRect.isCurrentTrack ? 1 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: DesignSystem.spacingMd
                    anchors.rightMargin: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingMd

                    // Track Number or Active Waveform Icon
                    Item {
                        width: 24
                        height: 24
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            visible: !delegateRect.isCurrentTrack
                            anchors.centerIn: parent
                            text: (index + 1).toString()
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeCaption
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textMuted
                        }

                        // Equalizer bars when playing
                        Row {
                            visible: delegateRect.isCurrentTrack
                            anchors.centerIn: parent
                            spacing: 2

                            Repeater {
                                model: 3
                                Rectangle {
                                    width: 3
                                    height: root.isPlaying ? (8 + (index * 4)) : 6
                                    radius: 1.5
                                    color: DesignSystem.accentCyan
                                    anchors.bottom: parent.bottom

                                    SequentialAnimation on height {
                                        running: delegateRect.isCurrentTrack && root.isPlaying
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 4 + (index * 3); duration: 220 + (index * 60); easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 16 - (index * 2); duration: 220 + (index * 60); easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }
                    }

                    // Mini Album Art
                    Rectangle {
                        width: 40
                        height: 40
                        radius: DesignSystem.radiusSm
                        color: modelData.coverColor || "#0284C7"
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: modelData.coverIcon || "🎧"
                            font.pixelSize: 18
                        }
                    }

                    // Track Title & Artist
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: modelData.title
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeBody
                            font.weight: delegateRect.isCurrentTrack ? DesignSystem.fontWeightBold : DesignSystem.fontWeightMedium
                            color: delegateRect.isCurrentTrack ? DesignSystem.accentCyan : DesignSystem.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: modelData.artist + " • " + modelData.album
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            color: DesignSystem.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Duration
                    Text {
                        text: modelData.durationFormatted
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textMuted
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: itemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.trackSelected(modelData.index)
                }
            }
        }
    }
}
