import QtQuick
import QtQuick.Window

Window {
    id: mainWindow
    width: 1280
    height: 720
    minimumWidth: 1024
    minimumHeight: 600
    visible: true
    title: qsTr("DriveOS — Automotive Digital Cockpit Foundation")
    color: "#090D16"

    AppShell {
        anchors.fill: parent
    }
}
