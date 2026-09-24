pragma Singleton

import Quickshell
import QtQuick
import qs.config

Singleton {
    id: root

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

    // ── Palette ─────────────────────────────────────────────────
    // Derived from the current wallpaper by ThemeState. Not readonly, because
    // the Behaviors below need to intercept the writes — they are what makes a
    // theme switch cross-fade instead of snap. Everything downstream still
    // just reads Theme.text, Theme.accent and friends.
    property color notchBg: ThemeState.palette.notchBg
    property color surface: ThemeState.palette.surface
    property color surfaceHi: ThemeState.palette.surfaceHi
    property color stroke: ThemeState.palette.stroke
    property color strokeSoft: ThemeState.palette.strokeSoft

    property color text: ThemeState.palette.text
    property color subtext: ThemeState.palette.subtext
    property color faint: ThemeState.palette.faint

    property color accent: ThemeState.palette.accent
    property color accent2: ThemeState.palette.accent2
    property color warm: ThemeState.palette.warm
    property color good: ThemeState.palette.good
    property color warn: ThemeState.palette.warn
    property color crit: ThemeState.palette.crit

    readonly property int durRecolour: 520

    Behavior on notchBg {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on surface {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on surfaceHi {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on stroke {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on strokeSoft {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on text {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on subtext {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on faint {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on accent {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on accent2 {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on warm {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on good {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on warn {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }
    Behavior on crit {
        ColorAnimation {
            duration: root.durRecolour
            easing.type: Easing.OutCubic
        }
    }

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
