import QtQuick
import "../theme"

Rectangle {
    id: root

    property string currentSource: "Bluetooth Audio"
    signal sourceSelected(string newSource)

    readonly property var sources: [
        { label: "Bluetooth", id: "Bluetooth Audio", icon: "📶" },
        { label: "USB Storage", id: "USB Storage", icon: "💾" },
        { label: "FM Radio", id: "FM Radio", icon: "📻" },
        { label: "Podcasts", id: "Podcasts", icon: "🎙️" }
    ]

    height: 38
    radius: DesignSystem.radiusPill
    color: DesignSystem.surfaceWell
    border.color: DesignSystem.borderMuted
    border.width: 1
    implicitWidth: 440

    Row {
        anchors.fill: parent

        Repeater {
            model: root.sources

            Item {
                id: itemRect
                width: parent.width / root.sources.length
                height: parent.height

                readonly property bool isSelected: root.currentSource === modelData.id

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: DesignSystem.radiusPill
                    color: itemRect.isSelected ? DesignSystem.surface : "transparent"
                    border.color: itemRect.isSelected ? DesignSystem.borderMuted : "transparent"
                    border.width: itemRect.isSelected ? 1 : 0

                    Behavior on color { ColorAnimation { duration: DesignSystem.durationFast } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: modelData.icon
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.label
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeCaption
                            font.weight: itemRect.isSelected ? DesignSystem.fontWeightBold : DesignSystem.fontWeightMedium
                            color: itemRect.isSelected ? DesignSystem.accentCyan : DesignSystem.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sourceSelected(modelData.id)
                }
            }
        }
    }
}
