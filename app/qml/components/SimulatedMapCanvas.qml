import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    // =========================================================================
    // PROPERTIES
    // =========================================================================
    property string destinationName: "Mysuru Palace"
    property string destinationIcon: "🏰"
    property string etaFormatted: "18 min"
    property real destX: 0.74
    property real destY: 0.26
    property bool isNavigating: true
    property bool isDriving: false
    property real mapScale: 1.0

    signal recenterRequested()

    implicitWidth: 600
    implicitHeight: 600
    color: "#F1F5F9"
    clip: true

    // Vehicle position along route (normalized)
    property real vehicleProgress: isDriving ? 0.42 : 0.26

    NumberAnimation on vehicleProgress {
        from: 0.20
        to: 0.65
        duration: 18000
        loops: Animation.Infinite
        running: root.isDriving && root.isNavigating
    }

    // Dynamic Route Stream pulse phase
    property real streamPhase: 0.0

    NumberAnimation on streamPhase {
        from: 0.0
        to: 40.0
        duration: 1600
        loops: Animation.Infinite
        running: root.isNavigating
    }

    onDestXChanged: mapCanvas.requestPaint()
    onDestYChanged: mapCanvas.requestPaint()
    onDestinationNameChanged: mapCanvas.requestPaint()
    onIsNavigatingChanged: mapCanvas.requestPaint()
    onIsDrivingChanged: mapCanvas.requestPaint()
    onVehicleProgressChanged: mapCanvas.requestPaint()
    onStreamPhaseChanged: mapCanvas.requestPaint()
    onMapScaleChanged: mapCanvas.requestPaint()

    Canvas {
        id: mapCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var w = width;
            var h = height;
            if (w <= 0 || h <= 0) return;

            // -----------------------------------------------------------------
            // 1. TERRAIN & NATURE FOUNDATION
            // -----------------------------------------------------------------
            // Base Alabaster Landmass
            ctx.fillStyle = "#F8FAFC";
            ctx.fillRect(0, 0, w, h);

            // Green Parks / Sanctuaries
            ctx.fillStyle = Qt.rgba(0.05, 0.65, 0.40, 0.08);

            // Park 1: Karanji Nature Sanctuary (Top Center)
            drawRoundedRect(ctx, w * 0.48, h * 0.12, w * 0.26, h * 0.18, 16);
            ctx.fill();

            // Park 2: Chamundi Foothills Reserve (Bottom Right)
            drawRoundedRect(ctx, w * 0.58, h * 0.65, w * 0.36, h * 0.28, 20);
            ctx.fill();

            // Park 3: University Botanical Gardens (Bottom Left)
            drawRoundedRect(ctx, w * 0.08, h * 0.60, w * 0.24, h * 0.22, 16);
            ctx.fill();

            // Water Feature: Curving River / Lake
            ctx.fillStyle = Qt.rgba(0.01, 0.52, 0.78, 0.10);
            ctx.strokeStyle = Qt.rgba(0.01, 0.52, 0.78, 0.25);
            ctx.lineWidth = 1.5;
            ctx.beginPath();
            ctx.moveTo(w * 0.88, 0);
            ctx.bezierCurveTo(w * 0.82, h * 0.25, w * 0.92, h * 0.50, w * 0.84, h);
            ctx.lineTo(w, h);
            ctx.lineTo(w, 0);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();

            // -----------------------------------------------------------------
            // 2. SECONDARY CITY STREET GRID
            // -----------------------------------------------------------------
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 8;
            ctx.lineCap = "round";

            // Horizontal Grid Avenues
            drawRoadSegment(ctx, 0, h * 0.24, w, h * 0.24, "#E2E8F0", 8);
            drawRoadSegment(ctx, 0, h * 0.44, w, h * 0.44, "#E2E8F0", 8);
            drawRoadSegment(ctx, 0, h * 0.64, w, h * 0.64, "#E2E8F0", 8);
            drawRoadSegment(ctx, 0, h * 0.84, w, h * 0.84, "#E2E8F0", 8);

            // Vertical Grid Streets
            drawRoadSegment(ctx, w * 0.20, 0, w * 0.20, h, "#E2E8F0", 8);
            drawRoadSegment(ctx, w * 0.42, 0, w * 0.42, h, "#E2E8F0", 8);
            drawRoadSegment(ctx, w * 0.64, 0, w * 0.64, h, "#E2E8F0", 8);

            // -----------------------------------------------------------------
            // 3. MAJOR HIGHWAYS & ARTERIAL BOULEVARDS
            // -----------------------------------------------------------------
            // Arterial 1: Outer Ring Highway (Diagonally Across)
            drawRoadSegment(ctx, 0, h * 0.78, w * 0.85, 0, "#CBD5E1", 16);
            drawRoadSegment(ctx, 0, h * 0.78, w * 0.85, 0, "#FFFFFF", 12);

            // Arterial 2: Cyberway Expressway (Vertical Spine)
            drawRoadSegment(ctx, w * 0.48, 0, w * 0.48, h, "#CBD5E1", 16);
            drawRoadSegment(ctx, w * 0.48, 0, w * 0.48, h, "#FFFFFF", 12);

            // Circular Roundabout Junction
            var rbx = w * 0.48;
            var rby = h * 0.52;
            var rbRadius = 34;

            ctx.beginPath();
            ctx.arc(rbx, rby, rbRadius + 3, 0, Math.PI * 2);
            ctx.fillStyle = "#CBD5E1";
            ctx.fill();

            ctx.beginPath();
            ctx.arc(rbx, rby, rbRadius, 0, Math.PI * 2);
            ctx.fillStyle = "#FFFFFF";
            ctx.fill();

            ctx.beginPath();
            ctx.arc(rbx, rby, rbRadius - 12, 0, Math.PI * 2);
            ctx.fillStyle = Qt.rgba(0.05, 0.65, 0.40, 0.15); // Roundabout landscaped center
            ctx.fill();

            // -----------------------------------------------------------------
            // 4. ALTERNATIVE ROUTE LINE (Subtle gray dashed path)
            // -----------------------------------------------------------------
            if (root.isNavigating) {
                ctx.save();
                ctx.strokeStyle = "#94A3B8";
                ctx.lineWidth = 5;
                ctx.setLineDash([8, 8]);
                ctx.beginPath();
                ctx.moveTo(w * 0.20, h * 0.78);
                ctx.lineTo(w * 0.20, h * 0.44);
                ctx.lineTo(w * 0.48, h * 0.44);
                ctx.lineTo(w * 0.64, h * 0.44);
                ctx.lineTo(root.destX * w, root.destY * h);
                ctx.stroke();
                ctx.restore();
            }

            // -----------------------------------------------------------------
            // 5. ACTIVE NAVIGATION ROUTE LINE (Cobalt Blue Polyline)
            // -----------------------------------------------------------------
            var startX = w * 0.20;
            var startY = h * 0.78;
            var midX = rbx;
            var midY = rby;
            var turnX = w * 0.48;
            var turnY = h * 0.26;
            var targetX = root.destX * w;
            var targetY = root.destY * h;

            if (root.isNavigating) {
                // Route outer casing / glow
                ctx.save();
                ctx.strokeStyle = Qt.rgba(0.01, 0.52, 0.78, 0.24);
                ctx.lineWidth = 14;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                drawRoutePath(ctx, startX, startY, midX, midY, turnX, turnY, targetX, targetY);
                ctx.stroke();

                // Route main cobalt ribbon
                ctx.strokeStyle = "#0284C7";
                ctx.lineWidth = 8;
                drawRoutePath(ctx, startX, startY, midX, midY, turnX, turnY, targetX, targetY);
                ctx.stroke();

                // Animated directional stream chevrons
                ctx.strokeStyle = "#FFFFFF";
                ctx.lineWidth = 2.5;
                ctx.setLineDash([10, 16]);
                ctx.lineDashOffset = -root.streamPhase;
                drawRoutePath(ctx, startX, startY, midX, midY, turnX, turnY, targetX, targetY);
                ctx.stroke();
                ctx.restore();
            }

            // -----------------------------------------------------------------
            // 6. CURRENT VEHICLE POSITION BEACON (Puck with Directional Cone)
            // -----------------------------------------------------------------
            var vPos = getPointAlongRoute(root.vehicleProgress, startX, startY, midX, midY, turnX, turnY, targetX, targetY);
            var vx = vPos.x;
            var vy = vPos.y;

            // Radar pulse ring
            ctx.save();
            ctx.beginPath();
            ctx.arc(vx, vy, 22, 0, Math.PI * 2);
            ctx.fillStyle = Qt.rgba(0.01, 0.52, 0.78, 0.18);
            ctx.fill();

            // Vehicle Puck Shadow
            ctx.beginPath();
            ctx.arc(vx, vy + 2, 12, 0, Math.PI * 2);
            ctx.fillStyle = "rgba(15, 23, 42, 0.20)";
            ctx.fill();

            // Vehicle Puck White Border
            ctx.beginPath();
            ctx.arc(vx, vy, 11, 0, Math.PI * 2);
            ctx.fillStyle = "#FFFFFF";
            ctx.fill();

            // Vehicle Puck Core Blue Fill
            ctx.beginPath();
            ctx.arc(vx, vy, 8, 0, Math.PI * 2);
            ctx.fillStyle = "#0284C7";
            ctx.fill();

            // Forward Heading Arrow (Directional Chevron)
            ctx.fillStyle = "#FFFFFF";
            ctx.beginPath();
            ctx.moveTo(vx, vy - 5);
            ctx.lineTo(vx + 3.5, vy + 3);
            ctx.lineTo(vx, vy + 1.5);
            ctx.lineTo(vx - 3.5, vy + 3);
            ctx.closePath();
            ctx.fill();
            ctx.restore();

            // -----------------------------------------------------------------
            // 7. DESTINATION PIN & FLOATING BANNER
            // -----------------------------------------------------------------
            if (root.isNavigating) {
                ctx.save();
                // Pin Shadow
                ctx.beginPath();
                ctx.ellipse(targetX, targetY + 2, 8, 4, 0, 0, Math.PI * 2);
                ctx.fillStyle = "rgba(15, 23, 42, 0.25)";
                ctx.fill();

                // Pin Stem & Teardrop
                ctx.beginPath();
                ctx.moveTo(targetX, targetY);
                ctx.bezierCurveTo(targetX - 10, targetY - 12, targetX - 12, targetY - 24, targetX, targetY - 24);
                ctx.bezierCurveTo(targetX + 12, targetY - 24, targetX + 10, targetY - 12, targetX, targetY);
                ctx.fillStyle = "#DC2626";
                ctx.fill();
                ctx.strokeStyle = "#FFFFFF";
                ctx.lineWidth = 1.5;
                ctx.stroke();

                // Inner Pin White Dot
                ctx.beginPath();
                ctx.arc(targetX, targetY - 15, 4, 0, Math.PI * 2);
                ctx.fillStyle = "#FFFFFF";
                ctx.fill();
                ctx.restore();
            }

            // -----------------------------------------------------------------
            // 8. LANDMARK LABELS
            // -----------------------------------------------------------------
            drawLandmark(ctx, w * 0.74, h * 0.22, "🏰 Mysuru Palace", true);
            drawLandmark(ctx, w * 0.32, h * 0.74, "🏫 Technology Campus", false);
            drawLandmark(ctx, w * 0.82, h * 0.68, "🏢 Cyber Park Tech", false);
            drawLandmark(ctx, w * 0.52, h * 0.16, "🌳 Karanji Lake", false);
            drawLandmark(ctx, w * 0.44, h * 0.88, "⚡ 150 kW Supercharger", false);
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

        // Helper: Draw street segment with casing
        function drawRoadSegment(ctx, x1, y1, x2, y2, color, width) {
            ctx.save();
            ctx.strokeStyle = color;
            ctx.lineWidth = width;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(x1, y1);
            ctx.lineTo(x2, y2);
            ctx.stroke();
            ctx.restore();
        }

        // Helper: Draw route polyline
        function drawRoutePath(ctx, sx, sy, mx, my, tx, ty, dx, dy) {
            ctx.beginPath();
            ctx.moveTo(sx, sy);
            ctx.lineTo(mx, my);
            ctx.lineTo(tx, ty);
            ctx.lineTo(dx, dy);
        }

        // Helper: Calculate point along piecewise route for vehicle puck
        function getPointAlongRoute(t, sx, sy, mx, my, tx, ty, dx, dy) {
            if (t <= 0.35) {
                var localT = t / 0.35;
                return { x: sx + (mx - sx) * localT, y: sy + (my - sy) * localT };
            } else if (t <= 0.70) {
                var localT = (t - 0.35) / 0.35;
                return { x: mx + (tx - mx) * localT, y: my + (ty - my) * localT };
            } else {
                var localT = (t - 0.70) / 0.30;
                return { x: tx + (dx - tx) * localT, y: ty + (dy - ty) * localT };
            }
        }

        // Helper: Draw landmark tag
        function drawLandmark(ctx, x, y, label, isHighlight) {
            ctx.save();
            ctx.font = "bold 11px Inter, sans-serif";
            var textMetrics = ctx.measureText(label);
            var padX = 8;
            var padY = 5;
            var boxW = textMetrics.width + padX * 2;
            var boxH = 22;

            drawRoundedRect(ctx, x - boxW * 0.5, y - boxH * 0.5, boxW, boxH, 11);
            ctx.fillStyle = isHighlight ? "#0F172A" : "rgba(255, 255, 255, 0.92)";
            ctx.fill();
            ctx.strokeStyle = isHighlight ? "#0F172A" : "#CBD5E1";
            ctx.lineWidth = 1;
            ctx.stroke();

            ctx.fillStyle = isHighlight ? "#FFFFFF" : "#334155";
            ctx.textBaseline = "middle";
            ctx.textAlign = "center";
            ctx.fillText(label, x, y + 1);
            ctx.restore();
        }
    }

    // =========================================================================
    // FLOATING MAP CONTROL OVERLAYS (Recenter, Compass, Zoom)
    // =========================================================================
    // Top-right Compass Rose
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: DesignSystem.spacingMd
        width: 44
        height: 44
        radius: 22
        color: DesignSystem.surface
        border.color: DesignSystem.borderMuted
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 0

            Text {
                text: "▲"
                font.pixelSize: 10
                color: "#DC2626"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "N"
                font.family: DesignSystem.fontFamily
                font.pixelSize: 11
                font.weight: DesignSystem.fontWeightBold
                color: DesignSystem.textPrimary
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.recenterRequested()
        }
    }

    // Right-edge Map Steppers (Zoom In, Zoom Out, Recenter)
    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm

        // Recenter Button
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: DesignSystem.surface
            border.color: DesignSystem.borderMuted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "⌖"
                font.pixelSize: 20
                color: DesignSystem.accentCyan
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.recenterRequested()
            }
        }

        // Zoom In Button
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: DesignSystem.surface
            border.color: DesignSystem.borderMuted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "+"
                font.family: DesignSystem.fontFamily
                font.pixelSize: 20
                font.weight: DesignSystem.fontWeightBold
                color: DesignSystem.textPrimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.mapScale = Math.min(1.6, root.mapScale + 0.15)
            }
        }

        // Zoom Out Button
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: DesignSystem.surface
            border.color: DesignSystem.borderMuted
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "−"
                font.family: DesignSystem.fontFamily
                font.pixelSize: 22
                font.weight: DesignSystem.fontWeightBold
                color: DesignSystem.textPrimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.mapScale = Math.max(0.6, root.mapScale - 0.15)
            }
        }
    }

    // Bottom-right Map Metric Scale
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: DesignSystem.spacingMd
        implicitHeight: 22
        implicitWidth: scaleRow.implicitWidth + 14
        radius: DesignSystem.radiusPill
        color: Qt.rgba(255, 255, 255, 0.88)
        border.color: DesignSystem.borderMuted
        border.width: 1

        Row {
            id: scaleRow
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                width: 28
                height: 2
                color: DesignSystem.textPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "200 m"
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeMicro
                font.weight: DesignSystem.fontWeightMedium
                color: DesignSystem.textSecondary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
