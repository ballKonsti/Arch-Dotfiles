import QtQuick
import QtQuick.Shapes

// A wave crest hanging off the top edge of the screen: a steep leading face,
// a rounded trough, and a long tail that streams back the way it came.
//
// As `tail` shrinks to zero the tail curve collapses into the notch's own
// concave shoulder, and as `leadRadius` shrinks to zero the leading face
// becomes a flat vertical butt — so at the moment two of these meet nose to
// nose their union is exactly a notch, and the hand-off is seamless.
Item {
    id: root

    property real crest: 92          // width of the crest body
    property real depth: 34          // how far the wave hangs down
    property real tail: 240          // length of the trailing wake
    property real shoulder: 14       // horizontal room the tail curve takes
    property real bottomRadius: 18   // trough corner, outer side
    property real leadRadius: 18     // trough corner, leading side
    property bool flipped: false     // leading face on the left instead
    property color color: "#000000"

    implicitWidth: tail + shoulder + crest
    implicitHeight: depth

    transform: Scale {
        xScale: root.flipped ? -1 : 1
        origin.x: root.width / 2
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        ShapePath {
            id: p

            fillColor: root.color
            strokeWidth: -1

            readonly property real w: root.width
            readonly property real h: root.depth
            readonly property real rl: Math.max(0, Math.min(root.leadRadius, root.crest / 2, h / 2))
            readonly property real ro: Math.max(0, Math.min(root.bottomRadius, root.crest / 2, h / 2))
            readonly property real ox: root.tail + root.shoulder   // outer edge of the crest

            startX: p.w
            startY: 0

            // down the leading face
            PathLine {
                x: p.w
                y: p.h - p.rl
            }
            PathArc {
                x: p.w - p.rl
                y: p.h
                radiusX: p.rl
                radiusY: p.rl
                direction: PathArc.Clockwise
            }
            // along the trough
            PathLine {
                x: p.ox + p.ro
                y: p.h
            }
            PathArc {
                x: p.ox
                y: p.h - p.ro
                radiusX: p.ro
                radiusY: p.ro
                direction: PathArc.Clockwise
            }
            // the long sweep back out into the tail
            PathCubic {
                x: 0
                y: 0
                control1X: p.ox
                control1Y: (p.h - p.ro) * 0.26
                control2X: root.tail * 0.55
                control2Y: 0
            }
            // close along the top edge
            PathLine {
                x: p.w
                y: 0
            }
        }
    }
}
