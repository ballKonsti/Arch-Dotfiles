import QtQuick
import qs.config

// Minimal drag/scroll slider. Grows a little under the cursor.
Item {
    id: root

    property real value: 0            // 0..1
    property color fill: Theme.accent
    property real step: 0.05
    signal moved(real value)

    implicitHeight: 18

    readonly property bool active: hover.containsMouse || hover.pressed
    readonly property real thickness: active ? 10 : 6

    function commit(mx) {
        const v = Math.max(0, Math.min(1, mx / Math.max(1, track.width)));
        root.value = v;
        root.moved(v);
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness
        radius: height / 2
        color: Theme.strokeSoft

        Behavior on height {
            NumberAnimation {
                duration: Theme.durFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: height / 2
            color: root.fill

            Behavior on width {
                enabled: !root.active
                NumberAnimation {
                    duration: Theme.durFast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        preventStealing: true

        onPressed: mouse => root.commit(mouse.x + 4)
        onPositionChanged: mouse => {
            if (pressed)
                root.commit(mouse.x + 4);
        }
        onWheel: wheel => {
            const d = wheel.angleDelta.y > 0 ? root.step : -root.step;
            root.value = Math.max(0, Math.min(1, root.value + d));
            root.moved(root.value);
        }
    }
}
