pragma Singleton

import Quickshell
import Quickshell.Io

// One Notch instance exists per monitor (see modules/Bar.qml), but an
// IpcHandler target is global to the whole shell process — two Notches
// each declaring target: "notch" would collide, so only one monitor would
// ever respond to Super+W. Instead each Notch registers itself here, and
// this singleton is the only thing that owns the "notch" IPC target,
// fanning every call out to all registered instances.
Singleton {
    id: root

    property var instances: []

    function register(notch): void {
        root.instances.push(notch);
    }

    function unregister(notch): void {
        const i = root.instances.indexOf(notch);
        if (i !== -1)
            root.instances.splice(i, 1);
    }

    IpcHandler {
        target: "notch"

        // Super+W — waves in if hidden, waves out if shown
        function toggle(): void {
            for (const n of root.instances) {
                if (n.shown)
                    n.playOutro();
                else
                    n.playIntro();
            }
        }

        function replay(): void {
            for (const n of root.instances)
                n.playIntro();
        }

        function hide(): void {
            for (const n of root.instances)
                n.playOutro();
        }

        function open(): void {
            for (const n of root.instances)
                n.pinned = true;
        }

        function close(): void {
            for (const n of root.instances)
                n.pinned = false;
        }
    }
}
