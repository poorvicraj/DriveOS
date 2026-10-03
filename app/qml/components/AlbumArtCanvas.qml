import QtQuick
import "../theme"

Rectangle {
    id: root

    property string coverColor: "#0284C7"
    property string coverIcon: "🎧"
    property string title: "Midnight Drive"
    property string artist: "DriveOS Synthetics"
    property bool isPlaying: true

    implicitWidth: 230
    implicitHeight: 230
    radius: DesignSystem.radiusLg
    color: "#0F172A"
    clip: true

    // Ambient Tinted Shadow underneath
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.bottomMargin: -6
        radius: parent.radius
        color: Qt.rgba(0.06, 0.09, 0.16, 0.12)
        z: -1
    }

    // High-Resolution Procedural Vinyl Artwork Canvas
    Canvas {
        id: artCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var w = width;
            var h = height;
            if (w <= 0 || h <= 0) return;

            // Background Deep Atmosphere Gradient
            var bgGrad = ctx.createLinearGradient(0, 0, w, h);
            bgGrad.addColorStop(0, root.coverColor);
            bgGrad.addColorStop(0.7, "#0F172A");
            bgGrad.addColorStop(1, "#020617");
            ctx.fillStyle = bgGrad;
            ctx.fillRect(0, 0, w, h);

            // Vinyl Record Disc Aesthetic
            var cx = w * 0.5;
            var cy = h * 0.44;
            var maxR = Math.min(w, h) * 0.38;

            // Outer Vinyl Ring
            ctx.beginPath();
            ctx.arc(cx, cy, maxR, 0, Math.PI * 2);
            ctx.fillStyle = "#111827";
            ctx.fill();
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.15);
            ctx.lineWidth = 1.5;
            ctx.stroke();

            // Concentric Micro-Grooves
            for (var r = maxR - 8; r > maxR * 0.45; r -= 6) {
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.strokeStyle = "rgba(255, 255, 255, 0.04)";
                ctx.lineWidth = 1;
                ctx.stroke();
            }

            // Anisotropic Sheen Light Flare
            var flare = ctx.createRadialGradient(cx, cy, maxR * 0.4, cx, cy, maxR);
            flare.addColorStop(0, "transparent");
            flare.addColorStop(0.5, "rgba(255, 255, 255, 0.05)");
            flare.addColorStop(1, "transparent");
            ctx.fillStyle = flare;
            ctx.beginPath();
            ctx.arc(cx, cy, maxR, 0, Math.PI * 2);
            ctx.fill();

            // Center Label Disc
            ctx.beginPath();
            ctx.arc(cx, cy, maxR * 0.38, 0, Math.PI * 2);
            ctx.fillStyle = root.coverColor;
            ctx.fill();
            ctx.strokeStyle = "rgba(255, 255, 255, 0.4)";
            ctx.lineWidth = 2;
            ctx.stroke();

            // Center Spindle Hole
            ctx.beginPath();
            ctx.arc(cx, cy, 5, 0, Math.PI * 2);
            ctx.fillStyle = "#0F172A";
            ctx.fill();
        }
    }

    // Centered Icon Glyphs
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
        text: root.coverIcon
        font.pixelSize: 32
    }

    // Bottom Ambient Frosted Banner
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: Qt.rgba(15, 23, 42, 0.85)

        Column {
            anchors.left: parent.left
            anchors.right: equalizerRow.left
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.title
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeBody
                font.weight: DesignSystem.fontWeightBold
                color: "#FFFFFF"
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.artist
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeMicro
                font.weight: DesignSystem.fontWeightMedium
                color: "#94A3B8"
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Live Audio Equalizer Waveform Animation
        Row {
            id: equalizerRow
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Repeater {
                model: 4

                Rectangle {
                    width: 3
                    height: root.isPlaying ? (10 + (index % 2 == 0 ? 12 : 8)) : 4
                    radius: 1.5
                    color: root.coverColor
                    anchors.bottom: parent.bottom

                    SequentialAnimation on height {
                        running: root.isPlaying
                        loops: Animation.Infinite
                        NumberAnimation { to: 4 + (index * 4); duration: 250 + (index * 70); easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 20 - (index * 2); duration: 250 + (index * 70); easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 8 + (index * 3); duration: 200; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }
    }

    Connections {
        target: root
        function onCoverColorChanged() { artCanvas.requestPaint(); }
        function onTitleChanged() { artCanvas.requestPaint(); }
    }
}
