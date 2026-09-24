import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// A three-block accent-coloured wipe that plays across every screen whenever
// ThemeState switches wallpaper/theme, layered on top of the awww crossfade
// for an extra snap of motion. Colours always match whatever palette is
// currently active, not a fixed skin.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData

        screen: win.modelData
        visible: false
        WlrLayershell.namespace: "quickshell:theme-wipe"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        color: "transparent"

        Connections {
            target: ThemeState
            function onWipeRequested() {
                win.visible = true;
                startDelay.start();
            }
        }

        Timer {
            id: startDelay
            interval: 80
            repeat: false
            onTriggered: blockRepeater.restartAll()
        }

        Repeater {
            id: blockRepeater
            model: [
                { colorKey: "accent", delay: 0 },
                { colorKey: "accent2", delay: 90 },
                { colorKey: "surfaceHi", delay: 180 }
            ]

            function restartAll() {
                for (var i = 0; i < count; i++)
                    itemAt(i).startAnim();
            }

            Item {
                id: blockItem
                required property var modelData
                required property int index
                anchors.fill: parent
                z: 999 - index

                function startAnim() {
                    blockAnim.restart();
                }

                Rectangle {
                    id: block
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: parent.width
                    color: Theme[blockItem.modelData.colorKey]
                    transformOrigin: Item.Left
                    transform: Scale {
                        id: blockScale
                        xScale: 0
                    }
                }

                SequentialAnimation {
                    id: blockAnim
                    running: false
                    PauseAnimation {
                        duration: blockItem.modelData.delay
                    }
                    NumberAnimation {
                        target: blockScale
                        property: "xScale"
                        from: 0
                        to: 1
                        duration: 350
                        easing.type: Easing.InOutQuart
                    }
                    PauseAnimation {
                        duration: 120
                    }
                    NumberAnimation {
                        target: blockScale
                        property: "xScale"
                        from: 1
                        to: 0
                        duration: 350
                        easing.type: Easing.InOutQuart
                    }
                    ScriptAction {
                        script: {
                            if (blockItem.index === 2)
                                win.visible = false;
                        }
                    }
                }
            }
        }
    }
}
