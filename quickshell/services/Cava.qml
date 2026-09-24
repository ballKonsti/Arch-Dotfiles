pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Real audio-reactive bar levels, via `cava`'s raw output mode. Generates its
// own config in the runtime dir so it never fights with a user cava config
// elsewhere, and always matches `barCount` below.
Singleton {
    id: root

    readonly property int barCount: 3
    property list<real> levels: Array(barCount).fill(0)

    readonly property string configPath: `${Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp"}/quickshell-cava.conf`

    readonly property string configText: `
[general]
bars = ${barCount}
autosens = 1

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
`

    FileView {
        id: configFile
        path: root.configPath
        printErrors: false
    }

    Component.onCompleted: {
        configFile.setText(root.configText);
        cavaProc.running = true;
    }

    Process {
        id: cavaProc
        command: ["cava", "-p", root.configPath]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";").filter(s => s.length > 0).map(Number);
                if (parts.length === root.barCount)
                    root.levels = parts;
            }
        }
    }
}
