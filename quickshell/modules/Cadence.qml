import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Cadence — a fullscreen, Fire-TV-style home screen. Super+Shift+H pops it up
// on the focused monitor. Rows of tiles fill the bottom: your apps first,
// then suggested films and series (services/Suggest.qml) on the services
// you have apps for. The hero above follows the focused tile — backdrop,
// title, what it is and where it streams.
//
// Enter opens the app, or plays the title, in Cadence's own fullscreen app
// frame (scripts/cadence-web.py) — a separate process, because QtWebEngine
// aborts inside Quickshell. The frame's Home button brings this back.
PanelWindow {
    id: win

    readonly property color bg: "#1a1040"
    readonly property color ink: "#ffffff"
    readonly property color inkSoft: Qt.rgba(1, 1, 1, 0.72)
    readonly property color inkFaint: Qt.rgba(1, 1, 1, 0.45)
    readonly property color yellow: "#f7c948"
    readonly property color shadowInk: "#1a0f3d"

    readonly property int cardW: 240
    readonly property int cardH: 135
    readonly property int rowH: 206

    // mark: what's drawn on the tile. A Nerd Font codepoint when `icon` is
    // set, otherwise a wordmark in the UI font.
    readonly property var apps: [
        { name: "Netflix",     tagline: "Stream movies and TV shows.",       blurb: "Series, films and documentaries — pick up where you left off.",          tile: "#141414", fg: "#e50914", glow: "#e50914", icon: 0xF0746, url: "https://www.netflix.com" },
        { name: "YouTube",     tagline: "Broadcast yourself.",               blurb: "Opens in TV mode — big type, made for the couch and the arrow keys.",   tile: "#ff0033", fg: "#ffffff", glow: "#ff0033", icon: 0xF05C3, url: "https://www.youtube.com/tv", tv: true },
        { name: "Prime Video", tagline: "Movies, series and live sport.",    blurb: "Amazon Originals and everything included with Prime.",                 tile: "#00a8e1", fg: "#ffffff", glow: "#1a98ff", word: "prime", url: "https://www.primevideo.com" },
        { name: "Disney+",     tagline: "Disney, Pixar, Marvel, Star Wars.", blurb: "Every saga and every classic, all in one place.",                      tile: "#0b1c5a", fg: "#ffffff", glow: "#2f6bff", word: "D+", url: "https://www.disneyplus.com" },
        { name: "Spotify",     tagline: "Music for everyone.",               blurb: "Your playlists, mixes and podcasts, picked up mid-song.",              tile: "#1ed760", fg: "#0b0b0b", glow: "#1ed760", icon: 0xF04C7, url: "https://open.spotify.com" },
        { name: "Plex",        tagline: "Your media, everywhere.",           blurb: "Your own library, plus free movies and live TV.",                      tile: "#1f2326", fg: "#e5a00d", glow: "#e5a00d", icon: 0xF06BA, url: "https://app.plex.tv" },
        { name: "Twitch",      tagline: "Live, together.",                   blurb: "Streams, chat and the channels you follow.",                           tile: "#9146ff", fg: "#ffffff", glow: "#9146ff", icon: 0xF0543, url: "https://www.twitch.tv" },
        { name: "Hulu",        tagline: "Stream TV and movies.",             blurb: "Current-season episodes the day after they air.",                      tile: "#1ce783", fg: "#0b0c0f", glow: "#1ce783", word: "hulu", url: "https://www.hulu.com" },
        { name: "Max",         tagline: "It's all here.",                    blurb: "HBO originals, blockbusters and the whole back catalogue.",            tile: "#002be7", fg: "#ffffff", glow: "#3d5cff", word: "max", url: "https://play.max.com" },
        { name: "Crunchyroll", tagline: "The home of anime.",                blurb: "Simulcasts an hour after Japan, plus the classics.",                    tile: "#f47521", fg: "#ffffff", glow: "#f47521", word: "CR", url: "https://www.crunchyroll.com" },
        { name: "Browser",     tagline: "Anywhere else on the web.",         blurb: "Start from a search page, for everything that isn't on this list.",    tile: "#ffffff", fg: "#261852", glow: "#c9b8ff", icon: 0xF059F, url: "https://duckduckgo.com" }
    ]

    function appNamed(name: string): var {
        return win.apps.find(a => a.name === name) ?? null;
    }

    // Rows on screen: apps, then whatever Suggest has (or a status row).
    readonly property var rowModel: {
        const rows = [{ label: "Your apps", kind: "apps", items: win.apps }];
        if (Suggest.rows.length > 0)
            return rows.concat(Suggest.rows.map(r => ({ label: r.label, kind: "titles", items: r.items })));
        return rows.concat([{
            label: Suggest.error ? `${Suggest.error} — press R to retry` : "Loading suggestions…",
            kind: "status",
            items: [0, 1, 2, 3, 4, 5, 6]
        }]);
    }

    // The tile that has focus: { kind: "app" | "title" | "status", data }.
    readonly property var focused: rowsView.currentItem?.focusedEntry ?? { kind: "app", data: win.apps[0] }

    readonly property string webHost: Quickshell.shellDir + "/scripts/cadence-web.py"

    function web(msg: var): void {
        Quickshell.execDetached(["python3", win.webHost, JSON.stringify(msg)]);
    }

    function activate(entry: var): void {
        if (!entry)
            return;
        if (entry.kind === "app") {
            win.web({ cmd: "open", app: entry.data });
        } else if (entry.kind === "title") {
            const app = win.appNamed(entry.data.offer.app);
            if (!app)
                return;
            // `go` sends an already-open app straight to the title's page.
            win.web({ cmd: "open", app: Object.assign({}, app, { go: entry.data.offer.url }) });
        } else {
            return;
        }
        // Stay up, showing a splash, until the frame says it's on screen
        // (CadenceState.handoff over IPC) — a cold start takes a second or
        // two, and the desktop would show through the gap.
        win.launching = entry.kind === "app" ? entry.data : win.appNamed(entry.data.offer.app);
        launchTimeout.restart();
    }

    // The app being handed to the frame, while its splash is up.
    property var launching: null

    Timer {
        id: launchTimeout
        interval: 8000
        onTriggered: CadenceState.handOff()
    }

    Connections {
        target: CadenceState
        function onOpenChanged(): void {
            if (!CadenceState.open) {
                launchTimeout.stop();
                win.launching = null;
            }
        }
    }

    screen: Quickshell.screens.find(s => s.name === CadenceState.screenName) ?? Quickshell.screens[0]
    // Stay mapped until the fade-out has finished.
    visible: CadenceState.open || stage.opacity > 0

    WlrLayershell.namespace: "cadence-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: CadenceState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
        if (!win.visible)
            return;
        keys.forceActiveFocus();
        Suggest.refreshIfStale();
        // Coming back to the launcher puts away whatever app was showing.
        win.web({ cmd: "hide" });
    }

    // ── Keyboard / remote ───────────────────────────────────────
    function press(key: string): bool {
        const row = rowsView.currentItem?.list;
        switch (key) {
        case "back":
            CadenceState.hide();
            break;
        case "up":
            rowsView.decrementCurrentIndex();
            break;
        case "down":
            rowsView.incrementCurrentIndex();
            break;
        case "left":
            row?.decrementCurrentIndex();
            break;
        case "right":
            row?.incrementCurrentIndex();
            break;
        case "home":
            rowsView.currentIndex = 0;
            break;
        case "select":
            win.activate(win.focused);
            break;
        case "refresh":
            Suggest.refresh();
            break;
        default:
            return false;
        }
        return true;
    }

    Connections {
        target: CadenceState
        function onRemote(key: string): void {
            win.press(key);
        }
    }

    Item {
        id: keys
        focus: true
        enabled: !win.launching

        readonly property var map: ({
                [Qt.Key_Escape]: "back",
                [Qt.Key_Up]: "up",
                [Qt.Key_Down]: "down",
                [Qt.Key_Left]: "left",
                [Qt.Key_Right]: "right",
                [Qt.Key_Home]: "home",
                [Qt.Key_Return]: "select",
                [Qt.Key_Enter]: "select",
                [Qt.Key_Space]: "select",
                [Qt.Key_R]: "refresh"
            })

        Keys.onPressed: event => {
            event.accepted = win.press(keys.map[event.key] ?? "");
        }
    }

    Rectangle {
        id: stage

        anchors.fill: parent
        color: win.bg
        clip: true

        opacity: CadenceState.open ? 1 : 0
        scale: CadenceState.open ? 1 : 1.03

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durMed
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.durMed + 80
                easing.bezierCurve: Theme.curve
                easing.type: Easing.Bezier
            }
        }

        // ── Hero data ───────────────────────────────────────────
        // What the hero shows lags the focus by a beat, so holding an arrow
        // key skims along the row without reloading a backdrop per tile.
        property var shown: win.focused
        property real fade: 1

        Timer {
            id: settle
            interval: 140
            onTriggered: swap.restart()
        }

        Connections {
            target: win
            function onFocusedChanged(): void {
                settle.restart();
            }
        }

        SequentialAnimation {
            id: swap
            NumberAnimation {
                target: stage
                property: "fade"
                to: 0
                duration: 110
                easing.type: Easing.InCubic
            }
            ScriptAction {
                script: stage.shown = win.focused
            }
            NumberAnimation {
                target: stage
                property: "fade"
                to: 1
                duration: 280
                easing.type: Easing.OutCubic
            }
        }

        readonly property bool showingTitle: stage.shown?.kind === "title" && !!stage.shown.data
        readonly property var title: stage.showingTitle ? stage.shown.data : null
        readonly property var heroApp: (stage.showingTitle ? win.appNamed(stage.title?.offer?.app ?? "") : (stage.shown?.kind === "app" ? stage.shown.data : null)) ?? win.apps[0]

        // Ambient light in the app's colour, behind everything.
        property color tint: stage.heroApp.glow

        Behavior on tint {
            ColorAnimation {
                duration: 420
                easing.type: Easing.OutCubic
            }
        }

        RectangularShadow {
            x: stage.width * 0.5
            y: -stage.height * 0.3
            width: stage.width * 0.55
            height: width
            radius: width / 2
            blur: 260
            color: Qt.alpha(stage.tint, 0.3)
        }

        RectangularShadow {
            x: -stage.width * 0.1
            y: stage.height * 0.65
            width: stage.width * 0.4
            height: width
            radius: width / 2
            blur: 240
            color: Qt.rgba(0.45, 0.3, 1, 0.14)
        }

        // ── Backdrop ────────────────────────────────────────────
        // Two images cross-fading: the incoming one only takes over once
        // it has actually loaded.
        Item {
            id: backdrop

            anchors.top: parent.top
            anchors.right: parent.right
            width: parent.width * 0.74
            height: parent.height * 0.74

            readonly property string src: stage.title?.backdrop ?? ""
            property bool frontA: true

            onSrcChanged: {
                if (!backdrop.src) {
                    imgA.opacity = 0;
                    imgB.opacity = 0;
                    return;
                }
                (backdrop.frontA ? imgB : imgA).source = backdrop.src;
            }

            function arrived(img: Image, other: Image, isA: bool): void {
                if (img.status !== Image.Ready || img.source.toString() !== backdrop.src)
                    return;
                img.opacity = 1;
                other.opacity = 0;
                backdrop.frontA = isA;
            }

            Image {
                id: imgA
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: 0
                onStatusChanged: backdrop.arrived(imgA, imgB, true)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 520
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Image {
                id: imgB
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                opacity: 0
                onStatusChanged: backdrop.arrived(imgB, imgA, false)

                Behavior on opacity {
                    NumberAnimation {
                        duration: 520
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Melt the image into the background on the left and bottom so
            // the text over it stays readable.
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: win.bg
                    }
                    GradientStop {
                        position: 0.38
                        color: Qt.alpha(win.bg, 0.55)
                    }
                    GradientStop {
                        position: 0.7
                        color: Qt.alpha(win.bg, 0)
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(win.bg, 0.35)
                    }
                    GradientStop {
                        position: 0.25
                        color: Qt.alpha(win.bg, 0)
                    }
                    GradientStop {
                        position: 0.7
                        color: Qt.alpha(win.bg, 0.25)
                    }
                    GradientStop {
                        position: 1
                        color: win.bg
                    }
                }
            }
        }

        // ── Top bar ─────────────────────────────────────────────
        Item {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 32
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            height: 44

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    color: win.yellow

                    Text {
                        anchors.centerIn: parent
                        text: "K"
                        color: win.shadowInk
                        font.family: Theme.fontUI
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const h = clock.date.getHours();
                        if (h < 5)
                            return "Good night";
                        if (h < 12)
                            return "Good morning";
                        if (h < 18)
                            return "Good afternoon";
                        return "Good evening";
                    }
                    color: win.ink
                    font.family: Theme.fontUI
                    font.pixelSize: 18
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: statusRow.width + 32
                height: 40
                radius: 20
                color: Qt.rgba(0, 0, 0, 0.3)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                Row {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Net.icon
                        color: win.ink
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatTime(clock.date, "HH:mm")
                        color: win.ink
                        font.family: Theme.fontUI
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.features: {
                            "tnum": 1
                        }
                    }
                }
            }
        }

        // ── Hero ────────────────────────────────────────────────
        Item {
            id: hero
            anchors.top: topBar.bottom
            anchors.bottom: rowsView.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 64
            anchors.rightMargin: 64

            // Big logo tile on the right while an app is focused (titles
            // have the backdrop instead).
            Item {
                id: logo
                anchors.right: parent.right
                anchors.rightMargin: parent.width * 0.06
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(hero.height - 70, 300)
                height: width
                visible: !stage.showingTitle
                opacity: stage.fade
                scale: 0.92 + 0.08 * stage.fade

                RectangularShadow {
                    anchors.fill: logoTile
                    radius: logoTile.radius
                    blur: 70
                    offset.y: 24
                    color: Qt.alpha(stage.heroApp.glow, 0.45)
                }

                AppTile {
                    id: logoTile
                    anchors.fill: parent
                    app: stage.heroApp
                }
            }

            Column {
                anchors.left: parent.left
                width: Math.min(parent.width * 0.5, 680)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: (1 - stage.fade) * 14
                opacity: stage.fade
                spacing: 0

                // "NETFLIX · SERIES" / "APP"
                Row {
                    spacing: 8

                    AppTile {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 22
                        app: stage.heroApp
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: stage.showingTitle ? `${stage.title?.offer?.service ?? ""}  ·  ${stage.title?.kind ?? ""}` : "App"
                        color: win.inkSoft
                        font.family: Theme.fontUI
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.2
                    }
                }

                Item {
                    width: 1
                    height: 12
                }

                Text {
                    width: parent.width
                    text: (stage.showingTitle ? stage.title?.title : stage.heroApp.name) ?? ""
                    color: win.ink
                    font.family: Theme.fontUI
                    font.pixelSize: text.length > 22 ? Math.min(52, stage.width * 0.036) : Math.min(76, stage.width * 0.05)
                    font.weight: Font.Black
                    font.letterSpacing: -1.5
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    lineHeight: 0.95
                }

                Item {
                    width: 1
                    height: 12
                }

                // Meta line: year · genres · runtime, then age and IMDb chips.
                Row {
                    visible: stage.showingTitle
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            const t = stage.title;
                            if (!t)
                                return "";
                            const bits = [];
                            if (t.year)
                                bits.push(t.year);
                            if (t.genres.length)
                                bits.push(t.genres.join(", "));
                            if (t.kind === "Movie" && t.runtime)
                                bits.push(`${Math.floor(t.runtime / 60)} h ${t.runtime % 60} min`);
                            return bits.join("   ·   ");
                        }
                        color: win.inkSoft
                        font.family: Theme.fontUI
                        font.pixelSize: 16
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: (stage.title?.age ?? "") !== ""
                        width: ageText.width + 14
                        height: 22
                        radius: 5
                        color: "transparent"
                        border.width: 1
                        border.color: win.inkFaint

                        Text {
                            id: ageText
                            anchors.centerIn: parent
                            text: stage.title?.age ?? ""
                            color: win.inkSoft
                            font.family: Theme.fontUI
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: (stage.title?.imdb ?? 0) > 0
                        width: imdbRow.width + 14
                        height: 22
                        radius: 5
                        color: "#f5c518"

                        Row {
                            id: imdbRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: "IMDb"
                                color: "#000000"
                                font.family: Theme.fontUI
                                font.pixelSize: 12
                                font.weight: Font.Black
                            }

                            Text {
                                text: (stage.title?.imdb ?? 0).toFixed(1)
                                color: "#000000"
                                font.family: Theme.fontUI
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                Text {
                    visible: !stage.showingTitle
                    width: parent.width
                    text: stage.heroApp.tagline
                    color: win.ink
                    font.family: Theme.fontUI
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Item {
                    width: 1
                    height: 12
                }

                Text {
                    width: Math.min(parent.width, 600)
                    text: (stage.showingTitle ? stage.title?.blurb : stage.heroApp.blurb) ?? ""
                    color: win.inkSoft
                    font.family: Theme.fontUI
                    font.pixelSize: 16
                    lineHeight: 1.3
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                Item {
                    width: 1
                    height: 24
                }

                Row {
                    spacing: 18

                    Rectangle {
                        width: playRow.width + 48
                        height: 50
                        radius: 25
                        color: win.yellow
                        scale: playArea.pressed ? 0.96 : playArea.containsMouse ? 1.03 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.durFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        Row {
                            id: playRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String.fromCodePoint(0xF040A)
                                color: win.shadowInk
                                font.family: Theme.fontIcon
                                font.pixelSize: 22
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: stage.showingTitle ? `Watch on ${stage.title?.offer?.app ?? ""}` : `Open ${stage.heroApp.name}`
                                color: win.shadowInk
                                font.family: Theme.fontUI
                                font.pixelSize: 16
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: playArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.activate(stage.shown)
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↑ ↓ ← →  browse     ⏎  play     esc  close"
                        color: win.inkFaint
                        font.family: Theme.fontUI
                        font.pixelSize: 13
                    }
                }
            }
        }

        // ── Rows ────────────────────────────────────────────────
        // The focused row sits at the top of this strip; rows above it slide
        // up out of view, the next one peeks in underneath.
        ListView {
            id: rowsView

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(stage.height * 0.44, win.rowH * 1.75)
            clip: true

            model: win.rowModel
            interactive: false
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: 0
            preferredHighlightEnd: win.rowH
            highlightMoveDuration: 340
            highlightMoveVelocity: -1

            WheelHandler {
                onWheel: event => {
                    if (Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)) {
                        const row = rowsView.currentItem?.list;
                        if (event.angleDelta.x < 0)
                            row?.incrementCurrentIndex();
                        else
                            row?.decrementCurrentIndex();
                    } else if (event.angleDelta.y < 0) {
                        rowsView.incrementCurrentIndex();
                    } else if (event.angleDelta.y > 0) {
                        rowsView.decrementCurrentIndex();
                    }
                }
            }

            delegate: Item {
                id: rowItem
                required property int index
                required property var modelData
                readonly property bool isCurrentRow: ListView.isCurrentItem
                property alias list: list

                readonly property var focusedEntry: {
                    const items = rowItem.modelData.items;
                    const data = items[list.currentIndex] ?? items[0];
                    if (!data)
                        return { kind: "status", data: null };
                    if (rowItem.modelData.kind === "apps")
                        return { kind: "app", data: data };
                    if (rowItem.modelData.kind === "titles")
                        return { kind: "title", data: data };
                    return { kind: "status", data: null };
                }

                width: rowsView.width
                height: win.rowH
                opacity: rowItem.isCurrentRow ? 1 : 0.55

                Behavior on opacity {
                    NumberAnimation {
                        duration: 240
                    }
                }

                Text {
                    id: rowLabel
                    x: 64
                    y: 6
                    text: rowItem.modelData.label
                    color: rowItem.isCurrentRow ? win.ink : win.inkSoft
                    font.family: Theme.fontUI
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }

                ListView {
                    id: list

                    anchors.top: rowLabel.bottom
                    anchors.topMargin: 6
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: win.cardH + 34

                    orientation: ListView.Horizontal
                    model: rowItem.modelData.items
                    spacing: 18
                    interactive: false
                    // The focused card stays at the left edge, Fire-TV style;
                    // the row slides along under it.
                    highlightRangeMode: ListView.StrictlyEnforceRange
                    preferredHighlightBegin: 64
                    preferredHighlightEnd: 64 + win.cardW
                    highlightMoveDuration: 300
                    highlightMoveVelocity: -1

                    delegate: Item {
                        id: card
                        required property int index
                        required property var modelData
                        readonly property bool isFocused: rowItem.isCurrentRow && ListView.isCurrentItem
                        readonly property bool isApp: rowItem.modelData.kind === "apps"
                        readonly property bool isStatus: rowItem.modelData.kind === "status"
                        readonly property bool isTitle: !card.isApp && !card.isStatus

                        width: win.cardW
                        height: list.height

                        Item {
                            id: face
                            y: 14
                            width: win.cardW
                            height: win.cardH
                            scale: card.isFocused ? 1.08 : cardArea.containsMouse ? 1.03 : 1
                            opacity: card.isFocused || !rowItem.isCurrentRow ? 1 : 0.78

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 240
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }

                            RectangularShadow {
                                anchors.fill: parent
                                radius: 14
                                blur: card.isFocused ? 34 : 18
                                spread: card.isFocused ? 2 : 0
                                offset.y: card.isFocused ? 0 : 8
                                color: card.isFocused ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(0, 0, 0, 0.45)
                            }

                            // App card.
                            AppTile {
                                anchors.fill: parent
                                visible: card.isApp
                                app: card.isApp ? card.modelData : win.apps[0]
                            }

                            // Placeholder while suggestions load.
                            Rectangle {
                                anchors.fill: parent
                                visible: card.isStatus
                                radius: 14
                                color: Qt.rgba(1, 1, 1, 0.06)

                                SequentialAnimation on opacity {
                                    running: card.isStatus && Suggest.loading
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: 0.4
                                        duration: 700
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: 1
                                        duration: 700
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }

                            // Title card: backdrop, darkened at the bottom for the name.
                            Item {
                                anchors.fill: parent
                                visible: card.isTitle

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                }

                                Image {
                                    id: thumb
                                    anchors.fill: parent
                                    source: card.isTitle ? (card.modelData?.card ?? "") : ""
                                    sourceSize.width: 480
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    visible: false
                                }

                                Rectangle {
                                    id: thumbMask
                                    anchors.fill: parent
                                    radius: 14
                                    visible: false
                                    layer.enabled: true
                                }

                                MultiEffect {
                                    anchors.fill: parent
                                    source: thumb
                                    maskEnabled: true
                                    maskSource: thumbMask
                                    opacity: thumb.status === Image.Ready ? 1 : 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 300
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.45
                                            color: Qt.rgba(0, 0, 0, 0)
                                        }
                                        GradientStop {
                                            position: 1
                                            color: Qt.rgba(0, 0, 0, 0.82)
                                        }
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 12
                                    text: card.isTitle ? (card.modelData?.title ?? "") : ""
                                    color: "#ffffff"
                                    font.family: Theme.fontUI
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                // Which service, top-left.
                                AppTile {
                                    x: 10
                                    y: 10
                                    width: 22
                                    height: 22
                                    app: (card.isTitle ? win.appNamed(card.modelData?.offer?.app ?? "") : null) ?? win.apps[0]
                                }
                            }

                            // Focus ring.
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -4
                                radius: 18
                                color: "transparent"
                                border.width: 3
                                border.color: "#ffffff"
                                opacity: card.isFocused ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 180
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: face
                            hoverEnabled: true
                            cursorShape: card.isStatus ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (card.isFocused) {
                                    win.activate(rowItem.focusedEntry);
                                } else {
                                    rowsView.currentIndex = rowItem.index;
                                    list.currentIndex = card.index;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Launch splash ───────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: win.bg
        opacity: win.launching && CadenceState.open ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        RectangularShadow {
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: width
            radius: width / 2
            blur: 260
            color: Qt.alpha(win.launching?.glow ?? "#7a5cff", 0.28)
        }

        Item {
            anchors.centerIn: parent
            width: 150
            height: 150

            RectangularShadow {
                anchors.fill: splashTile
                radius: splashTile.radius
                blur: 60
                offset.y: 18
                color: Qt.alpha(win.launching?.glow ?? "#7a5cff", 0.5)
            }

            AppTile {
                id: splashTile
                anchors.fill: parent
                app: win.launching ?? win.apps[0]
            }

            SequentialAnimation on scale {
                running: !!win.launching
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
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
