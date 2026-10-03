import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string title: "No Data Available"
    property string message: "The requested telemetry or service is currently idle."
    property string iconText: "📡"
    property string actionText: ""

    signal actionClicked()

    implicitWidth: 420
    implicitHeight: 240
    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: DesignSystem.borderMuted
    border.width: 1

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - DesignSystem.spacingXl * 2, 360)
        spacing: DesignSystem.spacingMd

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 56
            height: 56
            radius: 28
            color: DesignSystem.surfaceElevated
            border.color: DesignSystem.borderDefault
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.iconText
                font.pixelSize: 26
            }
        }

        Text {
            text: root.title
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeSubtitle
            font.weight: DesignSystem.fontWeightBold
            color: DesignSystem.textPrimary
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: root.message
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeBody
            color: DesignSystem.textSecondary
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        PrimaryButton {
            visible: root.actionText.length > 0
            text: root.actionText
            Layout.alignment: Qt.AlignHCenter
            onClicked: root.actionClicked()
        }
    }
}
