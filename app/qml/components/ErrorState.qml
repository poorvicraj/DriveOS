import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string errorCode: "U0111"
    property string title: "Communication Degraded"
    property string message: "Periodic CAN bus deadline exceeded. Fallback safety parameters active."
    property string retryText: "RETRY SUBSYSTEM"

    signal retryClicked()

    implicitWidth: 440
    implicitHeight: 260
    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: DesignSystem.accentRuby
    border.width: 1

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - DesignSystem.spacingXl * 2, 380)
        spacing: DesignSystem.spacingMd

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 56
            height: 56
            radius: 28
            color: Qt.rgba(1.0, 0.271, 0.227, 0.15)
            border.color: DesignSystem.accentRuby
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "⚠️"
                font.pixelSize: 24
            }
        }

        StatusBadge {
            text: "DTC " + root.errorCode
            status: "critical"
            Layout.alignment: Qt.AlignHCenter
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

        SecondaryButton {
            visible: root.retryText.length > 0
            text: root.retryText
            Layout.alignment: Qt.AlignHCenter
            onClicked: root.retryClicked()
        }
    }
}
