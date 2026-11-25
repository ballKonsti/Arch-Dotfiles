pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Open/closed state for the Cadence launcher, and its IPC target.
// `qs ipc call cadence toggle` is bound to Super+Shift+H.
Singleton {
    id: root

    property bool open: false
    // The monitor that was focused when the launcher was opened — it pops
    // up there, not on whichever screen happens to be first.
    property string screenName: ""
    // Set while an app is playing in the Cadence frame: the notch is put
    // away so video gets the whole screen, and comes back when you leave.
    property bool notchHidden: false

    // Remote-control presses from IPC ("up", "down", "left", "right",
    // "select", "back"), handled by the launcher like the matching keys.
    signal remote(string key)

    function show(): void {
        root.screenName = Hyprland.focusedMonitor?.name ?? "";
        root.open = true;
    }

    // Back to the desktop: launcher gone, notch back if we hid it.
    function hide(): void {
        root.open = false;
        if (root.notchHidden) {
            root.notchHidden = false;
            Quickshell.execDetached(["qs", "ipc", "call", "notch", "replay"]);
        }
    }

    // The launcher steps aside for an app: notch goes too, until we're done.
    function handOff(): void {
        root.open = false;
        if (!root.notchHidden) {
            root.notchHidden = true;
            Quickshell.execDetached(["qs", "ipc", "call", "notch", "hide"]);
        }
    }

    IpcHandler {
        target: "cadence"

        function toggle(): void {
            if (root.open)
                root.hide();
            else
                root.show();
        }

        function open(): void {
            root.show();
        }

        function close(): void {
            root.hide();
        }

        // The app frame calls this once it's on screen, so the launcher
        // only steps aside when there's something to step aside for.
        function handoff(): void {
            if (root.open)
                root.handOff();
        }

        // Remote control: `qs ipc call cadence press down`, etc.
        function press(key: string): void {
            if (root.open)
                root.remote(key);
        }
    }
}
