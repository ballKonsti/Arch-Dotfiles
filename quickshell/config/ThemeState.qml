pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The switchable half of the theme: which wallpaper is up, whether we are in
// dark or light, and the palette derived from the wallpaper's dominant colour.
// Theme.qml reads this and exposes it as the flat token set the rest of the
// shell already binds to, so nothing else had to change.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string wallDir: `${root.home}/Pictures/wallpapers`

    // [{ path, name, seed, mean }] — filled in by the scan script.
    property var themes: []
    property int index: 0
    property bool light: false

    // Set while the picker is up. The picker itself owns its window; this is
    // just the shared bit of state the IPC handler pokes.
    property bool popupOpen: false

    readonly property var fallback: ({
            path: "",
            name: "default",
            seed: "#e0b189",
            mean: 0.2
        })

    readonly property int count: themes.length
    readonly property var active: count > 0 ? themes[Math.max(0, Math.min(index, count - 1))] : fallback
    readonly property string wallpaper: active.path

    // Bright wallpapers read better with a light shell; this is only a
    // suggestion the picker shows, never applied behind your back.
    readonly property bool suggestsLight: (active.mean ?? 0) > 0.62

    readonly property var palette: root.buildPalette(root.active.seed, root.light)

    // ── Palette derivation ──────────────────────────────────────
    // Everything hangs off one seed hue. Surfaces get a trace of it so the
    // shell sits in the wallpaper rather than on top of it; accents get most
    // of it; the semantic colours (good/warn/crit) keep their own hue and
    // only lean a little towards the wallpaper, so a red still reads as red.

    function mixHue(a, b, t) {
        let d = b - a;
        if (d > 0.5)
            d -= 1;
        if (d < -0.5)
            d += 1;
        let h = a + d * t;
        return (h % 1 + 1) % 1;
    }

    function buildPalette(seed, isLight) {
        const c = Qt.color(seed || "#808080");
        const rawS = c.hslSaturation;
        // A near-grey wallpaper has no usable hue; fall back to a warm one so
        // the shell never turns clinically neutral.
        const achroma = rawS < 0.06;
        const h = achroma ? 0.083 : c.hslHue;
        const s = achroma ? 0.14 : Math.max(0.12, Math.min(rawS, 0.85));

        // How far the semantic colours drift toward the wallpaper hue.
        const lean = 0.16;

        if (isLight) {
            return {
                notchBg: Qt.hsla(h, s * 0.22, 0.965, 1),
                surface: Qt.hsla(h, s * 0.26, 0.920, 1),
                surfaceHi: Qt.hsla(h, s * 0.30, 0.845, 1),
                stroke: Qt.rgba(0, 0, 0, 0.14),
                strokeSoft: Qt.rgba(0, 0, 0, 0.07),
                text: Qt.hsla(h, s * 0.45, 0.120, 1),
                subtext: Qt.hsla(h, s * 0.30, 0.380, 1),
                faint: Qt.hsla(h, s * 0.24, 0.580, 1),
                accent: Qt.hsla(h, Math.max(0.40, Math.min(s * 1.25, 0.85)), 0.400, 1),
                accent2: Qt.hsla((h + 0.47) % 1, Math.max(0.34, Math.min(s, 0.70)), 0.420, 1),
                warm: Qt.hsla(root.mixHue(0.075, h, lean), 0.62, 0.400, 1),
                good: Qt.hsla(root.mixHue(0.300, h, lean), 0.48, 0.330, 1),
                warn: Qt.hsla(root.mixHue(0.090, h, lean), 0.72, 0.360, 1),
                crit: Qt.hsla(root.mixHue(0.000, h, lean), 0.68, 0.420, 1)
            };
        }

        return {
            notchBg: Qt.hsla(h, s * 0.30, 0.025, 1),
            surface: Qt.hsla(h, s * 0.32, 0.080, 1),
            surfaceHi: Qt.hsla(h, s * 0.34, 0.145, 1),
            stroke: Qt.rgba(1, 1, 1, 0.10),
            strokeSoft: Qt.rgba(1, 1, 1, 0.05),
            text: Qt.hsla(h, s * 0.20, 0.930, 1),
            subtext: Qt.hsla(h, s * 0.16, 0.660, 1),
            faint: Qt.hsla(h, s * 0.14, 0.420, 1),
            accent: Qt.hsla(h, Math.max(0.32, Math.min(s * 1.20, 0.72)), 0.760, 1),
            accent2: Qt.hsla((h + 0.47) % 1, Math.max(0.28, Math.min(s, 0.62)), 0.800, 1),
            warm: Qt.hsla(root.mixHue(0.075, h, lean), 0.52, 0.700, 1),
            good: Qt.hsla(root.mixHue(0.300, h, lean), 0.38, 0.720, 1),
            warn: Qt.hsla(root.mixHue(0.090, h, lean), 0.62, 0.660, 1),
            crit: Qt.hsla(root.mixHue(0.000, h, lean), 0.66, 0.650, 1)
        };
    }

    // ── Selection ───────────────────────────────────────────────

    function select(i) {
        if (root.count === 0)
            return;
        root.index = ((i % root.count) + root.count) % root.count;
        wallTimer.restart();
        root.persist();
    }

    function next() {
        root.select(root.index + 1);
    }

    function prev() {
        root.select(root.index - 1);
    }

    function selectByName(name) {
        const i = root.themes.findIndex(t => t.name === name || t.path === name);
        if (i >= 0)
            root.select(i);
        return i >= 0;
    }

    function setLight(on) {
        root.light = on;
        root.persist();
    }

    function toggleMode() {
        root.setLight(!root.light);
    }

    // ── Applying to the world outside the shell ─────────────────

    // Debounced: arrowing through the picker recolours instantly, but the
    // wallpaper only redraws once you settle on one.
    Timer {
        id: wallTimer
        interval: 320
        onTriggered: root.applyWallpaper()
    }

    signal wipeRequested

    function applyWallpaper() {
        if (!root.active.path)
            return;
        wallProc.command = ["awww", "img", root.active.path, "--transition-type", "center", "--transition-duration", "1.1", "--transition-fps", "60"];
        wallProc.running = true;
        root.wipeRequested();
    }

    Process {
        id: wallProc
    }

    // Hyprland borders follow the accent so the window chrome belongs to the
    // same theme. Runtime keywords only — hyprland.conf is left alone.
    Process {
        id: hyprProc
    }

    function hex(c) {
        const f = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return f(c.r) + f(c.g) + f(c.b);
    }

    function applyBorders() {
        const p = root.palette;
        hyprProc.command = ["hyprctl", "--batch", `keyword general:col.active_border rgba(${root.hex(p.accent)}ee) rgba(${root.hex(p.accent2)}ff) 45deg ; keyword general:col.inactive_border rgba(${root.hex(p.faint)}66)`];
        hyprProc.running = true;
    }

    onPaletteChanged: root.applyBorders()

    // ── Persistence ─────────────────────────────────────────────
    // Keyed on the wallpaper path, so adding or removing images from the
    // directory doesn't silently shuffle you onto a different theme.

    property bool restored: false

    function persist() {
        if (!root.restored)
            return;
        state.adapter.wallpaper = root.active.path;
        state.adapter.light = root.light;
        state.writeAdapter();
    }

    FileView {
        id: state
        path: `${root.home}/.local/state/quickshell/theme.json`
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: stateData
            property string wallpaper: ""
            property bool light: false
        }
    }

    // ── Scan ────────────────────────────────────────────────────

    function rescan() {
        scanProc.running = true;
    }

    // Poll the wallpaper directory so a picture dropped in mid-session shows
    // up in the picker without needing Super+Shift+... / `qs ipc call theme
    // rescan`. The scan script hashes paths+mtimes and returns its cache
    // untouched when nothing changed, so this is cheap even every few
    // seconds — no inotify dependency needed.
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.rescan()
    }

    Process {
        id: scanProc
        command: [`${root.home}/.config/quickshell/scripts/scan-wallpapers.sh`, root.wallDir]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed;
                try {
                    parsed = JSON.parse(this.text);
                } catch (e) {
                    console.warn("theme: could not parse wallpaper scan:", e);
                    return;
                }

                root.themes = parsed.items ?? [];
                if (root.themes.length === 0)
                    return;

                root.light = stateData.light;

                const i = root.themes.findIndex(t => t.path === stateData.wallpaper);
                if (i >= 0) {
                    root.index = i;
                    root.restored = true;
                    root.applyBorders();
                } else {
                    // Nothing remembered yet — adopt whatever awww is already
                    // showing rather than yanking the desktop to image one.
                    queryProc.running = true;
                }
            }
        }
    }

    // "eDP-1: 1536x864, scale: 1.25, currently displaying: image: /path.jpg"
    Process {
        id: queryProc
        command: ["awww", "query"]

        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/image:\s*(\S.*?)\s*$/m);
                const i = m ? root.themes.findIndex(t => t.path === m[1]) : -1;
                root.index = i >= 0 ? i : 0;
                root.restored = true;
                root.applyBorders();
                root.persist();
            }
        }
    }

    IpcHandler {
        target: "theme"

        // Super+T — open the picker, or close it if it is already up.
        function toggle(): void {
            root.popupOpen = !root.popupOpen;
        }

        function open(): void {
            root.popupOpen = true;
        }

        function close(): void {
            root.popupOpen = false;
        }

        // Super+Shift+T — skip the picker, jump straight to the next theme.
        function next(): void {
            root.next();
        }

        function prev(): void {
            root.prev();
        }

        // Super+Shift+D — flip dark/light on the current wallpaper.
        function mode(): void {
            root.toggleMode();
        }

        function dark(): void {
            root.setLight(false);
        }

        function light(): void {
            root.setLight(true);
        }

        function set(name: string): void {
            if (!root.selectByName(name))
                console.warn("theme: no theme named", name);
        }

        function list(): string {
            return root.themes.map((t, i) => `${i === root.index ? "*" : " "} ${t.name}  ${t.seed}`).join("\n");
        }

        function current(): string {
            return `${root.active.name} (${root.light ? "light" : "dark"}) ${root.active.seed}`;
        }

        // Pick up images added to the wallpaper directory since startup.
        function rescan(): void {
            root.rescan();
        }
    }
}
