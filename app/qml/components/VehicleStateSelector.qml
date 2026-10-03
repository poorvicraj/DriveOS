import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string currentState: "PARKED"
    signal stateSelected(string newState)

    readonly property var states: [
        { id: "PARKED", label: "PARKED", icon: "🅿️" },
        { id: "DRIVING", label: "DRIVING", icon: "🚘" },
        { id: "REVERSE", label: "REVERSE", icon: "🔄" },
        { id: "CHARGING", label: "CHARGING", icon: "⚡" },
        { id: "FAULT", label: "FAULT", icon: "⚠️" }
    ]

    height: 38
    radius: DesignSystem.radiusPill
    color: DesignSystem.surfaceWell
    border.color: DesignSystem.borderMuted
    border.width: 1
    implicitWidth: 460

    Row {
        anchors.fill: parent

        Repeater {
            model: root.states

            Item {
                id: itemRect
                width: parent.width / root.states.length
                height: parent.height

                readonly property bool isSelected: root.currentState === modelData.id

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
                        spacing: 4

                        Text {
                            text: modelData.icon
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.label
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: itemRect.isSelected ? DesignSystem.fontWeightBold : DesignSystem.fontWeightMedium
                            color: {
                                if (itemRect.isSelected) {
                                    if (modelData.id === "PARKED") return DesignSystem.accentEmerald
                                    if (modelData.id === "DRIVING") return DesignSystem.accentCyan
                                    if (modelData.id === "REVERSE") return DesignSystem.accentAmber
                                    if (modelData.id === "CHARGING") return DesignSystem.accentEmerald
                                    if (modelData.id === "FAULT") return DesignSystem.accentRuby
                                    return DesignSystem.accentCyan
                                }
                                return DesignSystem.textMuted
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.stateSelected(modelData.id)
                }
            }
        }
    }
}
