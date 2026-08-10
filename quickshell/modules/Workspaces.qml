import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

Item {
    id: root

    property string monitorName: ""
    property int minWorkspaces: 5

    implicitWidth: row.implicitWidth
    implicitHeight: 18

    readonly property int activeId: Hyprland.focusedWorkspace?.id ?? -1

    readonly property var model: {
        const occupied = new Set();
        const ids = new Set();
        for (let i = 1; i <= root.minWorkspaces; i++)
            ids.add(i);

        for (const ws of Hyprland.workspaces.values) {
            if (ws.id < 1)
                continue;
            if (root.monitorName !== "" && ws.monitor && ws.monitor.name !== root.monitorName)
                continue;
            ids.add(ws.id);
            occupied.add(ws.id);
        }

        return Array.from(ids).sort((a, b) => a - b).map(id => ({
                    id: id,
                    occupied: occupied.has(id)
                }));
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => Hyprland.dispatch(wheel.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.model

            delegate: Item {
                id: dot
                required property var modelData

                readonly property bool isActive: dot.modelData.id === root.activeId

                width: dot.isActive ? 22 : 8
                height: 8

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.durMed
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Theme.curve
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: dot.isActive ? Theme.accent : (dot.modelData.occupied ? Theme.subtext : Theme.faint)
                    opacity: dot.isActive ? 1 : (dot.modelData.occupied ? 0.85 : 0.45)

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.durFast
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durFast
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`workspace ${dot.modelData.id}`)
                }
            }
        }
    }
}
