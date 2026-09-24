import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config

// The picker. Arrow keys walk the grid and recolour the shell as you go;
// the wallpaper follows a moment later so holding a key doesn't thrash the
// daemon. Enter keeps the selection, Escape puts back what you started with.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData

        screen: win.modelData
        visible: ThemeState.popupOpen

        WlrLayershell.namespace: "quickshell:themeswitcher"
        WlrLayershell.layer: WlrLayer.Overlay
        // Exclusive so the grid can be driven from the keyboard the moment it
        // appears, without a click to hand focus over first.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        // What we snap back to on Escape.
        property int entryIndex: 0
        property bool entryLight: false

        onVisibleChanged: {
            if (!win.visible)
                return;
            console.log("DBG popup opened, ThemeState.index =", ThemeState.index, "count", ThemeState.count);
            win.entryIndex = ThemeState.index;
            win.entryLight = ThemeState.light;
            grid.currentIndex = ThemeState.index;
            grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
            grid.forceActiveFocus();
        }

        function commit() {
            ThemeState.popupOpen = false;
        }

        function cancel() {
            if (ThemeState.index !== win.entryIndex)
                ThemeState.select(win.entryIndex);
            if (ThemeState.light !== win.entryLight)
                ThemeState.setLight(win.entryLight);
            ThemeState.popupOpen = false;
        }

        // Click anywhere outside the card to dismiss.
        MouseArea {
            anchors.fill: parent
            onClicked: win.commit()
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: card.shown ? 0.42 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            id: card

            readonly property bool shown: ThemeState.popupOpen
            readonly property int cols: Math.min(5, Math.max(1, ThemeState.count))
            readonly property int cellW: 176
            readonly property int cellH: 122

            anchors.centerIn: parent
            width: card.cols * card.cellW + 40
            height: grid.height + header.height + footer.height + 56
            radius: 22
            color: Theme.surface
            border.width: 1
            border.color: Theme.stroke

            opacity: card.shown ? 1 : 0
            scale: card.shown ? 1 : 0.94

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.bezierCurve: Theme.curve
                    easing.type: Easing.Bezier
                }
            }

            // Swallow clicks so the dismiss-on-outside area doesn't catch them.
            MouseArea {
                anchors.fill: parent
            }

            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 18
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Theme"
                    color: Theme.text
                    font.family: Theme.fontUI
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }

                Text {
                    anchors.right: modePill.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: ThemeState.count > 0 ? ThemeState.themes[grid.currentIndex]?.name ?? "" : "no wallpapers found"
                    color: Theme.subtext
                    font.family: Theme.fontUI
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                // Dark/light toggle. Highlighted when the wallpaper is bright
                // enough that light mode is probably what you want.
                Rectangle {
                    id: modePill
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: modeRow.width + 20
                    height: 24
                    radius: 12
                    color: modeArea.containsMouse ? Theme.surfaceHi : Qt.rgba(0, 0, 0, 0)
                    border.width: 1
                    border.color: ThemeState.suggestsLight !== ThemeState.light ? Theme.accent : Theme.strokeSoft

                    Row {
                        id: modeRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ThemeState.light ? "󰖨" : "󰖔"
                            color: Theme.accent
                            font.family: Theme.fontIcon
                            font.pixelSize: 12
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ThemeState.light ? "Light" : "Dark"
                            color: Theme.subtext
                            font.family: Theme.fontUI
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: modeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: ThemeState.toggleMode()
                    }
                }
            }

            GridView {
                id: grid

                anchors.top: header.bottom
                anchors.topMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                width: card.cols * card.cellW
                height: Math.min(3, Math.ceil(ThemeState.count / card.cols)) * card.cellH
                clip: true

                cellWidth: card.cellW
                cellHeight: card.cellH
                model: ThemeState.themes
                focus: true

                // Selection is moved by the keyboard or by a click, never by
                // hover. Building and laying out the delegates emits a burst
                // of hover events at a perfectly stationary cursor, so
                // hover-to-select made merely opening the picker change your
                // theme. Hover still lights a cell up — it just doesn't
                // choose for you.
                keyNavigationEnabled: true
                keyNavigationWraps: true
                highlightMoveDuration: Theme.durFast

                // Walking the grid previews the theme for real: colours land
                // immediately, the wallpaper after ThemeState's debounce.
                onCurrentIndexChanged: {
                    console.log("DBG currentIndexChanged ->", currentIndex, "visible", win.visible); console.trace();
                    if (win.visible && currentIndex >= 0 && currentIndex !== ThemeState.index)
                        ThemeState.select(currentIndex);
                }

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Escape:
                        win.cancel();
                        event.accepted = true;
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space:
                        win.commit();
                        event.accepted = true;
                        break;
                    case Qt.Key_Tab:
                    case Qt.Key_D:
                        ThemeState.toggleMode();
                        event.accepted = true;
                        break;
                    }
                }

                delegate: Item {
                    id: cell
                    required property int index
                    required property var modelData

                    width: card.cellW
                    height: card.cellH

                    readonly property bool selected: grid.currentIndex === cell.index

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 12
                        color: cell.selected || cellArea.containsMouse ? Theme.surfaceHi : Qt.rgba(0, 0, 0, 0)
                        border.width: 1
                        border.color: cell.selected ? Theme.accent : Theme.strokeSoft

                        scale: cell.selected ? 1 : 0.97

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.durFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        Item {
                            id: thumbBox
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 7
                            height: 76

                            Image {
                                id: thumb
                                anchors.fill: parent
                                source: "file://" + cell.modelData.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                // Decode small — these are multi-megabyte photos.
                                sourceSize.width: 340
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: thumb
                                maskEnabled: true
                                maskSource: thumbMask
                                opacity: thumb.status === Image.Ready ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.durFast
                                    }
                                }
                            }

                            Rectangle {
                                id: thumbMask
                                anchors.fill: parent
                                radius: 8
                                visible: false
                                layer.enabled: true
                            }
                        }

                        Row {
                            anchors.top: thumbBox.bottom
                            anchors.topMargin: 7
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.right: parent.right
                            anchors.rightMargin: 9
                            spacing: 6

                            // The colour this wallpaper drives the shell with.
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 4
                                color: cell.modelData.seed
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 14
                                text: cell.modelData.name
                                color: cell.selected ? Theme.text : Theme.subtext
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: cellArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                grid.currentIndex = cell.index;
                                ThemeState.select(cell.index);
                                win.commit();
                            }
                        }
                    }
                }
            }

            Item {
                id: footer
                anchors.top: grid.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 18
                anchors.topMargin: 12
                height: 16

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "←→↑↓ browse   ⏎ keep   tab dark/light   esc revert"
                    color: Theme.faint
                    font.family: Theme.fontUI
                    font.pixelSize: 11
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: ThemeState.count > 0 ? `${grid.currentIndex + 1}/${ThemeState.count}` : ""
                    color: Theme.faint
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }
        }
    }
}
