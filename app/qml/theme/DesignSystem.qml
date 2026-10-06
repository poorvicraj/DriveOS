import QtQuick

pragma Singleton

QtObject {
    id: root

    // =========================================================================
    // THEME CONFIGURATION
    // =========================================================================
    property bool isDarkTheme: false                        // Light automotive cockpit theme

    // =========================================================================
    // COLOR PALETTE — CALM LUXURY AUTOMOTIVE COCKPIT
    // =========================================================================
    // Base foundation & surfaces
    readonly property color background: isDarkTheme ? "#080B11" : "#F5F7FA"           // Clean alabaster in light mode
    readonly property color surface: isDarkTheme ? "#111622" : "#FFFFFF"              // Pure crisp white container
    readonly property color surfaceCard: isDarkTheme ? "#141C2B" : "#FFFFFF"          // Elevated card surface
    readonly property color surfaceElevated: isDarkTheme ? "#1C2638" : "#FFFFFF"      // Modals & elevated cards
    readonly property color surfaceWell: isDarkTheme ? "#162030" : "#F1F5F9"          // Subtle recessed wells/chips
    readonly property color surfaceGlass: isDarkTheme ? Qt.rgba(0.07, 0.10, 0.16, 0.82) : Qt.rgba(1.0, 1.0, 1.0, 0.94)

    // Semantic colors & accents (refined, restrained, calm)
    readonly property color accentCyan: isDarkTheme ? "#00E5FF" : "#0284C7"           // Sky cobalt in light mode
    readonly property color accentEmerald: isDarkTheme ? "#00E676" : "#059669"        // Calibrated emerald
    readonly property color accentAmber: isDarkTheme ? "#FFB300" : "#D97706"          // Caution amber
    readonly property color accentRuby: isDarkTheme ? "#FF453A" : "#DC2626"           // Critical ruby
    readonly property color accentPurple: isDarkTheme ? "#7C4DFF" : "#4F46E5"         // Media violet

    // Text hierarchy (maximum readability & contrast)
    readonly property color textPrimary: isDarkTheme ? "#FFFFFF" : "#0F172A"          // Deep slate navy in light mode
    readonly property color textSecondary: isDarkTheme ? "#94A3B8" : "#475569"        // Neutral slate description
    readonly property color textMuted: isDarkTheme ? "#64748B" : "#8E9CAE"            // Subdued metadata & units
    readonly property color textDisabled: isDarkTheme ? "#334155" : "#94A3B8"         // Inactive labels
    readonly property color textInverse: isDarkTheme ? "#080B11" : "#FFFFFF"          // Inverted text

    // Component borders & dividers
    readonly property color borderMuted: isDarkTheme ? "#162030" : "#E2E8F0"
    readonly property color borderDefault: isDarkTheme ? "#232E42" : "#E2E8F0"
    readonly property color borderHighlight: isDarkTheme ? "#3B4A65" : "#CBD5E1"
    readonly property color borderActive: isDarkTheme ? "#00E5FF" : "#0284C7"

    // Glows & shadows
    readonly property color glowCyan: isDarkTheme ? Qt.rgba(0.0, 0.898, 1.0, 0.24) : Qt.rgba(2, 132, 199, 0.12)
    readonly property color glowEmerald: isDarkTheme ? Qt.rgba(0.0, 0.902, 0.463, 0.24) : Qt.rgba(5, 150, 105, 0.12)
    readonly property color glowAmber: isDarkTheme ? Qt.rgba(1.0, 0.702, 0.0, 0.24) : Qt.rgba(217, 119, 6, 0.12)
    readonly property color glowRuby: isDarkTheme ? Qt.rgba(1.0, 0.271, 0.227, 0.24) : Qt.rgba(220, 38, 38, 0.12)
    readonly property color shadowAmbient: isDarkTheme ? Qt.rgba(0, 0, 0, 0.40) : Qt.rgba(15, 23, 42, 0.06)

    // Explicit Standard Design Token Aliases (Section 3 Requirement)
    readonly property color colorBackground: background
    readonly property color colorSurface: surface
    readonly property color colorSurfaceCard: surfaceCard
    readonly property color colorSurfaceElevated: surfaceElevated
    readonly property color colorPrimaryText: textPrimary
    readonly property color colorSecondaryText: textSecondary
    readonly property color colorMutedText: textMuted
    readonly property color colorDisabledText: textDisabled
    readonly property color colorAccent: accentCyan
    readonly property color colorSuccess: accentEmerald
    readonly property color colorWarning: accentAmber
    readonly property color colorError: accentRuby
    readonly property color colorDisabled: isDarkTheme ? "#1B2232" : "#E2E8F0"

    // =========================================================================
    // TYPOGRAPHY SCALE (Automotive Legibility & Glanceability)
    // =========================================================================
    readonly property string fontFamily: "Inter, Roboto, -apple-system, sans-serif"
    readonly property string fontMonospace: "JetBrains Mono, Roboto Mono, monospace"

    // Font sizes
    readonly property int fontSizeHero: 56          // Hero speedometer
    readonly property int fontSizeDisplay: 40       // Prominent gauges & values
    readonly property int fontSizeTitle: 24         // Primary screen and section headings
    readonly property int fontSizeSubtitle: 18      // Subsections & card headers
    readonly property int fontSizeBody: 14          // Standard UI labels
    readonly property int fontSizeCaption: 12       // Secondary data, metadata
    readonly property int fontSizeMicro: 10         // Tiny tags, badges

    // Semantic typography aliases
    readonly property int fontDisplay: fontSizeDisplay
    readonly property int fontHeading: fontSizeTitle
    readonly property int fontSubheading: fontSizeSubtitle
    readonly property int fontBody: fontSizeBody
    readonly property int fontCaption: fontSizeCaption
    readonly property int fontNumeric: 36

    // Font weights
    readonly property int fontWeightBold: Font.Bold
    readonly property int fontWeightMedium: Font.DemiBold
    readonly property int fontWeightRegular: Font.Normal

    // =========================================================================
    // SPACING SCALE (Generous, Touch-Friendly Geometry)
    // =========================================================================
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int spacingLg: 24
    readonly property int spacingXl: 32
    readonly property int spacing2Xl: 48

    // Short-form spacing aliases
    readonly property int spaceXs: spacingXs
    readonly property int spaceSm: spacingSm
    readonly property int spaceMd: spacingMd
    readonly property int spaceLg: spacingLg
    readonly property int spaceXl: spacingXl

    // =========================================================================
    // SHAPE & CORNER RADII SCALE
    // =========================================================================
    readonly property real radiusSm: 6.0
    readonly property real radiusMd: 12.0
    readonly property real radiusLg: 18.0
    readonly property real radiusXl: 24.0
    readonly property real radiusPill: 999.0

    readonly property real radiusSmall: radiusSm
    readonly property real radiusMedium: radiusMd
    readonly property real radiusLarge: radiusLg

    // =========================================================================
    // TOUCH TARGET & SIZING ERGONOMICS (Strict Automotive 48x48 Rule)
    // =========================================================================
    readonly property real minTouchTarget: 48.0     // Minimum interactive touch box
    readonly property real buttonHeight: 52.0       // Standard comfortable touch button
    readonly property real iconSizeSm: 18.0
    readonly property real iconSizeMd: 24.0
    readonly property real iconSizeLg: 32.0
    readonly property real iconSizeXl: 48.0

    // =========================================================================
    // MOTION & MICRO-ANIMATION TIMINGS (Fast, Purposeful, Calm)
    // =========================================================================
    readonly property int durationInstant: 80
    readonly property int durationFast: 160
    readonly property int durationNormal: 260
    readonly property int durationSlow: 400

    readonly property real easingCurveStandard: Easing.OutCubic
    readonly property real easingCurveSnappy: Easing.OutQuad
    readonly property real easingCurveBounce: Easing.OutBack

    // =========================================================================
    // INTERACTION STATES & OPACITIES
    // =========================================================================
    readonly property real opacityNormal: 1.0
    readonly property real opacityDefault: 1.0
    readonly property real opacityHovered: 0.88
    readonly property real opacityPressed: 0.72
    readonly property real opacitySelected: 1.0
    readonly property real opacityDisabled: 0.35
    readonly property real opacityRestricted: 0.22
    readonly property real opacityUnavailable: 0.15

    readonly property real scalePressed: 0.97
}
