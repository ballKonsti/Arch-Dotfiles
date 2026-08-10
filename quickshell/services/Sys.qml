pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// One shared clock + uptime for the whole shell.
Singleton {
    id: root

    readonly property date now: clock.date
    readonly property string time: Qt.formatDateTime(now, "HH:mm")
    readonly property string seconds: Qt.formatDateTime(now, "ss")
    readonly property string dateShort: Qt.formatDateTime(now, "ddd d MMM")
    readonly property string dateLong: Qt.formatDateTime(now, "dddd, d MMMM")

    property int uptimeSeconds: 0
    readonly property string uptime: {
        const d = Math.floor(uptimeSeconds / 86400);
        const h = Math.floor((uptimeSeconds % 86400) / 3600);
        const m = Math.floor((uptimeSeconds % 3600) / 60);
        if (d > 0)
            return `${d}d ${h}h`;
        if (h > 0)
            return `${h}h ${m}m`;
        return `${m}m`;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = Math.floor(parseFloat(text().split(" ")[0]) || 0)
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeFile.reload()
    }
}
