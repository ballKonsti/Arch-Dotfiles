import QtQuick
import QtQuick.Shapes

// The MacBook notch silhouette: flush with the top edge, rounded at the
// bottom, and — the detail that sells it — concave "shoulders" where the
// shape meets the screen edge.
//
// `bodyWidth` is the notch itself; the item is wider by 2 * shoulder so the
// concave corners have somewhere to live.
Item {
    id: root

    property real bodyWidth: 360
    property real bodyHeight: 34
    property real shoulder: 14
    property real bottomRadius: 18
    property color color: "#000000"

    implicitWidth: bodyWidth + shoulder * 2
    implicitHeight: bodyHeight

    // Left edge of the notch body, in item coordinates.
    readonly property real bodyX: shoulder

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        ShapePath {
            id: path
            fillColor: root.color
            strokeWidth: -1

            readonly property real s: root.shoulder
            readonly property real r: Math.min(root.bottomRadius, root.bodyHeight / 2, root.bodyWidth / 2)
            readonly property real w: root.bodyWidth
            readonly property real h: root.bodyHeight

            startX: 0
            startY: 0

            // concave shoulder, top-left
            PathArc {
                x: path.s
                y: path.s
                radiusX: path.s
                radiusY: path.s
                direction: PathArc.Clockwise
            }
            PathLine {
                x: path.s
                y: path.h - path.r
            }
            // bottom-left corner
            PathArc {
                x: path.s + path.r
                y: path.h
                radiusX: path.r
                radiusY: path.r
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: path.s + path.w - path.r
                y: path.h
            }
            // bottom-right corner
            PathArc {
                x: path.s + path.w
                y: path.h - path.r
                radiusX: path.r
                radiusY: path.r
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: path.s + path.w
                y: path.s
            }
            // concave shoulder, top-right
            PathArc {
                x: path.s + path.w + path.s
                y: 0
                radiusX: path.s
                radiusY: path.s
                direction: PathArc.Clockwise
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }
}
