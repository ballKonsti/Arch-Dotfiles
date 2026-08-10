import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config
import qs.services
import qs.widgets

Item {
    id: root

    property string monitorName: ""

    property bool pinned: false
    readonly property bool expanded: introDone && (pinned || hoverArea.hovered)

    // ── Entrance ────────────────────────────────────────────────
    //
    // Two waves run in from the left and right screen edges, collide on the
    // centre line and splash out into the notch. Replayed over IPC, so
    // Super+W can re-trigger it without restarting the shell.
    property real wavePos: 0                       // 0 = at the screen edges, 1 = touching
    property real waveHalf: Theme.wavePiece        // half-width of the merged blob
    property real waveH: Theme.notchHeight
    property bool introDone: false
    property bool shown: true
    property bool retreating: false                // true while waving back out

    readonly property bool collided: wavePos >= 1

    visible: root.shown

    function playIntro() {
        outroAnim.stop();
        root.introDone = false;
        root.pinned = false;
        root.osd = 0;
        root.shown = true;
        root.retreating = false;
        introAnim.restart();
    }

    // The entrance in reverse: the notch draws back into the blob, splits,
    // and the two halves shoot back off the sides of the screen.
    function playOutro() {
        if (!root.shown)
            return;
        introAnim.stop();
        root.pinned = false;
        root.osd = 0;
        // hand the current geometry over to the wave properties before
        // switching authority, so nothing jumps
        root.waveHalf = root.halfL;
        root.waveH = root.bodyH;
        root.introDone = false;
        // Turn the crests around before they're visible again, so they lead
        // with the steep face and drag their wake behind them on the way out.
        root.retreating = true;
        outroAnim.restart();
    }

    SequentialAnimation {
        id: introAnim
        running: true

        // the run in — accelerating, so the two waves are quickest at impact
        NumberAnimation {
            target: root
            property: "wavePos"
            from: 0
            to: 1
            duration: Theme.waveTravel
            easing.type: Easing.InQuad
        }

        // the splash — squashed horizontally on impact, so it bulges down
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "waveHalf"
                from: Theme.wavePiece
                to: Theme.notchWidth / 2
                duration: 520
                easing.type: Easing.OutBack
                easing.overshoot: 1.35
            }
            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "waveH"
                    from: Theme.notchHeight
                    to: Theme.notchHeight * 1.32
                    duration: 120
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: root
                    property: "waveH"
                    to: Theme.notchHeight
                    duration: 400
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.9
                }
            }
        }

        ScriptAction {
            script: root.introDone = true
        }
    }

    SequentialAnimation {
        id: outroAnim

        // draw back down into the blob
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "waveHalf"
                to: Theme.wavePiece
                duration: 300
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: root
                property: "waveH"
                to: Theme.notchHeight
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }

        // split, and accelerate off both sides
        NumberAnimation {
            target: root
            property: "wavePos"
            from: 1
            to: 0
            duration: Theme.waveTravel
            easing.type: Easing.InQuad
        }

        ScriptAction {
            script: root.shown = false
        }
    }

    IpcHandler {
        target: "notch"

        // Super+W — waves in if hidden, waves out if shown
        function toggle(): void {
            if (root.shown)
                root.playOutro();
            else
                root.playIntro();
        }

        function replay(): void {
            root.playIntro();
        }

        function hide(): void {
            root.playOutro();
        }

        function open(): void {
            root.pinned = true;
        }

        function close(): void {
            root.pinned = false;
        }
    }

    // OSD: 0 = none, 1 = volume, 2 = brightness
    property int osd: 0
    property bool armed: false

    property alias hitArea: hit

    implicitHeight: Theme.notchHeightOpen

    // ── Silhouette, measured out from a fixed centre line ───────
    //
    // Left and right are animated separately so the notch unfolds as a
    // sweep instead of a symmetric zoom: the right edge leads, the height
    // unfurls behind it, the left edge follows last.
    readonly property real centreX: width / 2

    readonly property real openHalf: expanded ? Theme.notchWidthOpen / 2 : Theme.notchWidth / 2

    property real halfR: introDone ? openHalf + (osd !== 0 ? Theme.osdStretch : 0) : waveHalf
    property real halfL: introDone ? openHalf : waveHalf
    property real bodyH: introDone ? (expanded ? Theme.notchHeightOpen : Theme.notchHeight) : waveH

    Behavior on halfR {
        enabled: root.introDone

        SequentialAnimation {
            PauseAnimation {
                duration: Theme.leadDelay
            }
            NumberAnimation {
                duration: Theme.durSlow
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.curve
            }
        }
    }
    Behavior on bodyH {
        enabled: root.introDone

        SequentialAnimation {
            PauseAnimation {
                duration: Theme.heightDelay
            }
            NumberAnimation {
                duration: Theme.durSlow
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.curve
            }
        }
    }
    Behavior on halfL {
        enabled: root.introDone

        SequentialAnimation {
            PauseAnimation {
                duration: Theme.trailDelay
            }
            NumberAnimation {
                duration: Theme.durSlow
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.curve
            }
        }
    }

    // ── Media ───────────────────────────────────────────────────
    readonly property var player: {
        const ps = Mpris.players.values;
        let fallback = null;
        for (const p of ps) {
            if (p.isPlaying)
                return p;
            if (fallback === null)
                fallback = p;
        }
        return fallback;
    }
    readonly property string trackTitle: root.player?.trackTitle ?? ""
    readonly property bool hasMedia: root.trackTitle !== ""
    readonly property bool playing: root.player?.isPlaying ?? false

    // ── OSD plumbing ────────────────────────────────────────────
    function flash(mode: int) {
        if (!root.armed || root.expanded)
            return;
        root.osd = mode;
        osdTimer.restart();
    }

    Timer {
        id: osdTimer
        interval: 1700
        onTriggered: root.osd = 0
    }
    Timer {
        interval: 1800
        running: true
        onTriggered: root.armed = true
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            root.flash(1);
        }
        function onMutedChanged() {
            root.flash(1);
        }
    }
    Connections {
        target: Backlight
        function onRawChanged() {
            root.flash(2);
        }
    }

    // ── The incoming waves ──────────────────────────────────────
    //
    // Two crests streaming in off the screen edges. The wake retracts and
    // the leading face flattens as they close, so by the time their noses
    // touch on the centre line their union is exactly the notch and the
    // real shape can take over unnoticed.
    readonly property real waveTail: Theme.waveTail * (1 - wavePos)
    readonly property real waveLead: Theme.bottomRadius * (1 - wavePos)
    readonly property real waveSwell: Theme.notchHeight * (1 + Theme.waveWobble * Math.sin(wavePos * Math.PI * Theme.waveRipples))

    // leading edges, running from just off each screen edge to the centre
    readonly property real leadL: -Theme.waveOvershoot + (centreX + Theme.waveOvershoot) * wavePos
    readonly property real leadR: (width + Theme.waveOvershoot) + (centreX - width - Theme.waveOvershoot) * wavePos

    WaveShape {
        id: waveL
        visible: !root.collided
        // nose towards the centre on the way in, towards the edge on the way out
        flipped: root.retreating
        y: 0
        x: root.leadL - width
        crest: root.waveHalf
        depth: root.waveSwell
        tail: root.waveTail
        leadRadius: root.waveLead
        shoulder: Theme.innerRadius
        bottomRadius: Theme.bottomRadius
        color: Theme.notchBg
    }

    WaveShape {
        id: waveR
        visible: !root.collided
        flipped: !root.retreating
        y: 0
        x: root.leadR
        crest: root.waveHalf
        depth: root.waveSwell
        tail: root.waveTail
        leadRadius: root.waveLead
        shoulder: Theme.innerRadius
        bottomRadius: Theme.bottomRadius
        color: Theme.notchBg
    }

    // ── The shape ───────────────────────────────────────────────
    NotchShape {
        id: shape
        visible: root.collided
        y: 0
        x: root.centreX - root.halfL - shoulder
        bodyWidth: root.halfL + root.halfR
        bodyHeight: root.bodyH
        shoulder: Theme.innerRadius
        bottomRadius: root.expanded ? 28 : Theme.bottomRadius
        color: Theme.notchBg

        Behavior on bottomRadius {
            NumberAnimation {
                duration: Theme.durSlow
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.curve
            }
        }
    }

    // Input region — exactly the painted silhouette, and nothing at all
    // once the notch has waved itself off screen.
    Item {
        id: hit
        x: shape.x
        y: shape.y
        width: root.shown ? shape.width : 0
        height: root.shown ? shape.height : 0
    }

    // Hover lives on the root so that the sliders and buttons inside the
    // panel can't steal it and collapse the notch mid-drag.
    HoverHandler {
        id: hoverArea
        blocking: false
    }

    MouseArea {
        anchors.fill: hit
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouseEvent => {
            if (mouseEvent.button === Qt.MiddleButton)
                Audio.toggleMute();
            else
                root.pinned = !root.pinned;
        }
        onWheel: wheel => Audio.nudge(wheel.angleDelta.y > 0 ? 0.03 : -0.03)
    }

    // Everything inside the notch is clipped to the silhouette's box, so
    // content can never be drawn where the background hasn't arrived yet.
    Item {
        id: bodyClip

        x: root.centreX - root.halfL
        y: 0
        width: root.halfL + root.halfR
        height: root.bodyH
        clip: true

        // ── Collapsed face ──────────────────────────────────────────
        Item {
            id: face

            x: 0
            width: bodyClip.width
            height: Theme.notchHeight
            opacity: root.expanded || !root.introDone ? 0 : 1
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: 130
                }
            }

            // ── left: workspaces + clock ────────────────────────────
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Workspaces {
                    anchors.verticalCenter: parent.verticalCenter
                    monitorName: root.monitorName
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Sys.time
                    color: Theme.text
                    font.family: Theme.fontUI
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }

            // ── the "camera" ────────────────────────────────────────
            Rectangle {
                x: root.halfL - width / 2      // stays on the true centre line
                anchors.verticalCenter: parent.verticalCenter
                width: 7
                height: 7
                radius: 3.5
                color: "#0c0c0d"
                border.width: 1
                border.color: "#1b1b1d"
                opacity: root.osd === 0 && !root.hasMedia ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durMed
                    }
                }
            }

            // ── right: OSD > media > status ─────────────────────────
            Item {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(osdRow.implicitWidth, mediaRow.implicitWidth, statusRow.implicitWidth)
                height: 16

                Row {
                    id: osdRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9
                    opacity: root.osd !== 0 ? 1 : 0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.osd === 2 ? Backlight.icon : Audio.icon
                        color: root.osd === 2 ? Theme.warm : Theme.accent2
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 86
                        height: 4
                        radius: 2
                        color: Theme.strokeSoft

                        Rectangle {
                            width: Math.max(4, parent.width * Math.min(1, root.osd === 2 ? Backlight.value : Audio.volume))
                            height: parent.height
                            radius: 2
                            color: root.osd === 2 ? Theme.warm : Theme.accent2

                            Behavior on width {
                                NumberAnimation {
                                    duration: Theme.durFast
                                }
                            }
                        }
                    }
                }

                Row {
                    id: mediaRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    opacity: root.osd === 0 && root.hasMedia ? 1 : 0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 150)
                        elide: Text.ElideRight
                        text: root.trackTitle
                        color: Theme.subtext
                        font.family: Theme.fontUI
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    // three bars that bounce while something is playing
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Repeater {
                            model: 3

                            delegate: Rectangle {
                                required property int index
                                width: 2.5
                                radius: 1.25
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                                height: 4

                                SequentialAnimation on height {
                                    running: root.playing && mediaRow.visible
                                    loops: Animation.Infinite

                                    PauseAnimation {
                                        duration: index * 130
                                    }
                                    NumberAnimation {
                                        to: 12
                                        duration: 380
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: 4
                                        duration: 380
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    id: statusRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    opacity: root.osd === 0 && !root.hasMedia ? 1 : 0
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Net.icon
                        color: Net.up ? Theme.subtext : Theme.crit
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Bat.icon
                        color: Bat.tint
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                        visible: Bat.available
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${Bat.percent}%`
                        color: Bat.tint
                        font.family: Theme.fontUI
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        visible: Bat.available
                    }
                }
            }
        }

        // ── Expanded panel ──────────────────────────────────────────
        Item {
            id: panel

            readonly property int pad: 20

            // Laid out for the final open size, then slid in from the leading
            // (right) edge so the content rides the wave.
            y: pad
            // Tracks halfL exactly — halfL is already animated, so animating
            // x on top of it would double-lag and drag the panel off to one
            // side of the box. The slide-in rides its own property instead.
            property real slide: root.expanded ? 0 : 34

            x: root.halfL - Theme.notchWidthOpen / 2 + pad + slide
            width: Theme.notchWidthOpen - pad * 2
            height: Theme.notchHeightOpen - pad * 2

            opacity: root.expanded ? 1 : 0
            visible: opacity > 0.01

            // Hold the fade until the box has actually grown, so the panel is
            // revealed by the background rather than racing ahead of it.
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation {
                        duration: root.expanded ? Theme.heightDelay + 110 : 0
                    }
                    NumberAnimation {
                        duration: Theme.durMed
                    }
                }
            }
            Behavior on slide {
                SequentialAnimation {
                    PauseAnimation {
                        duration: Theme.heightDelay
                    }
                    NumberAnimation {
                        duration: Theme.durSlow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.curve
                    }
                }
            }

            // MPRIS position is cached; nudge it while the panel is open.
            Timer {
                running: panel.visible && root.playing
                interval: 1000
                repeat: true
                onTriggered: {
                    if (root.player)
                        root.player.positionChanged();
                }
            }

            // ── row 1: clock + media (or the focused window) ────────
            Item {
                id: headerRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 56

                Column {
                    id: clockBlock
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: Sys.time
                        color: Theme.text
                        font.family: Theme.fontUI
                        font.pixelSize: 32
                        font.weight: Font.Light
                        font.letterSpacing: -1
                    }
                    Text {
                        text: Sys.dateLong
                        color: Theme.subtext
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }

                Item {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: clockBlock.right
                    anchors.leftMargin: 22
                    height: 52

                    // no media → show what's focused instead
                    ActiveWindow {
                        anchors.centerIn: parent
                        maxTextWidth: 220
                        visible: !root.hasMedia
                    }

                    Row {
                        anchors.fill: parent
                        spacing: 12
                        visible: root.hasMedia

                        Item {
                            id: art
                            width: 50
                            height: 50
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: 11
                                color: Theme.surfaceHi
                            }

                            Image {
                                id: artSource
                                anchors.fill: parent
                                source: root.player?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 100
                                sourceSize.height: 100
                                smooth: true
                                visible: false
                            }

                            Rectangle {
                                id: artMask
                                anchors.fill: parent
                                radius: 11
                                color: "white"
                                visible: false
                                layer.enabled: true
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: artSource
                                maskEnabled: true
                                maskSource: artMask
                                visible: artSource.status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰎈"
                                color: Theme.faint
                                font.family: Theme.fontIcon
                                font.pixelSize: 20
                                visible: artSource.status !== Image.Ready
                            }
                        }

                        Column {
                            width: parent.width - 50 - 12 - controls.width - 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: root.trackTitle
                                color: Theme.text
                                font.family: Theme.fontUI
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: root.player?.trackArtist ?? ""
                                color: Theme.subtext
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                            }
                            Rectangle {
                                width: parent.width
                                height: 3
                                radius: 1.5
                                color: Theme.strokeSoft
                                visible: (root.player?.length ?? 0) > 0

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1)))
                                    height: parent.height
                                    radius: 1.5
                                    color: Theme.accent
                                }
                            }
                        }

                        Row {
                            id: controls
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Repeater {
                                model: [
                                    {
                                        glyph: "󰒮",
                                        action: "prev"
                                    },
                                    {
                                        glyph: root.playing ? "󰏤" : "󰐊",
                                        action: "toggle"
                                    },
                                    {
                                        glyph: "󰒭",
                                        action: "next"
                                    },
                                ]

                                delegate: Rectangle {
                                    id: btn
                                    required property var modelData

                                    width: modelData.action === "toggle" ? 30 : 26
                                    height: width
                                    radius: width / 2
                                    color: btnMouse.containsMouse ? Theme.surfaceHi : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.durFast
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: btn.modelData.glyph
                                        color: btn.modelData.action === "toggle" ? Theme.accent : Theme.subtext
                                        font.family: Theme.fontIcon
                                        font.pixelSize: btn.modelData.action === "toggle" ? 15 : 13
                                    }

                                    MouseArea {
                                        id: btnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const p = root.player;
                                            if (!p)
                                                return;
                                            if (btn.modelData.action === "prev")
                                                p.previous();
                                            else if (btn.modelData.action === "next")
                                                p.next();
                                            else
                                                p.togglePlaying();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: divider
                anchors.top: headerRow.bottom
                anchors.topMargin: 13
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.strokeSoft
            }

            // ── rows 2/3: sliders ───────────────────────────────────
            Column {
                id: sliders
                anchors.top: divider.bottom
                anchors.topMargin: 13
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: Audio.icon
                        color: Theme.accent2
                        font.family: Theme.fontIcon
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Audio.toggleMute()
                        }
                    }

                    SliderBar {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 18 - 12 - 12 - 38
                        value: Audio.volume
                        fill: Audio.muted ? Theme.faint : Theme.accent2
                        onMoved: v => Audio.set(v)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 38
                        text: `${Audio.percent}%`
                        color: Theme.subtext
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Row {
                    width: parent.width
                    spacing: 12
                    visible: Backlight.available

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: Backlight.icon
                        color: Theme.warm
                        font.family: Theme.fontIcon
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                    }

                    SliderBar {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 18 - 12 - 12 - 38
                        value: Backlight.value
                        fill: Theme.warm
                        onMoved: v => Backlight.set(v)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 38
                        text: `${Backlight.percent}%`
                        color: Theme.subtext
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // ── row 4: chips on the left, tray on the right ─────────
            Row {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                spacing: 16

                Row {
                    spacing: 7

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Net.icon
                        color: Net.up ? Theme.accent2 : Theme.crit
                        font.family: Theme.fontIcon
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 120)
                        elide: Text.ElideRight
                        text: Net.up ? (Net.name !== "" ? Net.name : Net.kind) : "offline"
                        color: Theme.subtext
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                    }
                }

                Row {
                    spacing: 7
                    visible: Bat.available

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Bat.icon
                        color: Bat.tint
                        font.family: Theme.fontIcon
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${Bat.percent}% · ${Bat.eta}`
                        color: Theme.subtext
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                    }
                }

                Row {
                    spacing: 7

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅐"
                        color: Theme.faint
                        font.family: Theme.fontIcon
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `up ${Sys.uptime}`
                        color: Theme.subtext
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                    }
                }
            }

            Tray {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
            }
        }
    }
}
