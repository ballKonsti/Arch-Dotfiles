pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool ready: sink?.audio ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round(volume * 100)

    readonly property bool micMuted: source?.audio?.muted ?? true

    readonly property string icon: {
        if (muted || volume <= 0.001)
            return "󰝟";
        if (volume < 0.34)
            return "󰕿";
        if (volume < 0.67)
            return "󰖀";
        return "󰕾";
    }

    function set(v: real) {
        if (!sink?.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(1.4, v));
    }

    function nudge(delta: real) {
        set(volume + delta);
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // Keep the default nodes bound so their properties stay live.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
