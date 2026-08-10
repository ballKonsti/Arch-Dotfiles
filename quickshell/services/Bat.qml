pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property bool available: dev?.isLaptopBattery ?? false
    readonly property real level: dev?.percentage ?? 0        // 0..1
    readonly property int percent: Math.round(level * 100)
    readonly property bool charging: dev ? (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged) : false
    readonly property bool critical: available && !charging && percent <= 15
    readonly property bool low: available && !charging && percent <= 30

    readonly property int secondsLeft: charging ? (dev?.timeToFull ?? 0) : (dev?.timeToEmpty ?? 0)

    readonly property string eta: {
        if (secondsLeft <= 0)
            return charging ? "charged" : "—";
        const h = Math.floor(secondsLeft / 3600);
        const m = Math.floor((secondsLeft % 3600) / 60);
        const s = h > 0 ? `${h}h ${m}m` : `${m}m`;
        return charging ? `${s} to full` : `${s} left`;
    }

    readonly property color tint: critical ? Theme.crit : (low ? Theme.warn : (charging ? Theme.good : Theme.text))

    readonly property string icon: {
        if (charging)
            return "󰂄";
        const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return icons[Math.min(10, Math.max(0, Math.round(level * 10)))];
    }
}
