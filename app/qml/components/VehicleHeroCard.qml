import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string vehicleState: "PARKED"      // "PARKED", "DRIVING", "CHARGING", "FAULT"
    property string stateSubtitle: "Ready to drive"
    property string speed: "0"
    property string gear: "P"
    property real batterySoc: 92.0
    property string rangeFormatted: "410 km"
    property string driveMode: "COMFORT"

    signal clicked()
    signal cycleDriveModeRequested()

    radius: DesignSystem.radiusLg
    color: DesignSystem.surfaceCard
    border.color: DesignSystem.borderMuted
    border.width: 1

    // Soft Ambient Card Shadow
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        anchors.bottomMargin: -4
        radius: parent.radius
        color: DesignSystem.shadowAmbient
        z: -1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingLg
        spacing: DesignSystem.spacingMd

        // Top Row: Dominant State Chip + Subtitle + Transmission & Drive Mode
        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingMd

            // Dominant State Badge
            Rectangle {
                height: 36
                radius: DesignSystem.radiusPill
                color: {
                    if (root.vehicleState === "PARKED") return Qt.rgba(5, 150, 105, 0.10)
                    if (root.vehicleState === "DRIVING") return Qt.rgba(2, 132, 199, 0.10)
                    if (root.vehicleState === "CHARGING") return Qt.rgba(16, 185, 129, 0.15)
                    if (root.vehicleState === "FAULT") return Qt.rgba(220, 38, 38, 0.10)
                    return Qt.rgba(5, 150, 105, 0.10)
                }
                border.color: {
                    if (root.vehicleState === "PARKED") return DesignSystem.accentEmerald
                    if (root.vehicleState === "DRIVING") return DesignSystem.accentCyan
                    if (root.vehicleState === "CHARGING") return DesignSystem.accentEmerald
                    if (root.vehicleState === "FAULT") return DesignSystem.accentRuby
                    return DesignSystem.accentEmerald
                }
                border.width: 1
                implicitWidth: stateRow.implicitWidth + 24

                Row {
                    id: stateRow
                    anchors.centerIn: parent
                    spacing: 8

                    // State Status Dot
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: {
                            if (root.vehicleState === "PARKED") return DesignSystem.accentEmerald
                            if (root.vehicleState === "DRIVING") return DesignSystem.accentCyan
                            if (root.vehicleState === "CHARGING") return DesignSystem.accentEmerald
                            if (root.vehicleState === "FAULT") return DesignSystem.accentRuby
                            return DesignSystem.accentEmerald
                        }

                        // Subtle breathing animation for active states
                        SequentialAnimation on opacity {
                            running: root.vehicleState !== "PARKED"
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        text: root.vehicleState
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightBold
                        color: {
                            if (root.vehicleState === "PARKED") return DesignSystem.accentEmerald
                            if (root.vehicleState === "DRIVING") return DesignSystem.accentCyan
                            if (root.vehicleState === "CHARGING") return DesignSystem.accentEmerald
                            if (root.vehicleState === "FAULT") return DesignSystem.accentRuby
                            return DesignSystem.accentEmerald
                        }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Contextual Status Subtitle
            Text {
                text: root.stateSubtitle
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeSubtitle
                font.weight: DesignSystem.fontWeightMedium
                color: DesignSystem.textPrimary
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Transmission Gear Badge
            Rectangle {
                width: 38
                height: 38
                radius: DesignSystem.radiusSm
                color: root.gear === "D"
                       ? Qt.rgba(2, 132, 199, 0.12)
                       : DesignSystem.surfaceWell
                border.color: root.gear === "D" ? DesignSystem.accentCyan : DesignSystem.borderMuted
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.gear
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: root.gear === "D" ? DesignSystem.accentCyan : DesignSystem.textPrimary
                }
            }

            // Drive Mode Interactive Chip
            Rectangle {
                height: 38
                radius: DesignSystem.radiusSm
                color: DesignSystem.surfaceWell
                border.color: DesignSystem.borderMuted
                border.width: 1
                implicitWidth: modeText.implicitWidth + 24

                Text {
                    id: modeText
                    anchors.centerIn: parent
                    text: root.driveMode
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleDriveModeRequested()
                }
            }
        }

        // Center Area: Vehicle Technical Vector Silhouette & Speed Display
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: DesignSystem.spacingLg

                // Vehicle Technical Canvas Illustration
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Canvas {
                        id: vehicleCanvas
                        anchors.fill: parent
                        renderTarget: Canvas.FramebufferObject

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            var w = width;
                            var h = height;
                            if (w <= 0 || h <= 0) return;

                            var cx = w * 0.48;
                            var cy = h * 0.58;
                            var scaleFactor = Math.min(w / 440, h / 210);

                            ctx.save();
                            ctx.translate(cx, cy);
                            ctx.scale(scaleFactor, scaleFactor);

                            // Underbody / Ground Reflection shadow
                            ctx.beginPath();
                            ctx.ellipse(0, 48, 170, 10, 0, 0, Math.PI * 2);
                            ctx.fillStyle = "rgba(15, 23, 42, 0.07)";
                            ctx.fill();

                            // Aero Wind Streamlines when driving
                            if (root.vehicleState === "DRIVING") {
                                ctx.strokeStyle = "rgba(2, 132, 199, 0.35)";
                                ctx.lineWidth = 2;
                                ctx.setLineDash([12, 16]);

                                // Top streamline
                                ctx.beginPath();
                                ctx.moveTo(130, -32);
                                ctx.lineTo(210, -32);
                                ctx.stroke();

                                // Mid streamline
                                ctx.beginPath();
                                ctx.moveTo(140, 2);
                                ctx.lineTo(230, 2);
                                ctx.stroke();

                                // Lower streamline
                                ctx.beginPath();
                                ctx.moveTo(110, 36);
                                ctx.lineTo(190, 36);
                                ctx.stroke();

                                ctx.setLineDash([]);
                            }

                            // Charging Pulse rings
                            if (root.vehicleState === "CHARGING") {
                                ctx.strokeStyle = "rgba(16, 185, 129, 0.45)";
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.arc(105, 14, 18, 0, Math.PI * 2);
                                ctx.stroke();

                                ctx.beginPath();
                                ctx.arc(105, 14, 28, 0, Math.PI * 2);
                                ctx.strokeStyle = "rgba(16, 185, 129, 0.20)";
                                ctx.stroke();
                            }

                            // Car Body Silhouette (Modern Aerodynamic Fastback EV)
                            ctx.beginPath();
                            // Nose & Front Bumper
                            ctx.moveTo(-165, 40);
                            ctx.lineTo(-168, 30);
                            ctx.quadraticCurveTo(-166, 12, -150, 4);
                            ctx.quadraticCurveTo(-135, -4, -100, -10);

                            // Windshield & A-Pillar
                            ctx.quadraticCurveTo(-60, -18, -35, -48);
                            ctx.quadraticCurveTo(5, -54, 45, -50);

                            // Fastback Roofline & Rear Window
                            ctx.quadraticCurveTo(90, -42, 135, -8);
                            ctx.quadraticCurveTo(155, 6, 162, 18);

                            // Rear Deck & Tail Lip
                            ctx.lineTo(168, 26);
                            ctx.lineTo(165, 40);

                            // Rear Wheel Arch
                            ctx.lineTo(122, 40);
                            ctx.arc(95, 40, 27, 0, Math.PI, true);
                            ctx.lineTo(68, 40);

                            // Underbody Rocker Panel
                            ctx.lineTo(-65, 40);

                            // Front Wheel Arch
                            ctx.arc(-92, 40, 27, 0, Math.PI, true);
                            ctx.lineTo(-165, 40);
                            ctx.closePath();

                            // Vehicle Paint Fill (Sophisticated Pearlescent Slate/Silver)
                            var bodyGrad = ctx.createLinearGradient(0, -54, 0, 40);
                            bodyGrad.addColorStop(0, "#F1F5F9");
                            bodyGrad.addColorStop(0.5, "#E2E8F0");
                            bodyGrad.addColorStop(1, "#CBD5E1");
                            ctx.fillStyle = bodyGrad;
                            ctx.fill();

                            ctx.strokeStyle = "#94A3B8";
                            ctx.lineWidth = 2.5;
                            ctx.stroke();

                            // Greenhouse / Cabin Glass
                            ctx.beginPath();
                            ctx.moveTo(-30, -45);
                            ctx.quadraticCurveTo(5, -50, 42, -47);
                            ctx.quadraticCurveTo(80, -40, 118, -12);
                            ctx.lineTo(-5, -12);
                            ctx.quadraticCurveTo(-45, -12, -75, -10);
                            ctx.closePath();
                            ctx.fillStyle = "#1E293B";
                            ctx.fill();

                            // B-Pillar divider
                            ctx.fillStyle = "#334155";
                            ctx.fillRect(8, -50, 5, 38);

                            // Front Headlamp Cluster (Crisp Cobalt LED)
                            ctx.beginPath();
                            ctx.moveTo(-165, 14);
                            ctx.lineTo(-142, 8);
                            ctx.lineTo(-148, 18);
                            ctx.closePath();
                            ctx.fillStyle = root.vehicleState === "FAULT" ? "#DC2626" : "#0284C7";
                            ctx.fill();

                            // Rear Taillight Cluster (Sleek Ruby LED Lightbar)
                            ctx.beginPath();
                            ctx.moveTo(158, 16);
                            ctx.lineTo(168, 22);
                            ctx.lineTo(154, 24);
                            ctx.closePath();
                            ctx.fillStyle = "#DC2626";
                            ctx.fill();

                            // Front Wheel & Tire
                            ctx.beginPath();
                            ctx.arc(-92, 40, 22, 0, Math.PI * 2);
                            ctx.fillStyle = "#1E293B";
                            ctx.fill();
                            // Alloy Wheel Hub
                            ctx.beginPath();
                            ctx.arc(-92, 40, 13, 0, Math.PI * 2);
                            ctx.fillStyle = "#E2E8F0";
                            ctx.fill();
                            ctx.strokeStyle = "#64748B";
                            ctx.lineWidth = 2;
                            ctx.stroke();

                            // Rear Wheel & Tire
                            ctx.beginPath();
                            ctx.arc(95, 40, 22, 0, Math.PI * 2);
                            ctx.fillStyle = "#1E293B";
                            ctx.fill();
                            // Alloy Wheel Hub
                            ctx.beginPath();
                            ctx.arc(95, 40, 13, 0, Math.PI * 2);
                            ctx.fillStyle = "#E2E8F0";
                            ctx.fill();
                            ctx.strokeStyle = "#64748B";
                            ctx.lineWidth = 2;
                            ctx.stroke();

                            ctx.restore();
                        }
                    }

                    Connections {
                        target: root
                        function onVehicleStateChanged() { vehicleCanvas.requestPaint(); }
                    }
                }

                // Speedometer Readout Callout
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 150
                    spacing: 0

                    Row {
                        spacing: 4
                        Layout.alignment: Qt.AlignLeft

                        Text {
                            text: root.speed
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeHero
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textPrimary
                        }
                    }

                    Text {
                        text: "KM/H SPEED"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightBold
                        color: DesignSystem.textMuted
                        font.letterSpacing: 1.2
                    }

                    Item { height: 12 }

                    Text {
                        text: root.vehicleState === "FAULT" ? "⚠️ Check Sensors" : (root.vehicleState === "DRIVING" ? "⚡ Cruising Active" : "🛡️ Powertrain OK")
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: root.vehicleState === "FAULT" ? DesignSystem.accentRuby : DesignSystem.textSecondary
                    }
                }
            }
        }

        // Bottom Telemetry Strip: 3 Recessed Data Wells
        RowLayout {
            Layout.fillWidth: true
            spacing: DesignSystem.spacingMd

            // Well 1: Battery SOC with mini progress bar
            Rectangle {
                Layout.fillWidth: true
                height: 58
                radius: DesignSystem.radiusMd
                color: DesignSystem.surfaceWell
                border.color: DesignSystem.borderMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: DesignSystem.spacingMd
                    anchors.rightMargin: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingSm

                    Text {
                        text: root.vehicleState === "CHARGING" ? "⚡" : "🔋"
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: Math.round(root.batterySoc) + "%"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeBody
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: "BATTERY"
                                font.family: DesignSystem.fontFamily
                                font.pixelSize: DesignSystem.fontSizeMicro
                                font.weight: DesignSystem.fontWeightBold
                                color: DesignSystem.textMuted
                            }
                        }

                        // Horizontal Battery Bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: DesignSystem.borderMuted

                            Rectangle {
                                width: parent.width * Math.max(0.0, Math.min(1.0, root.batterySoc / 100.0))
                                height: parent.height
                                radius: 3
                                color: root.batterySoc < 20.0 ? DesignSystem.accentRuby : DesignSystem.accentEmerald

                                Behavior on width { NumberAnimation { duration: DesignSystem.durationFast } }
                            }
                        }
                    }
                }
            }

            // Well 2: Estimated Range
            Rectangle {
                Layout.fillWidth: true
                height: 58
                radius: DesignSystem.radiusMd
                color: DesignSystem.surfaceWell
                border.color: DesignSystem.borderMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: DesignSystem.spacingMd
                    anchors.rightMargin: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingSm

                    Text {
                        text: "🧭"
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: root.rangeFormatted
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeBody
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textPrimary
                        }

                        Text {
                            text: "EST. RANGE"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textMuted
                        }
                    }
                }
            }

            // Well 3: Tap to inspect shortcut
            Rectangle {
                Layout.fillWidth: true
                height: 58
                radius: DesignSystem.radiusMd
                color: DesignSystem.surfaceWell
                border.color: DesignSystem.borderMuted
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: DesignSystem.spacingMd
                    anchors.rightMargin: DesignSystem.spacingMd
                    spacing: DesignSystem.spacingSm

                    Text {
                        text: "⚙️"
                        font.pixelSize: 18
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            text: "Vehicle Settings"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeBody
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.accentCyan
                        }

                        Text {
                            text: "TAP TO OPEN →"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: DesignSystem.fontSizeMicro
                            font.weight: DesignSystem.fontWeightBold
                            color: DesignSystem.textMuted
                        }
                    }
                }
            }
        }
    }

    // Interactive Card Click Handler
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: -0.5
        onClicked: root.clicked()
    }
}
