import QtQuick
import QtQuick.Effects
import QtQuick.Window
import QtWebEngine

// The app half of Cadence: a fullscreen window that hosts the web apps the
// launcher (modules/Cadence.qml) hands it. Run by cadence-web.py, never by
// Quickshell — QtWebEngine aborts inside the shell process.
//
// The page always gets the whole screen. The controls float over it and
// tuck themselves away a moment after the mouse stops moving; nudging the
// mouse to the top edge brings them back. Each app gets its own web view,
// created the first time it's opened and kept alive after that, so Home →
// launcher → back resumes where you were.
Window {
    id: win

    readonly property color bg: "#1a1040"
    readonly property color glass: Qt.rgba(0.08, 0.05, 0.19, 0.84)
    readonly property color yellow: "#f7c948"
    readonly property string fontUI: "Inter"
    readonly property string fontIcon: "JetBrainsMono Nerd Font"

    // App descriptors as the launcher sent them, keyed by name.
    property var apps: ({})
    property var order: []
    property string current: ""
    // A page asked for real fullscreen (a video player's button).
    property bool pageFullscreen: false

    readonly property var app: win.apps[win.current] ?? null
    readonly property var slot: {
        for (let i = 0; i < views.count; i++) {
            const it = views.itemAt(i);
            if (it && it.key === win.current)
                return it;
        }
        return null;
    }
    readonly property var view: win.slot?.page ?? null

    title: win.app ? `Cadence — ${win.app.name}` : "Cadence"
    color: win.bg
    visible: false
    width: 1280
    height: 800

    function glyph(cp: int): string {
        return String.fromCodePoint(cp);
    }

    function open(app: var): void {
        const fresh = !win.apps[app.name];
        const a = Object.assign({}, win.apps);
        a[app.name] = app;
        win.apps = a;
        if (fresh)
            win.order = win.order.concat([app.name]);
        win.current = app.name;
        // A deep link (a film or series picked on the launcher) sends an
        // app that's already open straight to it.
        if (!fresh && app.go && win.view)
            win.view.url = app.go;
        win.showFullScreen();
        win.raise();
        win.requestActivate();
        controls.poke(3500);
        // Tell the launcher it can fade out now: we're underneath it.
        handoff.restart();
        Qt.callLater(() => win.view?.forceActiveFocus());
    }

    function home(): void {
        win.pageFullscreen = false;
        win.hide();
        bridge.goHome();
    }

    // Close the current app outright: its page is torn down, not just hidden.
    function quit(): void {
        const name = win.current;
        win.current = "";
        const a = Object.assign({}, win.apps);
        delete a[name];
        win.apps = a;
        win.order = win.order.filter(n => n !== name);
        win.home();
    }

    function switchTo(name: string): void {
        win.current = name;
        controls.poke(2500);
        Qt.callLater(() => win.view?.forceActiveFocus());
    }

    // Super+Q (or anything else closing the window) goes home instead of
    // killing every open app.
    onClosing: close => {
        close.accepted = false;
        win.home();
    }

    // A beat after mapping, so the compositor has actually put us on screen
    // before the launcher's overlay goes.
    Timer {
        id: handoff
        interval: 250
        onTriggered: bridge.shown()
    }

    Connections {
        target: bridge

        function onOpenApp(json: string): void {
            win.open(JSON.parse(json));
        }

        function onHideAll(): void {
            win.pageFullscreen = false;
            win.hide();
        }
    }

    // Logins and cookies persist under ~/.local/share/cadence-web.
    // Desktop Chrome UA, because some services turn QtWebEngine's own away.
    WebEngineProfile {
        id: desktopProfile
        storageName: "cadence"
        offTheRecord: false
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpUserAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
    }

    // YouTube only serves its couch UI (youtube.com/tv) to things that look
    // like a TV. Separate storage so the two profiles don't fight over it.
    WebEngineProfile {
        id: tvProfile
        storageName: "cadence-tv"
        offTheRecord: false
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        httpUserAgent: "Mozilla/5.0 (SMART-TV; Linux; Tizen 6.0) AppleWebKit/538.1 (KHTML, like Gecko) Version/6.0 TV Safari/538.1"
    }

    Shortcut {
        sequences: ["Alt+Home", "Ctrl+Escape"]
        onActivated: win.home()
    }

    Shortcut {
        sequence: "Ctrl+W"
        onActivated: win.quit()
    }

    Shortcut {
        sequences: ["Alt+Left", "Back"]
        onActivated: win.view?.goBack()
    }

    Shortcut {
        sequences: ["Alt+Right", "Forward"]
        onActivated: win.view?.goForward()
    }

    Shortcut {
        sequences: ["F5", "Ctrl+R"]
        onActivated: win.view?.reload()
    }

    // Show the controls without touching the mouse.
    Shortcut {
        sequence: "Ctrl+Space"
        onActivated: controls.poke(3000)
    }

    Item {
        id: root
        anchors.fill: parent

        // Watches the pointer without taking anything from the page.
        HoverHandler {
            id: hover
            onPointChanged: {
                if (hover.point.position.y < 120)
                    controls.poke(2200);
            }
        }

        // ── Pages ───────────────────────────────────────────────
        Repeater {
            id: views
            model: win.order

            Item {
                id: slotItem
                required property string modelData
                readonly property string key: slotItem.modelData
                readonly property var app: win.apps[slotItem.key]
                property alias page: page
                // Until the first page has painted, a branded splash covers
                // the white flash of an empty web view.
                property bool ready: false

                anchors.fill: parent
                visible: win.current === slotItem.key

                WebEngineView {
                    id: page
                    anchors.fill: parent

                    url: slotItem.app?.go ?? slotItem.app?.url ?? "about:blank"
                    profile: slotItem.app?.tv ? tvProfile : desktopProfile
                    backgroundColor: win.bg
                    focus: slotItem.visible

                    settings.fullScreenSupportEnabled: true
                    settings.playbackRequiresUserGesture: false
                    settings.javascriptCanAccessClipboard: true
                    settings.localStorageEnabled: true

                    onLoadingChanged: request => {
                        if (request.status === WebEngineView.LoadSucceededStatus || request.status === WebEngineView.LoadFailedStatus)
                            slotItem.ready = true;
                    }

                    onFullScreenRequested: request => {
                        request.accept();
                        win.pageFullscreen = request.toggleOn;
                    }

                    // Popups and target=_blank links open in place — there
                    // are no other windows to put them in.
                    onNewWindowRequested: request => page.url = request.requestedUrl

                    onPermissionRequested: permission => permission.grant()
                }

                // ── Splash ──────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    color: win.bg
                    opacity: slotItem.ready ? 0 : 1
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 450
                            easing.type: Easing.OutCubic
                        }
                    }

                    RectangularShadow {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: width
                        radius: width / 2
                        blur: 260
                        color: Qt.alpha(slotItem.app?.glow ?? "#7a5cff", 0.28)
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 28

                        Item {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 150
                            height: 150

                            RectangularShadow {
                                anchors.fill: splashTile
                                radius: splashTile.radius
                                blur: 60
                                offset.y: 18
                                color: Qt.alpha(slotItem.app?.glow ?? "#7a5cff", 0.5)
                            }

                            Tile {
                                id: splashTile
                                anchors.fill: parent
                                app: slotItem.app
                            }

                            SequentialAnimation on scale {
                                running: !slotItem.ready && slotItem.visible
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 1.04
                                    duration: 900
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 1
                                    duration: 900
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }

                        // Load progress.
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 180
                            height: 4
                            radius: 2
                            color: Qt.rgba(1, 1, 1, 0.12)

                            Rectangle {
                                width: parent.width * Math.max(0.06, page.loadProgress / 100)
                                height: parent.height
                                radius: 2
                                color: win.yellow

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Controls ────────────────────────────────────────────
        Item {
            id: controls

            property bool awake: false

            function poke(ms: int): void {
                if (win.pageFullscreen)
                    return;
                controls.awake = true;
                nap.interval = ms;
                nap.restart();
            }

            Timer {
                id: nap
                // Stay up while the pointer is over a control.
                onTriggered: {
                    if (barsHover.hovered)
                        nap.restart();
                    else
                        controls.awake = false;
                }
            }

            anchors.left: parent.left
            anchors.right: parent.right
            height: 120
            readonly property bool shown: controls.awake && !win.pageFullscreen
            y: controls.shown ? 0 : -40
            opacity: controls.shown ? 1 : 0
            visible: opacity > 0

            Behavior on y {
                NumberAnimation {
                    duration: 280
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            HoverHandler {
                id: barsHover
            }

            // Soft scrim so the pills read over any page.
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(0, 0, 0, 0.5)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(0, 0, 0, 0)
                    }
                }
            }

            // Left: home + navigation.
            Pill {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 20

                Row {
                    spacing: 4

                    Rectangle {
                        width: homeRow.width + 28
                        height: 40
                        radius: 20
                        color: homeArea.containsMouse ? Qt.lighter(win.yellow, 1.08) : win.yellow

                        Row {
                            id: homeRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: win.glyph(0xF02DC)
                                color: "#1a0f3d"
                                font.family: win.fontIcon
                                font.pixelSize: 17
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Home"
                                color: "#1a0f3d"
                                font.family: win.fontUI
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: homeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.home()
                        }
                    }

                    Item {
                        width: 6
                        height: 1
                    }

                    IconButton {
                        glyph: 0xF004D
                        enabled: win.view?.canGoBack ?? false
                        onClicked: win.view?.goBack()
                    }

                    IconButton {
                        glyph: 0xF0054
                        enabled: win.view?.canGoForward ?? false
                        onClicked: win.view?.goForward()
                    }

                    IconButton {
                        glyph: (win.view?.loading ?? false) ? 0xF0156 : 0xF0450
                        onClicked: win.view?.loading ? win.view.stop() : win.view?.reload()
                    }
                }
            }

            // Middle: what's playing.
            Pill {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 20

                Row {
                    spacing: 10

                    Item {
                        width: 4
                        height: 1
                    }

                    Tile {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        app: win.app
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: win.app?.name ?? ""
                        color: "#ffffff"
                        font.family: win.fontUI
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Item {
                        width: 8
                        height: 1
                    }
                }
            }

            // Right: other open apps, then quit.
            Pill {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20

                Row {
                    spacing: 6

                    Repeater {
                        model: win.order.filter(n => n !== win.current)

                        Item {
                            id: other
                            required property string modelData
                            width: 40
                            height: 40

                            Tile {
                                anchors.centerIn: parent
                                width: otherArea.containsMouse ? 32 : 28
                                height: width
                                app: win.apps[other.modelData]
                                opacity: otherArea.containsMouse ? 1 : 0.7

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 140
                                    }
                                }
                            }

                            MouseArea {
                                id: otherArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.switchTo(other.modelData)
                            }
                        }
                    }

                    Rectangle {
                        visible: win.order.length > 1
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 22
                        color: Qt.rgba(1, 1, 1, 0.15)
                    }

                    IconButton {
                        glyph: 0xF0156
                        label: "Quit app"
                        onClicked: win.quit()
                    }
                }
            }

            // Load progress across the very top of the screen.
            Rectangle {
                anchors.top: parent.top
                height: 2
                width: parent.width * ((win.view?.loadProgress ?? 100) / 100)
                color: win.yellow
                opacity: (win.view?.loading ?? false) && (win.slot?.ready ?? false) ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 260
                    }
                }
            }
        }

        // One-time hint, the first time the controls tuck away.
        Rectangle {
            id: hint
            property bool used: false
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            width: hintText.width + 32
            height: 34
            radius: 17
            color: win.glass
            opacity: !hint.used && !controls.shown && win.visible && !win.pageFullscreen && (win.slot?.ready ?? false) ? 1 : 0
            visible: opacity > 0

            onOpacityChanged: {
                if (opacity === 1)
                    hintOff.restart();
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }

            Timer {
                id: hintOff
                interval: 2600
                onTriggered: hint.used = true
            }

            Text {
                id: hintText
                anchors.centerIn: parent
                text: "Move the mouse to the top for controls  ·  Ctrl+Esc for Home"
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: win.fontUI
                font.pixelSize: 12
            }
        }
    }

    // ── Pieces ──────────────────────────────────────────────────
    component Pill: Rectangle {
        id: p
        default property alias content: inner.data

        width: inner.childrenRect.width + 12
        height: 52
        radius: 26
        color: win.glass
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        Item {
            id: inner
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: 40
        }
    }

    component IconButton: Rectangle {
        id: b
        property int glyph
        property string label: ""
        signal clicked

        width: b.label ? bRow.width + 26 : 40
        height: 40
        radius: 20
        color: bArea.containsMouse && b.enabled ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
        opacity: b.enabled ? 1 : 0.32

        Row {
            id: bRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: String.fromCodePoint(b.glyph)
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: b.label.length > 0
                text: b.label
                color: "#ffffff"
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: bArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (b.enabled) b.clicked()
        }
    }

    // An app's tile: brand colour, glyph or wordmark (mirrors the shell's
    // widgets/AppTile.qml, which this process can't import).
    component Tile: Rectangle {
        id: t
        property var app: null
        readonly property real side: Math.min(t.width, t.height)

        radius: t.side * 0.24
        color: t.app?.tile ?? "transparent"

        Rectangle {
            anchors.fill: parent
            radius: t.radius
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(1, 1, 1, 0.14)
                }
                GradientStop {
                    position: 0.55
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: t.app ? (t.app.icon ? String.fromCodePoint(t.app.icon) : t.app.word) : ""
            color: t.app?.fg ?? "#ffffff"
            font.family: t.app?.icon ? "JetBrainsMono Nerd Font" : "Inter"
            font.pixelSize: t.app?.icon ? t.side * 0.5 : t.side * ((t.app?.word ?? "").length > 3 ? 0.27 : 0.34)
            font.weight: Font.Black
        }
    }
}
