import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// A small accent-coloured burst at every click, purely decorative — clicks
// still pass straight through to whatever is underneath.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData

        screen: win.modelData
        WlrLayershell.namespace: "quickshell:click-ripple"
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

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => {
                burst.createObject(win.contentItem, {
                    x: mouse.x - 10,
                    y: mouse.y - 10
                });
                mouse.accepted = false;
            }
        }

        Component {
            id: burst

            Rectangle {
                id: ripple
                width: 20
                height: 20
                radius: 10
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
                scale: 0.4
                opacity: 0.8

                ParallelAnimation {
                    running: true
                    NumberAnimation {
                        target: ripple
                        property: "scale"
                        to: 1.8
                        duration: Theme.durMed
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: ripple
                        property: "opacity"
                        to: 0
                        duration: Theme.durMed
                        easing.type: Easing.OutCubic
                    }
                    onFinished: ripple.destroy()
                }
            }
        }
    }
}
