import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    // =========================================================================
    // PROPERTIES
    // =========================================================================
    property bool frontLeftDoorOpen: false
    property bool frontRightDoorOpen: false
    property bool rearLeftDoorOpen: false
    property bool rearRightDoorOpen: false
    property bool autoHeadlights: true
    property bool doorsLocked: true
    property bool isDriving: false
    property bool isCharging: false
    property bool hasFault: false

    signal doorToggleRequested(string doorName)
    signal lockToggleRequested()

    implicitWidth: 320
    implicitHeight: 360
    radius: DesignSystem.radiusXl
    color: DesignSystem.surfaceWell
    border.color: DesignSystem.borderMuted
    border.width: 1
    clip: true

    // Request canvas repaint on any visual property change
    onFrontLeftDoorOpenChanged: chassisCanvas.requestPaint()
    onFrontRightDoorOpenChanged: chassisCanvas.requestPaint()
    onRearLeftDoorOpenChanged: chassisCanvas.requestPaint()
    onRearRightDoorOpenChanged: chassisCanvas.requestPaint()
    onAutoHeadlightsChanged: chassisCanvas.requestPaint()
    onDoorsLockedChanged: chassisCanvas.requestPaint()
    onIsDrivingChanged: chassisCanvas.requestPaint()
    onIsChargingChanged: chassisCanvas.requestPaint()
    onHasFaultChanged: chassisCanvas.requestPaint()

    Canvas {
        id: chassisCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var w = width;
            var h = height;
            if (w <= 0 || h <= 0) return;

            var cx = w * 0.50;
            var cy = h * 0.52;
            var bodyW = Math.min(w * 0.46, 140);
            var bodyH = Math.min(h * 0.74, 250);

            // -----------------------------------------------------------------
            // 1. FORWARD HEADLIGHT BEAMS (when autoHeadlights is active)
            // -----------------------------------------------------------------
            if (root.autoHeadlights) {
                var beamL = ctx.createLinearGradient(cx - bodyW * 0.35, cy - bodyH * 0.50, cx - bodyW * 0.65, cy - bodyH * 0.88);
                beamL.addColorStop(0, Qt.rgba(0.01, 0.52, 0.78, 0.35));
                beamL.addColorStop(1, Qt.rgba(0.01, 0.52, 0.78, 0.00));

                ctx.fillStyle = beamL;
                ctx.beginPath();
                ctx.moveTo(cx - bodyW * 0.36, cy - bodyH * 0.46);
                ctx.lineTo(cx - bodyW * 0.85, cy - bodyH * 0.90);
                ctx.lineTo(cx - bodyW * 0.15, cy - bodyH * 0.90);
                ctx.closePath();
                ctx.fill();

                var beamR = ctx.createLinearGradient(cx + bodyW * 0.35, cy - bodyH * 0.50, cx + bodyW * 0.65, cy - bodyH * 0.88);
                beamR.addColorStop(0, Qt.rgba(0.01, 0.52, 0.78, 0.35));
                beamR.addColorStop(1, Qt.rgba(0.01, 0.52, 0.78, 0.00));

                ctx.fillStyle = beamR;
                ctx.beginPath();
                ctx.moveTo(cx + bodyW * 0.36, cy - bodyH * 0.46);
                ctx.lineTo(cx + bodyW * 0.15, cy - bodyH * 0.90);
                ctx.lineTo(cx + bodyW * 0.85, cy - bodyH * 0.90);
                ctx.closePath();
                ctx.fill();
            }

            // -----------------------------------------------------------------
            // 2. WHEELS (4 corners)
            // -----------------------------------------------------------------
            var wheelW = bodyW * 0.14;
            var wheelH = bodyH * 0.18;
            ctx.fillStyle = "#1E293B";

            // Front Left Wheel
            drawRoundedRect(ctx, cx - bodyW * 0.56, cy - bodyH * 0.36, wheelW, wheelH, 3);
            ctx.fill();
            // Front Right Wheel
            drawRoundedRect(ctx, cx + bodyW * 0.42, cy - bodyH * 0.36, wheelW, wheelH, 3);
            ctx.fill();
            // Rear Left Wheel
            drawRoundedRect(ctx, cx - bodyW * 0.56, cy + bodyH * 0.20, wheelW, wheelH, 3);
            ctx.fill();
            // Rear Right Wheel
            drawRoundedRect(ctx, cx + bodyW * 0.42, cy + bodyH * 0.20, wheelW, wheelH, 3);
            ctx.fill();

            // -----------------------------------------------------------------
            // 3. VEHICLE AERODYNAMIC BODY HULL
            // -----------------------------------------------------------------
            ctx.save();
            ctx.fillStyle = "#FFFFFF";
            ctx.strokeStyle = root.hasFault ? "#DC2626" : (root.isCharging ? "#059669" : "#94A3B8");
            ctx.lineWidth = 2.0;

            // Streamlined outer monocoque
            ctx.beginPath();
            // Front bumper center
            ctx.moveTo(cx, cy - bodyH * 0.50);
            // Front right curved nose
            ctx.bezierCurveTo(cx + bodyW * 0.30, cy - bodyH * 0.50, cx + bodyW * 0.48, cy - bodyH * 0.40, cx + bodyW * 0.48, cy - bodyH * 0.25);
            // Right waistline
            ctx.lineTo(cx + bodyW * 0.48, cy + bodyH * 0.28);
            // Rear right quarter
            ctx.bezierCurveTo(cx + bodyW * 0.48, cy + bodyH * 0.44, cx + bodyW * 0.28, cy + bodyH * 0.49, cx, cy + bodyH * 0.49);
            // Rear left quarter
            ctx.bezierCurveTo(cx - bodyW * 0.28, cy + bodyH * 0.49, cx - bodyW * 0.48, cy + bodyH * 0.44, cx - bodyW * 0.48, cy + bodyH * 0.28);
            // Left waistline
            ctx.lineTo(cx - bodyW * 0.48, cy - bodyH * 0.25);
            // Front left curved nose
            ctx.bezierCurveTo(cx - bodyW * 0.48, cy - bodyH * 0.40, cx - bodyW * 0.30, cy - bodyH * 0.50, cx, cy - bodyH * 0.50);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            // -----------------------------------------------------------------
            // 4. GREENHOUSE / GLASS CANOPY (Windshield & Panoramic Roof)
            // -----------------------------------------------------------------
            ctx.fillStyle = "#E2E8F0";
            ctx.strokeStyle = "#CBD5E1";
            ctx.lineWidth = 1.2;

            // Front Windshield
            ctx.beginPath();
            ctx.moveTo(cx - bodyW * 0.34, cy - bodyH * 0.22);
            ctx.quadraticCurveTo(cx, cy - bodyH * 0.28, cx + bodyW * 0.34, cy - bodyH * 0.22);
            ctx.lineTo(cx + bodyW * 0.30, cy - bodyH * 0.08);
            ctx.quadraticCurveTo(cx, cy - bodyH * 0.10, cx - bodyW * 0.30, cy - bodyH * 0.08);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            // Panoramic Roof Glass
            drawRoundedRect(ctx, cx - bodyW * 0.28, cy - bodyH * 0.04, bodyW * 0.56, bodyH * 0.22, 6);
            ctx.fill();
            ctx.stroke();

            // Rear Windshield
            ctx.beginPath();
            ctx.moveTo(cx - bodyW * 0.28, cy + bodyH * 0.22);
            ctx.quadraticCurveTo(cx, cy + bodyH * 0.20, cx + bodyW * 0.28, cy + bodyH * 0.22);
            ctx.lineTo(cx + bodyW * 0.32, cy + bodyH * 0.34);
            ctx.quadraticCurveTo(cx, cy + bodyH * 0.36, cx - bodyW * 0.32, cy + bodyH * 0.34);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            // -----------------------------------------------------------------
            // 5. FOUR DOORS (Rendered Closed or Swung Open)
            // -----------------------------------------------------------------
            var doorColor = root.doorsLocked ? "#0284C7" : "#64748B";
            var openDoorColor = "#D97706";

            // Front Left Door
            drawDoorWing(ctx, cx - bodyW * 0.48, cy - bodyH * 0.16, bodyH * 0.20, -1, root.frontLeftDoorOpen, openDoorColor, doorColor);
            // Front Right Door
            drawDoorWing(ctx, cx + bodyW * 0.48, cy - bodyH * 0.16, bodyH * 0.20, 1, root.frontRightDoorOpen, openDoorColor, doorColor);
            // Rear Left Door
            drawDoorWing(ctx, cx - bodyW * 0.48, cy + bodyH * 0.06, bodyH * 0.18, -1, root.rearLeftDoorOpen, openDoorColor, doorColor);
            // Rear Right Door
            drawDoorWing(ctx, cx + bodyW * 0.48, cy + bodyH * 0.06, bodyH * 0.18, 1, root.rearRightDoorOpen, openDoorColor, doorColor);

            ctx.restore();
        }

        // Helper: Draw rounded rectangle
        function drawRoundedRect(ctx, x, y, w, h, r) {
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.arcTo(x + w, y, x + w, y + h, r);
            ctx.arcTo(x + w, y + h, x, y + h, r);
            ctx.arcTo(x, y + h, x, y, r);
            ctx.arcTo(x, y, x + w, y, r);
            ctx.closePath();
        }

        // Helper: Draw door outline or swung open wing
        function drawDoorWing(ctx, hx, hy, len, side, isOpen, openColor, closedColor) {
            ctx.save();
            ctx.lineWidth = isOpen ? 3.0 : 2.0;
            ctx.strokeStyle = isOpen ? openColor : closedColor;

            if (isOpen) {
                // Swung open at angle
                var openAngle = side * 0.45; // ~26 degrees outward
                var endX = hx + Math.sin(openAngle) * len * 0.9;
                var endY = hy + Math.cos(openAngle) * len * 0.9;

                ctx.beginPath();
                ctx.moveTo(hx, hy);
                ctx.lineTo(endX, endY);
                ctx.stroke();

                // Warning indicator dot at tip
                ctx.fillStyle = openColor;
                ctx.beginPath();
                ctx.arc(endX, endY, 4, 0, Math.PI * 2);
                ctx.fill();
            } else {
                // Closed along waistline
                ctx.beginPath();
                ctx.moveTo(hx, hy);
                ctx.lineTo(hx, hy + len);
                ctx.stroke();
            }
            ctx.restore();
        }
    }

    // =========================================================================
    // INTERACTIVE DOOR TOUCH TARGETS (Direct manipulation of 4 doors)
    // =========================================================================
    // Front Left Door Touch Target
    MouseArea {
        width: 48; height: 52
        anchors.left: parent.left; anchors.leftMargin: 20
        anchors.top: parent.top; anchors.topMargin: 120
        cursorShape: Qt.PointingHandCursor
        onClicked: root.doorToggleRequested("FL")
    }

    // Front Right Door Touch Target
    MouseArea {
        width: 48; height: 52
        anchors.right: parent.right; anchors.rightMargin: 20
        anchors.top: parent.top; anchors.topMargin: 120
        cursorShape: Qt.PointingHandCursor
        onClicked: root.doorToggleRequested("FR")
    }

    // Rear Left Door Touch Target
    MouseArea {
        width: 48; height: 52
        anchors.left: parent.left; anchors.leftMargin: 20
        anchors.top: parent.top; anchors.topMargin: 180
        cursorShape: Qt.PointingHandCursor
        onClicked: root.doorToggleRequested("RL")
    }

    // Rear Right Door Touch Target
    MouseArea {
        width: 48; height: 52
        anchors.right: parent.right; anchors.rightMargin: 20
        anchors.top: parent.top; anchors.topMargin: 180
        cursorShape: Qt.PointingHandCursor
        onClicked: root.doorToggleRequested("RR")
    }

    // =========================================================================
    // STATUS HUD BADGES & OVERLAYS
    // =========================================================================
    // Top HUD: Interactive Lock / Security Pill
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: DesignSystem.spacingSm
        implicitHeight: 28
        implicitWidth: lockRow.implicitWidth + 20
        radius: DesignSystem.radiusPill
        color: root.doorsLocked ? Qt.rgba(0.01, 0.52, 0.78, 0.12) : Qt.rgba(0.85, 0.47, 0.02, 0.12)
        border.color: root.doorsLocked ? DesignSystem.accentCyan : DesignSystem.accentAmber
        border.width: 1

        Row {
            id: lockRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.doorsLocked ? "🔒" : "🔓"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.doorsLocked ? "DOORS SECURED" : "DOORS UNLOCKED"
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeMicro
                font.weight: DesignSystem.fontWeightBold
                color: root.doorsLocked ? DesignSystem.accentCyan : DesignSystem.accentAmber
                font.letterSpacing: 0.6
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.lockToggleRequested()
        }
    }

    // Bottom HUD: Door status summary
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: DesignSystem.spacingSm
        text: (root.frontLeftDoorOpen || root.frontRightDoorOpen || root.rearLeftDoorOpen || root.rearRightDoorOpen) ?
              "⚠️ Closure Ajar • Tap car doors to toggle" : "All Closures & Latches Sealed"
        font.family: DesignSystem.fontFamily
        font.pixelSize: DesignSystem.fontSizeCaption
        font.weight: DesignSystem.fontWeightBold
        color: (root.frontLeftDoorOpen || root.frontRightDoorOpen || root.rearLeftDoorOpen || root.rearRightDoorOpen) ?
               DesignSystem.accentAmber : DesignSystem.textSecondary
    }
}
