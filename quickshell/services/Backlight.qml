pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen backlight. Reads sysfs directly (cheap, event driven) and
// writes through brightnessctl so we don't need root.
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int raw: 0

    readonly property bool available: device !== "" && max > 0
    readonly property real value: max > 0 ? raw / max : 0   // 0..1
    readonly property int percent: Math.round(value * 100)

    readonly property string icon: {
        if (percent >= 66)
            return "󰃠";
        if (percent >= 33)
            return "󰃟";
        return "󰃞";
    }

    function set(v: real) {
        if (!available)
            return;
        const clamped = Math.max(0.01, Math.min(1, v));
        root.raw = Math.round(clamped * max);   // optimistic, sysfs confirms
        apply.command = ["brightnessctl", "-d", device, "-q", "set", Math.round(clamped * 100) + "%"];
        apply.running = true;
    }

    function nudge(delta: real) {
        set(value + delta);
    }

    Process {
        id: apply
    }

    // Find the first backlight device once at startup.
    Process {
        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text().trim()) || 0
    }

    FileView {
        id: current
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.raw = parseInt(text().trim()) || 0
    }
}
