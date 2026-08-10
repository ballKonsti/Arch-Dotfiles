import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.config

Row {
    id: root

    spacing: 10
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: entry
            required property SystemTrayItem modelData

            width: 15
            height: 15
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: img
                anchors.fill: parent
                sourceSize.width: 30
                sourceSize.height: 30
                fillMode: Image.PreserveAspectFit
                smooth: true
                source: entry.modelData.icon
                opacity: entry.modelData.status === SystemTrayItem.Passive ? 0.55 : 1
                scale: mouse.containsMouse ? 1.18 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durFast
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.durFast
                    }
                }
            }

            QsMenuAnchor {
                id: menu
                menu: entry.modelData.menu
                anchor.item: entry
                anchor.rect.y: entry.height + 8
                anchor.rect.height: 1
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                anchors.margins: -5
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouseEvent => {
                    if (mouseEvent.button === Qt.RightButton || entry.modelData.onlyMenu) {
                        if (entry.modelData.hasMenu)
                            menu.open();
                    } else {
                        entry.modelData.activate();
                    }
                }
            }
        }
    }
}
