#!/usr/bin/env python3
"""Host process for Cadence's in-launcher apps (see CadenceWeb.qml).

QtWebEngine can't run inside Quickshell (Chromium aborts on its empty argv),
so the launcher hands apps to this process instead:

    cadence-web.py '{"cmd": "open", "app": {...}}'
    cadence-web.py '{"cmd": "hide"}'

The first `open` starts the host; later calls are passed to the running one
over a unix socket and return straight away. `hide` never starts it.
"""

import json
import os
import socket
import subprocess
import sys
from pathlib import Path

SOCK = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "cadence-web.sock")
WIDEVINE = "/opt/google/chrome/WidevineCdm/_platform_specific/linux_x64/libwidevinecdm.so"


def forward(line: str) -> bool:
    """Hand a message to the running host. False if there isn't one."""
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(SOCK)
            s.sendall(line.encode() + b"\n")
        return True
    except OSError:
        return False


def ensure_fullscreen() -> bool:
    """Make our window really fullscreen. True once it is (or can't be helped).

    Qt's fullscreen request is ignored when the window maps while the
    launcher overlay holds keyboard focus, and Hyprland's fullscreen window
    rule doesn't apply in this setup — so ask the compositor directly,
    addressing our own window by pid. The dispatcher toggles, hence the
    state check first.
    """
    try:
        clients = json.loads(subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=2).stdout)
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return True
    me = next((c for c in clients if c.get("pid") == os.getpid()), None)
    if me is None:
        return False  # not mapped yet
    sel = f"pid:{os.getpid()}"
    # Keys go to the app, not to whatever had focus before the launcher.
    subprocess.run(["hyprctl", "dispatch", f'hl.dsp.focus({{ window = "{sel}" }})'], capture_output=True, timeout=2)
    if me.get("fullscreen") != 2:
        subprocess.run(["hyprctl", "dispatch", f'hl.dsp.window.fullscreen({{ mode = "fullscreen", window = "{sel}" }})'], capture_output=True, timeout=2)
    return True


def main() -> int:
    msg = sys.argv[1] if len(sys.argv) > 1 else None
    if msg:
        if forward(msg):
            return 0
        if json.loads(msg).get("cmd") != "open":
            return 0

    # Only the host pays for the Qt import.
    if Path(WIDEVINE).exists():
        os.environ.setdefault("QTWEBENGINE_CHROMIUM_FLAGS", f"--widevine-path={WIDEVINE}")

    from PySide6.QtCore import QObject, QProcess, QTimer, QUrl, Signal, Slot
    from PySide6.QtGui import QGuiApplication
    from PySide6.QtNetwork import QLocalServer
    from PySide6.QtQml import QQmlApplicationEngine
    from PySide6.QtWebEngineQuick import QtWebEngineQuick

    class Bridge(QObject):
        openApp = Signal(str)
        hideAll = Signal()

        @Slot()
        def goHome(self) -> None:
            QProcess.startDetached("qs", ["ipc", "call", "cadence", "open"])

        @Slot()
        def shown(self) -> None:
            # Launcher out of the way first, then fullscreen — retried for a
            # few seconds, since a cold start can still be mapping.
            QProcess.startDetached("qs", ["ipc", "call", "cadence", "handoff"])
            tries = [0]

            def attempt() -> None:
                tries[0] += 1
                if not ensure_fullscreen() and tries[0] < 15:
                    QTimer.singleShot(200, attempt)

            QTimer.singleShot(300, attempt)

    QtWebEngineQuick.initialize()
    app = QGuiApplication(sys.argv)
    app.setApplicationName("cadence-web")
    app.setDesktopFileName("cadence-web")

    bridge = Bridge()

    def handle(line: str) -> None:
        try:
            m = json.loads(line)
        except ValueError:
            return
        if m.get("cmd") == "open" and m.get("app"):
            bridge.openApp.emit(json.dumps(m["app"]))
        elif m.get("cmd") == "hide":
            bridge.hideAll.emit()

    QLocalServer.removeServer(SOCK)
    server = QLocalServer()
    if not server.listen(SOCK):
        print(f"cadence-web: can't listen on {SOCK}: {server.errorString()}", file=sys.stderr)
        return 1

    def accept() -> None:
        conn = server.nextPendingConnection()
        buf = bytearray()

        def read() -> None:
            buf.extend(conn.readAll().data())
            while b"\n" in buf:
                line, _, rest = bytes(buf).partition(b"\n")
                buf[:] = rest
                handle(line.decode(errors="replace"))

        conn.readyRead.connect(read)
        conn.disconnected.connect(conn.deleteLater)

    server.newConnection.connect(accept)

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("bridge", bridge)
    engine.load(QUrl.fromLocalFile(str(Path(__file__).resolve().with_name("CadenceWeb.qml"))))
    if not engine.rootObjects():
        return 1

    if msg:
        handle(msg)

    rc = app.exec()
    server.close()
    return rc


if __name__ == "__main__":
    sys.exit(main())
