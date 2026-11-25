import QtQuick
import qs.config

// One app's tile: brand-coloured rounded square with its glyph or
// wordmark. Sizes everything off its shorter side, so the same component
// works as a square logo and as a wide 16:9 card in the launcher's app row.
Rectangle {
    id: t
    required property var app
    property bool ring: false
    readonly property real side: Math.min(t.width, t.height)

    radius: t.side * (t.width > t.height * 1.2 ? 0.14 : 0.24)
    color: t.app.tile
    border.width: t.ring ? Math.max(3, t.side * 0.035) : 0
    border.color: "#ffffff"

    // A white ring would vanish on a white tile, so add an indigo one inside.
    Rectangle {
        anchors.fill: parent
        anchors.margins: t.border.width
        radius: t.radius - t.border.width
        color: "transparent"
        border.width: t.ring && Qt.color(t.app.tile).hslLightness > 0.85 ? 2 : 0
        border.color: "#261852"
    }

    // Faint top sheen.
    Rectangle {
        anchors.fill: parent
        radius: t.radius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(1, 1, 1, 0.14)
            }
            GradientStop {
                position: 0.55
                color: Qt.rgba(1, 1, 1, 0)
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: t.app.icon ? String.fromCodePoint(t.app.icon) : t.app.word
        color: t.app.fg
        font.family: t.app.icon ? Theme.fontIcon : Theme.fontUI
        font.pixelSize: t.app.icon ? t.side * 0.5 : t.side * (t.app.word.length > 3 ? 0.27 : 0.34)
        font.weight: Font.Black
        font.letterSpacing: t.app.icon ? 0 : -t.side * 0.01
    }
}
