import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

Rectangle {
    id: root
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: DesignSystem.spacingLg
        spacing: DesignSystem.spacingMd

        // =====================================================================
        // TOP CONTEXT RIBBON: Greeting, State Selector, Weather & Connectivity
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: DesignSystem.spacingMd

            // Left: Driver Greeting & Subtitle
            Row {
                spacing: DesignSystem.spacingSm
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: typeof shellViewModel !== "undefined" ? shellViewModel.greetingText : "GOOD MORNING"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeSubtitle
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    font.letterSpacing: 0.8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "• " + (typeof shellViewModel !== "undefined" ? shellViewModel.vehicleContextSubtitle : "Ready to drive")
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeBody
                    font.weight: DesignSystem.fontWeightMedium
                    color: DesignSystem.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { Layout.fillWidth: true }

            // Center: Interactive Vehicle State Selector (PARKED, DRIVING, CHARGING, FAULT)
            VehicleStateSelector {
                Layout.alignment: Qt.AlignVCenter
                currentState: typeof shellViewModel !== "undefined" ? shellViewModel.vehicleContextState : "PARKED"
                onStateSelected: function(newState) {
                    if (typeof shellViewModel !== "undefined") {
                        shellViewModel.setVehicleContextState(newState)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Right: Ambient Weather & Connectivity Badges
            Row {
                spacing: DesignSystem.spacingMd
                Layout.alignment: Qt.AlignVCenter

                // Outside Temperature Badge
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "🌤️"
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: typeof shellViewModel !== "undefined" ? shellViewModel.outsideTemperatureFormatted : "19°C"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Connectivity Indicator
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "📶"
                        font.pixelSize: 13
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "5G Connected"
                        font.family: DesignSystem.fontFamily
                        font.pixelSize: DesignSystem.fontSizeCaption
                        font.weight: DesignSystem.fontWeightMedium
                        color: DesignSystem.accentEmerald
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Time Readout
                Text {
                    text: typeof shellViewModel !== "undefined" ? shellViewModel.timeFormatted : "10:42 AM"
                    font.family: DesignSystem.fontFamily
                    font.pixelSize: DesignSystem.fontSizeCaption
                    font.weight: DesignSystem.fontWeightBold
                    color: DesignSystem.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // =====================================================================
        // MAIN COCKPIT GRID: Vehicle Hero (Left) + Contextual Shortcuts (Right)
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: DesignSystem.spacingLg

            // -----------------------------------------------------------------
            // LEFT COLUMN: Dominant Vehicle Hero Area
            // -----------------------------------------------------------------
            VehicleHeroCard {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: root.width * 0.53

                vehicleState: typeof shellViewModel !== "undefined" ? shellViewModel.vehicleContextState : "PARKED"
                stateSubtitle: typeof shellViewModel !== "undefined" ? shellViewModel.vehicleContextSubtitle : "Ready to drive"
                speed: typeof shellViewModel !== "undefined" ? shellViewModel.speedFormatted : "0"
                gear: typeof shellViewModel !== "undefined" ? shellViewModel.gear : "P"
                batterySoc: typeof shellViewModel !== "undefined" ? shellViewModel.batterySoc : 92.0
                rangeFormatted: typeof shellViewModel !== "undefined" ? shellViewModel.rangeKmFormatted : "410 km"
                driveMode: typeof shellViewModel !== "undefined" ? shellViewModel.driveMode : "COMFORT"

                onClicked: {
                    if (typeof navigationController !== "undefined") {
                        navigationController.navigateTo(3) // Navigate to Vehicle Screen
                    }
                }

                onCycleDriveModeRequested: {
                    if (typeof shellViewModel !== "undefined") {
                        shellViewModel.toggleDriveMode()
                    }
                }
            }

            // -----------------------------------------------------------------
            // RIGHT COLUMN: 3 Contextual Shortcuts (Climate, Media, Navigation)
            // -----------------------------------------------------------------
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredWidth: root.width * 0.47
                spacing: DesignSystem.spacingMd

                // 1. Climate Summary Card
                ClimateSummaryCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    cabinTemp: typeof shellViewModel !== "undefined" ? shellViewModel.cabinTemperatureFormatted : "21.5°C"
                    targetTemp: typeof shellViewModel !== "undefined" ? shellViewModel.targetTemperatureFormatted : "22.0°C"
                    isAcActive: typeof shellViewModel !== "undefined" ? shellViewModel.isAcActive : true
                    fanLevel: typeof shellViewModel !== "undefined" ? shellViewModel.fanSpeed : 2

                    onIncreaseTemp: {
                        if (typeof shellViewModel !== "undefined") {
                            shellViewModel.adjustTargetTemperature(0.5)
                        }
                    }

                    onDecreaseTemp: {
                        if (typeof shellViewModel !== "undefined") {
                            shellViewModel.adjustTargetTemperature(-0.5)
                        }
                    }

                    onToggleAc: {
                        if (typeof shellViewModel !== "undefined") {
                            shellViewModel.toggleAcActive()
                        }
                    }

                    onCardClicked: {
                        if (typeof navigationController !== "undefined") {
                            navigationController.navigateTo(2) // Navigate to Climate Screen
                        }
                    }
                }

                // 2. Now Playing Media Card
                MediaSummaryCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    title: typeof shellViewModel !== "undefined" ? shellViewModel.mediaTitle : "Midnight Drive"
                    artist: typeof shellViewModel !== "undefined" ? shellViewModel.mediaArtist : "DriveOS Synthetics"
                    isPlaying: typeof shellViewModel !== "undefined" ? shellViewModel.isMediaPlaying : true
                    elapsedFormatted: typeof shellViewModel !== "undefined" ? shellViewModel.mediaElapsedFormatted : "1:42"
                    durationFormatted: typeof shellViewModel !== "undefined" ? shellViewModel.mediaDurationFormatted : "3:50"
                    progress: typeof shellViewModel !== "undefined" ? shellViewModel.mediaProgress : 0.44

                    onTogglePlayPause: {
                        if (typeof shellViewModel !== "undefined") {
                            shellViewModel.toggleMediaPlayPause()
                        }
                    }

                    onNextTrack: {
                        if (typeof shellViewModel !== "undefined") {
                            shellViewModel.nextMediaTrack()
                        }
                    }

                    onPrevTrack: {
                        if (typeof shellViewModel !== "undefined") {
                            shellViewModel.prevMediaTrack()
                        }
                    }

                    onCardClicked: {
                        if (typeof navigationController !== "undefined") {
                            navigationController.navigateTo(1) // Navigate to Media Screen
                        }
                    }
                }

                // 3. Navigation Summary Card
                NavSummaryCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    destination: typeof shellViewModel !== "undefined" ? shellViewModel.navDestination : "Home → Mysuru Palace"
                    eta: typeof shellViewModel !== "undefined" ? shellViewModel.navEta : "18 min"
                    distance: typeof shellViewModel !== "undefined" ? shellViewModel.navDistance : "12.4 km"
                    maneuver: typeof shellViewModel !== "undefined" ? shellViewModel.navManeuver : "In 450 m, turn right onto Cyberway"
                    turnIcon: typeof shellViewModel !== "undefined" ? shellViewModel.navNextTurnIcon : "↱"

                    onCardClicked: {
                        if (typeof navigationController !== "undefined") {
                            navigationController.navigateTo(4) // Navigate to Navigation Screen
                        }
                    }
                }
            }
        }
    }
}
