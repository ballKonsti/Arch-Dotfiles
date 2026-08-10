import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

Row {
    id: root

    property int maxTextWidth: 240

    readonly property Toplevel active: ToplevelManager.activeToplevel
    readonly property string appId: root.active?.appId ?? ""
    readonly property string windowTitle: root.active?.title ?? ""

    readonly property DesktopEntry entry: root.appId !== "" ? DesktopEntries.heuristicLookup(root.appId) : null

    spacing: 7
    opacity: root.windowTitle === "" ? 0 : 1
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durMed
        }
    }

    Image {
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        sourceSize.width: 28
        sourceSize.height: 28
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: status === Image.Ready
        source: root.entry?.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, root.maxTextWidth)
        elide: Text.ElideRight
        text: root.windowTitle
        color: Theme.subtext
        font.family: Theme.fontUI
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
