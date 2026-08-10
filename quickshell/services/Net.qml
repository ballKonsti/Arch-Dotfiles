pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Network state, polled from NetworkManager.
Singleton {
    id: root

    property string kind: "none"      // "wifi" | "ethernet" | "none"
    property string name: ""          // SSID or connection name
    property int strength: 0          // 0-100, wifi only

    readonly property bool up: kind !== "none"
    readonly property string icon: {
        if (kind === "ethernet")
            return "󰈀";
        if (kind !== "wifi")
            return "󰤭";
        if (strength >= 80)
            return "󰤨";
        if (strength >= 55)
            return "󰤥";
        if (strength >= 30)
            return "󰤢";
        if (strength >= 10)
            return "󰤟";
        return "󰤯";
    }

    function refresh() {
        if (!poll.running)
            poll.running = true;
    }

    Process {
        id: poll
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null | grep -m1 ':connected:'; nmcli -t -f IN-USE,SIGNAL,SSID device wifi list --rescan no 2>/dev/null | grep -m1 '^\\*'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                let kind = "none";
                let name = "";
                let strength = 0;

                for (const line of lines) {
                    if (line.startsWith("*")) {
                        // IN-USE:SIGNAL:SSID
                        const p = line.split(":");
                        strength = parseInt(p[1]) || 0;
                        if (p.length > 2 && p[2].length > 0)
                            name = p.slice(2).join(":");
                    } else {
                        // TYPE:STATE:CONNECTION
                        const p = line.split(":");
                        kind = p[0] === "wifi" ? "wifi" : (p[0] === "ethernet" ? "ethernet" : kind);
                        if (name.length === 0 && p.length > 2)
                            name = p.slice(2).join(":");
                    }
                }

                root.kind = kind;
                root.name = name;
                root.strength = strength;
            }
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
