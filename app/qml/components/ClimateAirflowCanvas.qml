import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    // =========================================================================
    // PROPERTIES
    // =========================================================================
    property int fanSpeed: 2
    property string airflowMode: "vent" // "windshield", "vent", "floor", "bilevel"
    property bool isHeating: false
    property bool isCooling: true
    property bool isAcActive: true
    property bool isFrontDefrost: false
    property bool isRearDefrost: false
    property string cabinTemperatureFormatted: "21.5°C"
    property string targetTemperatureFormatted: "22.0°"

    implicitWidth: 440
    implicitHeight: 260
    radius: DesignSystem.radiusXl
    color: DesignSystem.surfaceCard
    border.color: DesignSystem.borderMuted
    border.width: 1
    clip: true

    // =========================================================================
    // ANIMATION PHASE (Scales speed smoothly with fan level)
    // =========================================================================
    property real flowOffset: 0.0

    NumberAnimation {
        id: flowAnim
        target: root
        property: "flowOffset"
        from: 0.0
        to: 36.0
        duration: root.fanSpeed > 0 ? Math.max(900, 3200 - (root.fanSpeed * 450)) : 4000
        loops: Animation.Infinite
        running: root.fanSpeed > 0
    }

    // Trigger canvas repaint when phase or state changes
    onFlowOffsetChanged: airflowCanvas.requestPaint()
    onAirflowModeChanged: airflowCanvas.requestPaint()
    onFanSpeedChanged: airflowCanvas.requestPaint()
    onIsHeatingChanged: airflowCanvas.requestPaint()
    onIsCoolingChanged: airflowCanvas.requestPaint()
    onIsFrontDefrostChanged: airflowCanvas.requestPaint()

    Canvas {
        id: airflowCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var w = width;
            var h = height;
            if (w <= 0 || h <= 0) return;

            // -----------------------------------------------------------------
            // 1. CABIN AMBIENT THERMAL BACKDROP
            // -----------------------------------------------------------------
            var activeColor = root.isHeating ? "#D97706" : (root.isCooling ? "#0284C7" : "#64748B");
            var auraGrad = ctx.createRadialGradient(w * 0.5, h * 0.55, 10, w * 0.5, h * 0.55, w * 0.45);
            if (root.fanSpeed > 0) {
                auraGrad.addColorStop(0, root.isHeating ? Qt.rgba(0.85, 0.47, 0.02, 0.09) :
                                         (root.isCooling ? Qt.rgba(0.01, 0.52, 0.78, 0.09) : Qt.rgba(0.39, 0.45, 0.55, 0.05)));
                auraGrad.addColorStop(1, Qt.rgba(1, 1, 1, 0));
                ctx.fillStyle = auraGrad;
                ctx.fillRect(0, 0, w, h);
            }

            // -----------------------------------------------------------------
            // 2. VEHICLE CABIN TOP-DOWN ARCHITECTURE SCHEMATIC
            // -----------------------------------------------------------------
            ctx.strokeStyle = "#CBD5E1";
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";

            // Windshield Curved Boundary (Front)
            ctx.beginPath();
            ctx.moveTo(w * 0.22, h * 0.24);
            ctx.quadraticCurveTo(w * 0.50, h * 0.16, w * 0.78, h * 0.24);
            ctx.stroke();

            // Dashboard Horizontal Bar
            ctx.beginPath();
            ctx.moveTo(w * 0.20, h * 0.32);
            ctx.lineTo(w * 0.80, h * 0.32);
            ctx.strokeStyle = "#94A3B8";
            ctx.lineWidth = 2.0;
            ctx.stroke();

            // Center Console Tunnel
            ctx.beginPath();
            ctx.moveTo(w * 0.47, h * 0.32);
            ctx.lineTo(w * 0.47, h * 0.85);
            ctx.moveTo(w * 0.53, h * 0.32);
            ctx.lineTo(w * 0.53, h * 0.85);
            ctx.strokeStyle = "#E2E8F0";
            ctx.lineWidth = 1.5;
            ctx.stroke();

            // Driver Seat (Left)
            drawSeat(ctx, w * 0.32, h * 0.58, w * 0.14, h * 0.26);

            // Passenger Seat (Right)
            drawSeat(ctx, w * 0.68, h * 0.58, w * 0.14, h * 0.26);

            // -----------------------------------------------------------------
            // 3. AIR VENT NOZZLES (Dash, Windshield, Floor)
            // -----------------------------------------------------------------
            var mode = root.airflowMode;
            var isDefrost = mode === "windshield" || root.isFrontDefrost;
            var isVent = mode === "vent" || mode === "bilevel";
            var isFloor = mode === "floor" || mode === "bilevel";

            // Windshield Vent Louvers (Top)
            drawVentNozzle(ctx, w * 0.50, h * 0.21, 54, 4, isDefrost ? activeColor : "#CBD5E1", isDefrost);

            // Dash Face Vent Louvers (Center Left & Center Right)
            drawVentNozzle(ctx, w * 0.32, h * 0.32, 38, 4, isVent ? activeColor : "#CBD5E1", isVent);
            drawVentNozzle(ctx, w * 0.68, h * 0.32, 38, 4, isVent ? activeColor : "#CBD5E1", isVent);

            // Lower Footwell Vents (Bottom of console)
            drawVentNozzle(ctx, w * 0.44, h * 0.68, 16, 4, isFloor ? activeColor : "#CBD5E1", isFloor);
            drawVentNozzle(ctx, w * 0.56, h * 0.68, 16, 4, isFloor ? activeColor : "#CBD5E1", isFloor);

            // -----------------------------------------------------------------
            // 4. ANIMATED AIRFLOW STREAMLINES
            // -----------------------------------------------------------------
            if (root.fanSpeed > 0) {
                var streamColor = root.isHeating ? Qt.rgba(0.85, 0.47, 0.02, 0.68) :
                                  (root.isCooling ? Qt.rgba(0.01, 0.52, 0.78, 0.72) : Qt.rgba(0.39, 0.45, 0.55, 0.55));
                ctx.strokeStyle = streamColor;
                ctx.lineWidth = Math.min(2.5, 1.2 + root.fanSpeed * 0.25);
                ctx.setLineDash([8, 6]);
                ctx.lineDashOffset = -root.flowOffset;

                // Defrost Airflow (Windshield upward sweep)
                if (isDefrost) {
                    ctx.beginPath();
                    ctx.moveTo(w * 0.42, h * 0.21);
                    ctx.quadraticCurveTo(w * 0.34, h * 0.17, w * 0.28, h * 0.22);
                    ctx.moveTo(w * 0.50, h * 0.20);
                    ctx.lineTo(w * 0.50, h * 0.15);
                    ctx.moveTo(w * 0.58, h * 0.21);
                    ctx.quadraticCurveTo(w * 0.66, h * 0.17, w * 0.72, h * 0.22);
                    ctx.stroke();
                }

                // Vent Airflow (Face / Torso direct flow)
                if (isVent) {
                    // Left (Driver) Airflow Streams
                    ctx.beginPath();
                    ctx.moveTo(w * 0.28, h * 0.33);
                    ctx.lineTo(w * 0.27, h * 0.48);
                    ctx.moveTo(w * 0.32, h * 0.33);
                    ctx.lineTo(w * 0.32, h * 0.52);
                    ctx.moveTo(w * 0.36, h * 0.33);
                    ctx.lineTo(w * 0.37, h * 0.48);

                    // Right (Passenger) Airflow Streams
                    ctx.moveTo(w * 0.64, h * 0.33);
                    ctx.lineTo(w * 0.63, h * 0.48);
                    ctx.moveTo(w * 0.68, h * 0.33);
                    ctx.lineTo(w * 0.68, h * 0.52);
                    ctx.moveTo(w * 0.72, h * 0.33);
                    ctx.lineTo(w * 0.73, h * 0.48);
                    ctx.stroke();
                }

                // Floor Airflow (Footwell side curves)
                if (isFloor) {
                    ctx.beginPath();
                    // Left Footwell
                    ctx.moveTo(w * 0.44, h * 0.68);
                    ctx.quadraticCurveTo(w * 0.36, h * 0.72, w * 0.32, h * 0.78);
                    // Right Footwell
                    ctx.moveTo(w * 0.56, h * 0.68);
                    ctx.quadraticCurveTo(w * 0.64, h * 0.72, w * 0.68, h * 0.78);
                    ctx.stroke();
                }

                // Reset Dash
                ctx.setLineDash([]);
            }
        }

        // Helper: Safe rounded rectangle for Qt Canvas 2D
        function drawRoundedRect(ctx, x, y, w, h, r) {
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.arcTo(x + w, y, x + w, y + h, r);
            ctx.arcTo(x + w, y + h, x, y + h, r);
            ctx.arcTo(x, y + h, x, y, r);
            ctx.arcTo(x, y, x + w, y, r);
            ctx.closePath();
        }

        // Helper: Draw stylized automotive bucket seat
        function drawSeat(ctx, cx, cy, sw, sh) {
            ctx.save();
            ctx.fillStyle = "#F8FAFC";
            ctx.strokeStyle = "#CBD5E1";
            ctx.lineWidth = 1.2;

            // Seat Cushion Base
            var rx = cx - sw * 0.5;
            var ry = cy - sh * 0.5;
            drawRoundedRect(ctx, rx, ry + sh * 0.25, sw, sh * 0.70, 6);
            ctx.fill();
            ctx.stroke();

            // Headrest
            drawRoundedRect(ctx, cx - sw * 0.25, ry, sw * 0.50, sh * 0.20, 4);
            ctx.fill();
            ctx.stroke();

            ctx.restore();
        }

        // Helper: Draw vent nozzle with active glow
        function drawVentNozzle(ctx, x, y, width, height, color, isActive) {
            ctx.save();
            ctx.fillStyle = color;
            drawRoundedRect(ctx, x - width * 0.5, y - height * 0.5, width, height, 2);
            ctx.fill();

            if (isActive) {
                ctx.shadowColor = color;
                ctx.shadowBlur = 6;
                ctx.fill();
            }
            ctx.restore();
        }
    }

    // =========================================================================
    // INFORMATIVE HUD OVERLAYS
    // =========================================================================
    // Top-left: Active Mode & Blower Status
    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: DesignSystem.spacingMd
        spacing: 6

        Rectangle {
            implicitHeight: 24
            implicitWidth: modeLabel.implicitWidth + 16
            radius: DesignSystem.radiusPill
            color: DesignSystem.surfaceWell
            border.color: DesignSystem.borderMuted
            border.width: 1

            Text {
                id: modeLabel
                anchors.centerIn: parent
                text: root.airflowMode.toUpperCase() + (root.isFrontDefrost ? " + DEFROST" : "")
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeMicro
                font.weight: DesignSystem.fontWeightBold
                color: DesignSystem.textSecondary
                font.letterSpacing: 0.6
            }
        }

        Rectangle {
            implicitHeight: 24
            implicitWidth: blowerLabel.implicitWidth + 16
            radius: DesignSystem.radiusPill
            color: root.fanSpeed > 0 ? Qt.rgba(0.01, 0.52, 0.78, 0.12) : DesignSystem.surfaceWell
            border.color: root.fanSpeed > 0 ? DesignSystem.accentCyan : DesignSystem.borderMuted
            border.width: 1

            Text {
                id: blowerLabel
                anchors.centerIn: parent
                text: root.fanSpeed === 0 ? "FAN OFF" : ("BLOWER LVL " + root.fanSpeed)
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeMicro
                font.weight: DesignSystem.fontWeightBold
                color: root.fanSpeed > 0 ? DesignSystem.accentCyan : DesignSystem.textMuted
                font.letterSpacing: 0.5
            }
        }
    }

    // Top-right: Cabin vs Outside Temperature Readout
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm

        Text {
            text: "INTERIOR AIRFLOW SCHEMATIC"
            font.family: DesignSystem.fontFamily
            font.pixelSize: DesignSystem.fontSizeMicro
            font.weight: DesignSystem.fontWeightBold
            color: DesignSystem.textMuted
            font.letterSpacing: 0.8
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Bottom-center: Subtitle note
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: DesignSystem.spacingSm
        text: root.fanSpeed === 0 ? "Cabin airflow is currently suspended" :
              (root.isHeating ? "Distributing warm air to target " + root.targetTemperatureFormatted :
               (root.isCooling ? "Conditioning cabin air with active refrigeration" : "Cabin thermal balance maintained"))
        font.family: DesignSystem.fontFamily
        font.pixelSize: DesignSystem.fontSizeCaption
        font.weight: DesignSystem.fontWeightMedium
        color: DesignSystem.textSecondary
    }
}
