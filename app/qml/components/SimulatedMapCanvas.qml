import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    // =========================================================================
    // COMPATIBILITY & TELEMETRY PROPERTIES
    // =========================================================================
    property string destinationName: "Mysuru Palace"
    property string destinationIcon: "🏰"
    property string etaFormatted: "18 min"
    property real destX: 0.74
    property real destY: 0.26
    property bool isNavigating: true
    property bool isDriving: false
    property real mapScale: 1.0

    // Real Geographic GPS Telemetry
    property real currentLatitude: 12.3410
    property real currentLongitude: 76.6268
    property real currentHeading: 45.0
    property real destinationLatitude: 12.3052
    property real destinationLongitude: 76.6552
    property string destinationAddress: "Sayyaji Rao Rd, Mysuru"
    property var routeWaypoints: []
    property var allDestinations: []
    property int speedLimit: 60

    // User GPS Location (Distinct from moving vehicle)
    property real userLatitude: 12.3551
    property real userLongitude: 76.6186
    property string userLocationTitle: "Current Location of the User"
    property string userLocationAddress: "GSSSIETW Campus, KRS Road, Mysuru"

    // Shortest Path / Dijkstra Route Telemetry
    property string pathfindingAlgorithm: "Dijkstra's Shortest Path Algorithm"
    property int shortestPathNodeCount: 8
    property real shortestPathDistanceKm: 8.4
    property var shortestPathNodeNames: []
    property real vehicleSpeed: 52.0

    // Map Display Configuration & Optional Custom API Key
    property string mapLayerType: "satellite"   // "satellite", "street", "dark"
    property bool is3DMode: false
    property int zoomLevel: 14                  // Supported levels: 13, 14, 15, 16
    property string customApiKey: ""            // Optional: Google Maps API key / Mapbox Token (Leave empty for built-in free zero-key open APIs)

    signal recenterRequested()
    signal recenterOnUserRequested()
    signal recenterOnVehicleRequested()
    signal destinationSelected(int index)

    implicitWidth: 600
    implicitHeight: 600
    color: mapLayerType === "satellite" ? "#0A0F1A" : (mapLayerType === "dark" ? "#0F172A" : "#E2E8F0")
    clip: true

    // Camera center coordinates & user panning offsets
    property real cameraLat: currentLatitude
    property real cameraLon: currentLongitude
    property real panOffsetX: 0.0
    property real panOffsetY: 0.0

    // Track vehicle when navigating and user hasn't panned
    property bool isUserPanning: false

    onCurrentLatitudeChanged: {
        if (!isUserPanning && isNavigating) {
            cameraLat = currentLatitude;
        }
    }

    onCurrentLongitudeChanged: {
        if (!isUserPanning && isNavigating) {
            cameraLon = currentLongitude;
        }
    }

    // Dynamic Route Stream animation phase
    property real streamPhase: 0.0
    NumberAnimation on streamPhase {
        from: 0.0
        to: 36.0
        duration: 1400
        loops: Animation.Infinite
        running: root.isNavigating
    }

    // Vehicle beacon pulse animation
    property real beaconPulse: 1.0
    SequentialAnimation on beaconPulse {
        loops: Animation.Infinite
        running: true
        NumberAnimation { from: 0.8; to: 1.5; duration: 1200; easing.type: Easing.OutQuad }
        NumberAnimation { from: 1.5; to: 0.8; duration: 1200; easing.type: Easing.InQuad }
    }

    // =========================================================================
    // SLIPPY MAP WEB MERCATOR PROJECTION UTILITIES
    // =========================================================================
    function lon2pixel(lon, z) {
        return (lon + 180.0) / 360.0 * Math.pow(2, z) * 256.0;
    }

    function lat2pixel(lat, z) {
        var latRad = lat * Math.PI / 180.0;
        var clamped = Math.max(-85.05112878, Math.min(85.05112878, latRad));
        return (1.0 - Math.log(Math.tan(clamped) + 1.0 / Math.cos(clamped)) / Math.PI) / 2.0 * Math.pow(2, z) * 256.0;
    }

    function pixel2lon(px, z) {
        return px / (256.0 * Math.pow(2, z)) * 360.0 - 180.0;
    }

    function pixel2lat(py, z) {
        var n = Math.PI - 2.0 * Math.PI * py / (256.0 * Math.pow(2, z));
        return 180.0 / Math.PI * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
    }

    // Convert GPS coordinate to viewport screen pixels
    function gpsToScreen(lat, lon) {
        var cPx = lon2pixel(root.cameraLon, root.zoomLevel) - root.panOffsetX;
        var cPy = lat2pixel(root.cameraLat, root.zoomLevel) - root.panOffsetY;
        var ptPx = lon2pixel(lon, root.zoomLevel);
        var ptPy = lat2pixel(lat, root.zoomLevel);
        return {
            x: mapViewport.width / 2 + (ptPx - cPx),
            y: mapViewport.height / 2 + (ptPy - cPy)
        };
    }

    // =========================================================================
    // INTERACTIVE MAP VIEWPORT WITH 3D PERSPECTIVE TRANSFORM
    // =========================================================================
    Item {
        id: mapViewport
        anchors.fill: parent

        transform: [
            Rotation {
                id: pitchRotation
                origin.x: mapViewport.width / 2
                origin.y: mapViewport.height * 0.65
                axis { x: 1; y: 0; z: 0 }
                angle: root.is3DMode ? 38 : 0
                Behavior on angle { NumberAnimation { duration: 500; easing.type: Easing.OutQuad } }
            },
            Rotation {
                id: headingRotation
                origin.x: mapViewport.width / 2
                origin.y: mapViewport.height * 0.65
                axis { x: 0; y: 0; z: 1 }
                angle: (root.is3DMode && root.isNavigating && !root.isUserPanning) ? -root.currentHeading : 0
                Behavior on angle { NumberAnimation { duration: 350; easing.type: Easing.OutQuad } }
            }
        ]

        // ---------------------------------------------------------------------
        // 1. DYNAMIC SLIPPY TILE GRID CONTAINER
        // ---------------------------------------------------------------------
        Item {
            id: tileContainer
            anchors.fill: parent

            // Center pixel and center tile
            readonly property real cPx: root.lon2pixel(root.cameraLon, root.zoomLevel) - root.panOffsetX
            readonly property real cPy: root.lat2pixel(root.cameraLat, root.zoomLevel) - root.panOffsetY
            readonly property int centerTileX: Math.floor(cPx / 256.0)
            readonly property int centerTileY: Math.floor(cPy / 256.0)
            readonly property real subPixelX: (cPx - centerTileX * 256.0)
            readonly property real subPixelY: (cPy - centerTileY * 256.0)

            // Optimized Grid bounds: 7 columns (-3 to +3) x 5 rows (-2 to +2) = 35 tiles
            Repeater {
                model: 35 // 7 cols * 5 rows (fits 1792x1280 px viewport with zero excess)

                Item {
                    id: tileItem
                    width: 256
                    height: 256

                    readonly property int colIndex: index % 7 - 3
                    readonly property int rowIndex: Math.floor(index / 7) - 2
                    readonly property int tX: tileContainer.centerTileX + colIndex
                    readonly property int tY: tileContainer.centerTileY + rowIndex
                    readonly property int zLevel: root.zoomLevel

                    x: mapViewport.width / 2 - tileContainer.subPixelX + colIndex * 256
                    y: mapViewport.height / 2 - tileContainer.subPixelY + rowIndex * 256

                    // Tile image with Google Hybrid satellite, local cache & online fallback
                    Image {
                        id: tileImage
                        anchors.fill: parent
                        fillMode: Image.Stretch
                        asynchronous: true
                        cache: true
                        smooth: true

                        property int fallbackStage: 0

                        function calculateSource() {
                            fallbackStage = 0;
                            var srv = Math.abs((tileItem.tX + tileItem.tY) % 4);

                            // If user provides a custom Google Maps API key, authenticate requests
                            if (root.customApiKey && root.customApiKey.length > 0) {
                                return "https://mt" + srv + ".google.com/vt/lyrs=y&x=" + tileItem.tX + "&y=" + tileItem.tY + "&z=" + tileItem.zLevel + "&key=" + root.customApiKey;
                            }
                            if (root.mapLayerType === "satellite" || root.mapLayerType === "google-hybrid") {
                                // Live Google Hybrid Satellite API (free zero-config Slippy Tile service, round-robin hosts)
                                return "https://mt" + srv + ".google.com/vt/lyrs=y&x=" + tileItem.tX + "&y=" + tileItem.tY + "&z=" + tileItem.zLevel;
                            } else if (root.mapLayerType === "street") {
                                // Live CartoDB / OpenStreetMap Voyager API (free automotive vector street style)
                                var cdnLetter = ["a", "b", "c", "d"][srv];
                                return "https://" + cdnLetter + ".basemaps.cartocdn.com/rastertiles/voyager/" + tileItem.zLevel + "/" + tileItem.tX + "/" + tileItem.tY + ".png";
                            } else {
                                // Live CartoDB Dark Matter API (free high-contrast automotive cockpit dark theme)
                                var cdnDark = ["a", "b", "c", "d"][srv];
                                return "https://" + cdnDark + ".basemaps.cartocdn.com/rastertiles/dark_all/" + tileItem.zLevel + "/" + tileItem.tX + "/" + tileItem.tY + ".png";
                            }
                        }

                        source: calculateSource()

                        Connections {
                            target: root
                            function onMapLayerTypeChanged() { tileImage.source = tileImage.calculateSource(); }
                            function onZoomLevelChanged() { tileImage.source = tileImage.calculateSource(); }
                            function onCustomApiKeyChanged() { tileImage.source = tileImage.calculateSource(); }
                        }

                        // Multi-tier open fallback if primary tile server times out or is unreachable
                        onStatusChanged: {
                            if (status === Image.Error) {
                                fallbackStage++;
                                if (root.mapLayerType === "satellite" || root.mapLayerType === "google-hybrid") {
                                    if (fallbackStage === 1) {
                                        // 1. Fallback to Esri World Imagery Satellite API (free open satellite)
                                        source = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/" + tileItem.zLevel + "/" + tileItem.tY + "/" + tileItem.tX;
                                    } else if (fallbackStage === 2) {
                                        // 2. Fallback to Google Standard Satellite
                                        source = "https://mt1.google.com/vt/lyrs=s&x=" + tileItem.tX + "&y=" + tileItem.tY + "&z=" + tileItem.zLevel;
                                    }
                                } else if (root.mapLayerType === "street") {
                                    if (fallbackStage === 1) {
                                        // 1. Fallback to Google Street Map API
                                        source = "https://mt1.google.com/vt/lyrs=m&x=" + tileItem.tX + "&y=" + tileItem.tY + "&z=" + tileItem.zLevel;
                                    } else if (fallbackStage === 2) {
                                        // 2. Fallback to OpenStreetMap Standard
                                        source = "https://tile.openstreetmap.org/" + tileItem.zLevel + "/" + tileItem.tX + "/" + tileItem.tY + ".png";
                                    }
                                } else {
                                    if (fallbackStage === 1) {
                                        // 1. Fallback to CartoDB Positron (light automotive)
                                        source = "https://basemaps.cartocdn.com/rastertiles/light_all/" + tileItem.zLevel + "/" + tileItem.tX + "/" + tileItem.tY + ".png";
                                    }
                                }
                            }
                        }
                    }

                    // Satellite Grid wireframe placeholder during tile streaming
                    Rectangle {
                        anchors.fill: parent
                        color: root.mapLayerType === "satellite" ? "#0D1829" : (root.mapLayerType === "dark" ? "#0B1120" : "#F1F5F9")
                        visible: tileImage.status !== Image.Ready
                        border.color: Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "🛰️ " + tileItem.zLevel + "/" + tileItem.tX + "/" + tileItem.tY
                            font.family: DesignSystem.fontMonospace
                            font.pixelSize: 9
                            color: Qt.rgba(1, 1, 1, 0.25)
                            visible: tileImage.status === Image.Loading
                        }
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // 2. ROUTE POLYLINE CANVAS (Luminous ribbon + animated chevrons)
        // ---------------------------------------------------------------------
        Canvas {
            id: routeCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject

            Connections {
                target: root
                function onCameraLatChanged() { routeCanvas.requestPaint(); }
                function onCameraLonChanged() { routeCanvas.requestPaint(); }
                function onPanOffsetXChanged() { routeCanvas.requestPaint(); }
                function onPanOffsetYChanged() { routeCanvas.requestPaint(); }
                function onZoomLevelChanged() { routeCanvas.requestPaint(); }
                function onStreamPhaseChanged() { routeCanvas.requestPaint(); }
                function onRouteWaypointsChanged() { routeCanvas.requestPaint(); }
                function onIsNavigatingChanged() { routeCanvas.requestPaint(); }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (!root.isNavigating) return;

                var wps = root.routeWaypoints;
                if (!wps || wps.length < 2) return;

                // Project all waypoints to current viewport screen coordinates
                var pts = [];
                for (var i = 0; i < wps.length; ++i) {
                    var pt = root.gpsToScreen(wps[i].lat, wps[i].lon);
                    pts.push(pt);
                }

                // 1. Route Outer Halo / Glow
                ctx.save();
                ctx.beginPath();
                ctx.moveTo(pts[0].x, pts[0].y);
                for (var j = 1; j < pts.length; ++j) {
                    ctx.lineTo(pts[j].x, pts[j].y);
                }
                ctx.strokeStyle = Qt.rgba(0.01, 0.65, 0.98, 0.35);
                ctx.lineWidth = 18;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.stroke();

                // 2. High-Visibility Cobalt Main Ribbon
                ctx.strokeStyle = "#0284C7";
                ctx.lineWidth = 9;
                ctx.stroke();

                // 3. Inner Electric Cyan Core
                ctx.strokeStyle = "#38BDF8";
                ctx.lineWidth = 4;
                ctx.stroke();

                // 4. Animated Directional Pulse Stream Chevrons
                ctx.strokeStyle = "#FFFFFF";
                ctx.lineWidth = 2.5;
                ctx.setLineDash([12, 16]);
                ctx.lineDashOffset = -root.streamPhase;
                ctx.stroke();
                ctx.restore();

                // 4.5 Intermediate Road Intersection Milestones (Dijkstra Shortest Path Nodes)
                var milestoneStep = pts.length > 25 ? Math.floor(pts.length / 8) : 1;
                for (var k = milestoneStep; k < pts.length - 1; k += milestoneStep) {
                    ctx.save();
                    ctx.beginPath();
                    ctx.arc(pts[k].x, pts[k].y, 4.5, 0, Math.PI * 2);
                    ctx.fillStyle = "#38BDF8";
                    ctx.fill();
                    ctx.strokeStyle = "#082F49";
                    ctx.lineWidth = 1.5;
                    ctx.stroke();
                    ctx.restore();
                }

                // 5. Origin Beacon Pulse
                ctx.save();
                ctx.beginPath();
                ctx.arc(pts[0].x, pts[0].y, 8, 0, Math.PI * 2);
                ctx.fillStyle = "#10B981";
                ctx.fill();
                ctx.strokeStyle = "#FFFFFF";
                ctx.lineWidth = 2;
                ctx.stroke();
                ctx.restore();
            }
        }

        // ---------------------------------------------------------------------
        // 3. REAL DESTINATION / POI PINS ON MAP
        // ---------------------------------------------------------------------
        Repeater {
            model: root.allDestinations

            Item {
                id: poiMarker
                readonly property var pt: root.gpsToScreen(modelData.latitude, modelData.longitude)
                x: pt.x
                y: pt.y
                visible: x >= -100 && x <= mapViewport.width + 100 && y >= -100 && y <= mapViewport.height + 100
                z: modelData.isSelected ? 50 : 20

                // Teardrop Pin Marker
                Rectangle {
                    anchors.bottom: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: modelData.isSelected ? 38 : 32
                    height: modelData.isSelected ? 38 : 32
                    radius: width / 2
                    color: modelData.isSelected ? "#DC2626" : Qt.rgba(0.06, 0.09, 0.16, 0.88)
                    border.color: "#FFFFFF"
                    border.width: modelData.isSelected ? 2.5 : 1.5

                    // Drop shadow
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: parent.radius + 3
                        color: Qt.rgba(0, 0, 0, 0.25)
                        z: -1
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon || "📍"
                        font.pixelSize: modelData.isSelected ? 18 : 15
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.destinationSelected(modelData.index)
                    }
                }

                // Frosted Place Name Tag
                Rectangle {
                    anchors.top: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 4
                    height: 24
                    implicitWidth: labelRow.implicitWidth + 16
                    radius: 12
                    color: modelData.isSelected ? "#0C4A6E" : "#0A0F1D"
                    border.color: modelData.isSelected ? DesignSystem.accentCyan : Qt.rgba(255, 255, 255, 0.25)
                    border.width: modelData.isSelected ? 2 : 1

                    Row {
                        id: labelRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: modelData.name
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 11
                            font.weight: modelData.isSelected ? DesignSystem.fontWeightBold : DesignSystem.fontWeightMedium
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "• " + modelData.distance
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 10
                            font.weight: DesignSystem.fontWeightBold
                            color: modelData.isSelected ? DesignSystem.accentCyan : "#CBD5E1"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.destinationSelected(modelData.index)
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // 3.5 USER LOCATION PIN (Placed Distinctly "Somewhere Else" from Vehicle)
        // ---------------------------------------------------------------------
        Item {
            id: userLocationMarker
            readonly property var pt: root.gpsToScreen(root.userLatitude, root.userLongitude)
            x: pt.x
            y: pt.y
            z: 110 // Above POI markers

            // Pulsing Emerald Radar Ring
            Rectangle {
                anchors.centerIn: parent
                width: 48 * root.beaconPulse
                height: 48 * root.beaconPulse
                radius: width / 2
                color: Qt.rgba(0.06, 0.78, 0.51, 0.20 / root.beaconPulse)
                border.color: Qt.rgba(0.06, 0.78, 0.51, 0.55 / root.beaconPulse)
                border.width: 1.5
            }

            // Teardrop Pin Marker for User's Location
            Rectangle {
                id: userPinHead
                anchors.bottom: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: 38
                height: 38
                radius: 19
                color: "#059669" // Emerald Green
                border.color: "#FFFFFF"
                border.width: 2.5

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: parent.radius + 4
                    color: Qt.rgba(0, 0, 0, 0.45)
                    z: -1
                }

                Text {
                    anchors.centerIn: parent
                    text: "📍"
                    font.pixelSize: 20
                }
            }

            // High-Contrast Frosted Badge Tag
            Rectangle {
                anchors.top: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 4
                height: 38
                implicitWidth: userTagCol.implicitWidth + 24
                radius: 10
                color: "#031E14"
                border.color: "#10B981"
                border.width: 1.5

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: parent.radius + 3
                    color: Qt.rgba(0.06, 0.78, 0.51, 0.22)
                    z: -1
                }

                Column {
                    id: userTagCol
                    anchors.centerIn: parent
                    spacing: 1

                    Row {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: "#34D399"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.userLocationTitle
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 11
                            font.weight: DesignSystem.fontWeightBold
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: root.userLocationAddress
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 9
                        font.weight: DesignSystem.fontWeightMedium
                        color: "#A7F3D0"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.cameraLat = root.userLatitude;
                        root.cameraLon = root.userLongitude;
                        root.panOffsetX = 0;
                        root.panOffsetY = 0;
                        root.isUserPanning = true;
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // 4. VEHICLE GPS BEACON (Moving along the Shortest Road Path)
        // ---------------------------------------------------------------------
        Item {
            id: vehiclePuck
            readonly property var pt: root.gpsToScreen(root.currentLatitude, root.currentLongitude)
            x: pt.x
            y: pt.y
            z: 120

            // Expanding Radar Ring Pulse
            Rectangle {
                anchors.centerIn: parent
                width: 44 * root.beaconPulse
                height: 44 * root.beaconPulse
                radius: width / 2
                color: Qt.rgba(0.01, 0.65, 0.98, 0.22 / root.beaconPulse)
                border.color: Qt.rgba(0.01, 0.65, 0.98, 0.55 / root.beaconPulse)
                border.width: 1.5
            }

            // Rotatable Vehicle Visual (Oriented with the road in 2D mode)
            Item {
                id: vehicleVisual
                anchors.centerIn: parent
                width: 140
                height: 140
                rotation: root.is3DMode ? 0 : root.currentHeading
                Behavior on rotation {
                    RotationAnimation {
                        direction: RotationAnimation.Shortest
                        duration: 250
                        easing.type: Easing.OutQuad
                    }
                }

                // Forward Headlight Beam Cone illuminating the road ahead
                Canvas {
                    anchors.fill: parent
                    renderTarget: Canvas.FramebufferObject

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cx = width / 2;
                        var cy = height / 2;
                        var grad = ctx.createRadialGradient(cx, cy, 10, cx, cy, 65);
                        grad.addColorStop(0, "rgba(56, 189, 248, 0.60)");
                        grad.addColorStop(0.5, "rgba(2, 132, 199, 0.25)");
                        grad.addColorStop(1, "rgba(2, 132, 199, 0.0)");

                        ctx.save();
                        ctx.fillStyle = grad;
                        ctx.beginPath();
                        ctx.moveTo(cx, cy);
                        // 60-degree forward beam pointing along vehicle's road heading
                        ctx.arc(cx, cy, 65, -Math.PI * 0.5 - Math.PI / 6.0, -Math.PI * 0.5 + Math.PI / 6.0);
                        ctx.closePath();
                        ctx.fill();
                        ctx.restore();
                    }
                }

                // High-Precision Vehicle Body (Sleek EV Silhouette)
                Rectangle {
                    id: vehicleBody
                    anchors.centerIn: parent
                    width: 24
                    height: 38
                    radius: 8
                    color: "#0284C7"
                    border.color: "#FFFFFF"
                    border.width: 2.5

                    // Drop Shadow
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: parent.radius + 3
                        color: Qt.rgba(0, 0, 0, 0.40)
                        z: -1
                    }

                    // Windshield / Cabin Glass
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        width: 16
                        height: 12
                        radius: 4
                        color: "#082F49"
                        border.color: "#38BDF8"
                        border.width: 1
                    }

                    // Dual Front Headlight LEDs
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: 2
                        anchors.topMargin: 2
                        width: 4
                        height: 3
                        radius: 1
                        color: "#E0F2FE"
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 2
                        anchors.topMargin: 2
                        width: 4
                        height: 3
                        radius: 1
                        color: "#E0F2FE"
                    }

                    // Dual Rear Red Taillights
                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 2
                        anchors.bottomMargin: 2
                        width: 4
                        height: 2
                        radius: 1
                        color: "#EF4444"
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 2
                        anchors.bottomMargin: 2
                        width: 4
                        height: 2
                        radius: 1
                        color: "#EF4444"
                    }
                }
            }

            // Floating Vehicle Telemetry Tag (Moving along the road)
            Rectangle {
                anchors.top: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 24
                height: 38
                implicitWidth: vehTagCol.implicitWidth + 20
                radius: 10
                color: "#081E36"
                border.color: "#38BDF8"
                border.width: 1.5

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: parent.radius + 3
                    color: Qt.rgba(0, 0, 0, 0.40)
                    z: -1
                }

                Column {
                    id: vehTagCol
                    anchors.centerIn: parent
                    spacing: 1

                    Row {
                        spacing: 5
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: "#38BDF8"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "🚗 DriveOS Vehicle (Moving)"
                            font.family: DesignSystem.fontFamily
                            font.pixelSize: 11
                            font.weight: DesignSystem.fontWeightBold
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: "Speed: " + Math.round(root.vehicleSpeed) + " km/h • Shortest Path (Dijkstra)"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 9
                        font.weight: DesignSystem.fontWeightMedium
                        color: "#BAE6FD"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.panOffsetX = 0;
                        root.panOffsetY = 0;
                        root.isUserPanning = false;
                        root.cameraLat = root.currentLatitude;
                        root.cameraLon = root.currentLongitude;
                        root.recenterRequested();
                    }
                }
            }
        }
    }

    // =========================================================================
    // MAP INTERACTION (Pan, Drag, Pinch-to-Zoom)
    // =========================================================================
    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.filterChildren: true

        property real startX: 0
        property real startY: 0
        property real initPanX: 0
        property real initPanY: 0

        onPressed: (mouse) => {
            root.isUserPanning = true;
            startX = mouse.x;
            startY = mouse.y;
            initPanX = root.panOffsetX;
            initPanY = root.panOffsetY;
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                var dx = mouse.x - startX;
                var dy = mouse.y - startY;
                root.panOffsetX = initPanX - dx;
                root.panOffsetY = initPanY - dy;
            }
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                root.zoomLevel = Math.min(16, root.zoomLevel + 1);
            } else if (wheel.angleDelta.y < 0) {
                root.zoomLevel = Math.max(13, root.zoomLevel - 1);
            }
        }
    }

    // =========================================================================
    // 3D HORIZON ATMOSPHERIC SKY & DEEP SPACE GRADIENT
    // =========================================================================
    Rectangle {
        id: horizonSky
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.35
        visible: root.is3DMode
        z: 150
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#030712" }
            GradientStop { position: 0.60; color: Qt.rgba(11, 21, 40, 0.82) }
            GradientStop { position: 0.88; color: Qt.rgba(2, 132, 199, 0.18) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        // Distant Horizon Atmospheric Glow Line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1.5
            color: Qt.rgba(56, 189, 248, 0.28)
        }
    }

    // =========================================================================
    // MODERN COCKPIT MAP CONTROLS & HUD OVERLAYS
    // =========================================================================

    // Top-Center Layer & View Switcher Floating Bar
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: DesignSystem.spacingMd
        height: 40
        implicitWidth: controlsRow.implicitWidth + 16
        radius: 20
        color: "#0A0F1D"
        border.color: Qt.rgba(255, 255, 255, 0.22)
        border.width: 1
        z: 300

        Row {
            id: controlsRow
            anchors.centerIn: parent
            spacing: 6

            // Satellite Layer Button
            Rectangle {
                width: 124
                height: 30
                radius: 15
                color: (root.mapLayerType === "satellite" || root.mapLayerType === "google-hybrid") ? DesignSystem.accentCyan : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "🛰️"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "GOOGLE HYBRID"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 10
                        font.weight: DesignSystem.fontWeightBold
                        color: (root.mapLayerType === "satellite" || root.mapLayerType === "google-hybrid") ? "#FFFFFF" : "#CBD5E1"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mapLayerType = "satellite"
                }
            }

            // Street Layer Button
            Rectangle {
                width: 84
                height: 30
                radius: 15
                color: root.mapLayerType === "street" ? DesignSystem.accentCyan : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "🗺️"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "STREET"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 10
                        font.weight: DesignSystem.fontWeightBold
                        color: root.mapLayerType === "street" ? "#FFFFFF" : "#CBD5E1"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mapLayerType = "street"
                }
            }

            // Dark Layer Button
            Rectangle {
                width: 76
                height: 30
                radius: 15
                color: root.mapLayerType === "dark" ? DesignSystem.accentCyan : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "🌙"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "DARK"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: 10
                        font.weight: DesignSystem.fontWeightBold
                        color: root.mapLayerType === "dark" ? "#FFFFFF" : "#CBD5E1"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mapLayerType = "dark"
                }
            }

            Rectangle {
                width: 1
                height: 20
                color: Qt.rgba(255, 255, 255, 0.20)
                anchors.verticalCenter: parent.verticalCenter
            }

            // 3D / 2D Perspective Toggle
            Rectangle {
                width: 68
                height: 30
                radius: 15
                color: root.is3DMode ? Qt.rgba(0.01, 0.65, 0.98, 0.25) : "transparent"
                border.color: root.is3DMode ? DesignSystem.accentCyan : Qt.rgba(255, 255, 255, 0.20)
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: root.is3DMode ? "📐 3D VIEW" : "🧭 2D VIEW"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: 10
                    font.weight: DesignSystem.fontWeightBold
                    color: root.is3DMode ? DesignSystem.accentCyan : "#CBD5E1"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.is3DMode = !root.is3DMode
                }
            }
        }
    }

    // Top-Right Compass Rose
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: DesignSystem.spacingMd
        width: 44
        height: 44
        radius: 22
        color: Qt.rgba(15, 23, 42, 0.85)
        border.color: Qt.rgba(255, 255, 255, 0.18)
        border.width: 1
        z: 300

        rotation: (root.is3DMode && root.isNavigating && !root.isUserPanning) ? -root.currentHeading : 0
        Behavior on rotation { NumberAnimation { duration: 300 } }

        Column {
            anchors.centerIn: parent
            spacing: -1

            Text {
                text: "▲"
                font.pixelSize: 11
                color: "#EF4444"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "N"
                font.family: DesignSystem.fontFamily
                font.pixelSize: 10
                font.weight: DesignSystem.fontWeightBold
                color: "#FFFFFF"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.panOffsetX = 0;
                root.panOffsetY = 0;
                root.isUserPanning = false;
                root.cameraLat = root.currentLatitude;
                root.cameraLon = root.currentLongitude;
                root.recenterRequested();
            }
        }
    }

    // Right-Edge Precision Map Controls (Recenter, Zoom In, Zoom Out)
    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: DesignSystem.spacingMd
        spacing: DesignSystem.spacingSm
        z: 300

        // Recenter on Vehicle Puck Button
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: !root.isUserPanning ? DesignSystem.accentCyan : "#0A0F1D"
            border.color: Qt.rgba(255, 255, 255, 0.22)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "🚗"
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.panOffsetX = 0;
                    root.panOffsetY = 0;
                    root.isUserPanning = false;
                    root.cameraLat = root.currentLatitude;
                    root.cameraLon = root.currentLongitude;
                    root.recenterRequested();
                    root.recenterOnVehicleRequested();
                }
            }
        }

        // Recenter on User Location Pin Button
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: root.isUserPanning ? "#059669" : "#0A0F1D"
            border.color: "#10B981"
            border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: "📍"
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.panOffsetX = 0;
                    root.panOffsetY = 0;
                    root.isUserPanning = true;
                    root.cameraLat = root.userLatitude;
                    root.cameraLon = root.userLongitude;
                    root.recenterOnUserRequested();
                }
            }
        }

        // Zoom In (+)
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: "#0A0F1D"
            border.color: Qt.rgba(255, 255, 255, 0.22)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "+"
                font.family: DesignSystem.fontFamily
                font.pixelSize: 22
                font.weight: DesignSystem.fontWeightBold
                color: "#FFFFFF"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.zoomLevel = Math.min(16, root.zoomLevel + 1)
            }
        }

        // Zoom Out (−)
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: "#0A0F1D"
            border.color: Qt.rgba(255, 255, 255, 0.22)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "−"
                font.family: DesignSystem.fontFamily
                font.pixelSize: 24
                font.weight: DesignSystem.fontWeightBold
                color: "#FFFFFF"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.zoomLevel = Math.max(13, root.zoomLevel - 1)
            }
        }
    }

    // Bottom-Right Geographic Scale Bar
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: DesignSystem.spacingMd
        implicitHeight: 24
        implicitWidth: scaleRow.implicitWidth + 18
        radius: DesignSystem.radiusPill
        color: "#0A0F1D"
        border.color: Qt.rgba(255, 255, 255, 0.22)
        border.width: 1
        z: 300

        Row {
            id: scaleRow
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                width: 32
                height: 2
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.zoomLevel >= 16 ? "100 m" : (root.zoomLevel === 15 ? "250 m" : (root.zoomLevel === 14 ? "500 m" : "1 km"))
                font.family: DesignSystem.fontFamily
                font.pixelSize: DesignSystem.fontSizeMicro
                font.weight: DesignSystem.fontWeightBold
                color: "#E2E8F0"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
