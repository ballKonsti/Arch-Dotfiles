pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // ── Geometry ────────────────────────────────────────────────
    readonly property int barHeight: 34          // reserved strip at the top
    readonly property int notchWidth: 400
    readonly property int notchHeight: 34
    readonly property int notchWidthOpen: 580
    readonly property int notchHeightOpen: 208
    readonly property int innerRadius: 14        // the inverted "shoulder" corners
    readonly property int bottomRadius: 18
    readonly property int osdStretch: 54         // how far the OSD pushes the right edge

    // Entrance: two waves run in from the screen edges and collide.
    readonly property int wavePiece: 92          // crest width of each incoming wave
    readonly property int waveTravel: 620        // time to cross the screen
    readonly property int waveOvershoot: 24      // how far off-screen they start
    readonly property int waveTail: 260          // length of the trailing wake
    readonly property real waveWobble: 0.3       // how much the crest swells as it runs
    readonly property int waveRipples: 3         // half-cycles of swell over the crossing

    // ── Palette (warm dark, carried over from the old waybar) ───
    readonly property color notchBg: "#000000"
    readonly property color surface: "#16130f"
    readonly property color surfaceHi: "#231f19"
    readonly property color stroke: "#1affffff"
    readonly property color strokeSoft: "#0dffffff"

    readonly property color text: "#ece6dd"
    readonly property color subtext: "#9b9186"
    readonly property color faint: "#5e574f"

    readonly property color accent: "#ffe5ec"     // soft pink
    readonly property color accent2: "#caf0f8"    // ice blue
    readonly property color warm: "#e0b189"
    readonly property color good: "#a7d3a0"
    readonly property color warn: "#e0a458"
    readonly property color crit: "#e05c5c"

    // ── Type ────────────────────────────────────────────────────
    readonly property string fontUI: "Inter"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontIcon: "JetBrainsMono Nerd Font"

    // ── Motion ──────────────────────────────────────────────────
    readonly property int durFast: 160
    readonly property int durMed: 260
    readonly property int durSlow: 480
    // easeOutQuint — the "settles into place" curve
    readonly property var curve: [0.22, 1.0, 0.36, 1.0, 1.0, 1.0]

    // The unfold sweeps in from the right: the right edge leads, the height
    // unfurls behind it, and the left edge brings up the rear.
    readonly property int leadDelay: 0
    readonly property int heightDelay: 80
    readonly property int trailDelay: 150
}
