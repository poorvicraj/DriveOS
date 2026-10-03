import QtQuick
import "../theme"

Rectangle {
    id: root

    property int currentIndex: 0
    signal tabSelected(int index)

    readonly property var tabs: [
        { label: "Home", icon: "🏠" },
        { label: "Media", icon: "🎵" },
        { label: "Climate", icon: "❄️" },
        { label: "Vehicle", icon: "⚡" },
        { label: "Navigation", icon: "🗺️" }
    ]

    implicitHeight: 84
    color: DesignSystem.surfaceGlass
    border.color: DesignSystem.borderMuted
    border.width: 1

    Item {
        id: dockContainer
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 680)
        height: 60

        // Sliding Active Pill Background
        Rectangle {
            id: activePill
            height: 52
            width: dockContainer.width / root.tabs.length
            radius: DesignSystem.radiusMd
            anchors.verticalCenter: parent.verticalCenter
            x: root.currentIndex * width
            color: Qt.rgba(0.0, 0.898, 1.0, 0.12)
            border.color: DesignSystem.accentCyan
            border.width: 1

            Behavior on x {
                NumberAnimation {
                    duration: DesignSystem.durationNormal
                    easing.type: DesignSystem.easingCurveStandard
                }
            }
        }

        // Tab Items Row
        Row {
            anchors.fill: parent

            Repeater {
                model: root.tabs

                Item {
                    id: tabItem
                    width: dockContainer.width / root.tabs.length
                    height: dockContainer.height

                    readonly property bool isActive: root.currentIndex === index

                    Column {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            text: modelData.icon
                            font.pixelSize: 20
                            anchors.horizontalCenter: parent.horizontalCenter
                            scale: tabItem.isActive ? 1.1 : 1.0
                            Behavior on scale { NumberAnimation { duration: DesignSystem.durationFast } }
                        }

                        Text {
                            text: modelData.label
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeCaption
                            font.weight: tabItem.isActive ? DesignSystem.fontWeightBold : DesignSystem.fontWeightMedium
                            color: tabItem.isActive ? DesignSystem.accentCyan : DesignSystem.textSecondary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabSelected(index)
                    }
                }
            }
        }
    }
}
