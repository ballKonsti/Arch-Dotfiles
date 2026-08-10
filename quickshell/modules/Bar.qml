import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData

        screen: win.modelData
        WlrLayershell.namespace: "quickshell:notch"
        // Overlay so the notch sits above every window, fullscreen included.
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            left: true
            right: true
        }

        // Tall enough for the notch to unfold into, and for the two waves to
        // run across. Nothing is reserved — windows use the full screen and
        // the notch floats on top of them.
        implicitHeight: Theme.notchHeightOpen + 8
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        // Only the notch itself takes input; the rest is click-through.
        mask: Region {
            item: notch.hitArea
        }

        Notch {
            id: notch
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            monitorName: win.modelData.name
        }
    }
}
