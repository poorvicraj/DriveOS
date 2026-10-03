import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string title: ""
    property string value: "0"
    property string unit: ""
    property string iconText: ""
    property color accentColor: DesignSystem.accentCyan
    property string subtitle: ""
    property bool isWarning: false

    implicitWidth: 220
    implicitHeight: 110
    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: isWarning ? DesignSystem.accentAmber : DesignSystem.borderMuted
    border.width: isWarning ? 1.5 : 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingMd
        spacing: 2

        // Top Row: Title + Icon
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.title.toUpperCase()
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeMicro
                font.weight: DesignSystem.fontWeightBold
                color: DesignSystem.textMuted
                Layout.fillWidth: true
            }

            Text {
                visible: root.iconText.length > 0
                text: root.iconText
                font.pixelSize: 16
            }
        }

        // Center Row: Value + Unit
        Row {
            spacing: DesignSystem.spacingXs
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

            Text {
                text: root.value
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontNumeric
                font.weight: DesignSystem.fontWeightBold
                color: root.isWarning ? DesignSystem.accentAmber : root.accentColor
            }

            Text {
                visible: root.unit.length > 0
                text: root.unit
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeBody
                font.weight: DesignSystem.fontWeightMedium
                color: DesignSystem.textSecondary
                anchors.baseline: parent.children[0].baseline
            }
        }

        // Bottom Subtitle
        Text {
            visible: root.subtitle.length > 0
            text: root.subtitle
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeMicro
            color: DesignSystem.textMuted
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }
}
