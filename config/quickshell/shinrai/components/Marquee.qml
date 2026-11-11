import QtQuick
import qs.config

// One line of text. If it doesn't fit, it glides left in an endless loop with
// soft edges, resting at the start of each round.
Item {
    id: root

    property alias text: first.text
    property int size: 13
    property int weight: Font.Normal
    property color color: Theme.ink
    property color edgeColor: Theme.island   // the background, for the soft edges
    property real speed: 26                  // px per second
    property int rest: 2400                  // ms to rest at the start of a round
    property int spacing: 36

    readonly property bool overflowing: first.implicitWidth > width + 0.5
    readonly property real round: first.implicitWidth + spacing

    implicitHeight: first.implicitHeight
    clip: true

    Item {
        id: strip
        width: root.round * 2
        height: root.height

        Label {
            id: first
            anchors.verticalCenter: parent.verticalCenter
            color: root.color
            font.pixelSize: root.size
            font.weight: root.weight
            elide: Text.ElideNone
        }

        Label {
            x: root.round
            anchors.verticalCenter: parent.verticalCenter
            visible: root.overflowing
            text: first.text
            color: root.color
            font.pixelSize: root.size
            font.weight: root.weight
            elide: Text.ElideNone
        }
    }

    SequentialAnimation {
        id: glide
        running: root.overflowing && root.visible
        loops: Animation.Infinite

        PropertyAction { target: strip; property: "x"; value: 0 }
        PauseAnimation { duration: root.rest }
        NumberAnimation {
            target: strip
            property: "x"
            from: 0
            to: -root.round
            duration: root.round / root.speed * 1000
            easing.type: Easing.InOutSine
        }
    }

    onTextChanged: {
        strip.x = 0;
        if (glide.running) glide.restart();
    }
    onOverflowingChanged: if (!overflowing) strip.x = 0

    // soft edges while it moves
    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 14
        visible: root.overflowing
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(root.edgeColor.r, root.edgeColor.g, root.edgeColor.b, 0) }
            GradientStop { position: 1; color: root.edgeColor }
        }
    }

    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        width: 14
        opacity: strip.x < -1 ? 1 : 0
        visible: root.overflowing
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.edgeColor }
            GradientStop { position: 1; color: Qt.rgba(root.edgeColor.r, root.edgeColor.g, root.edgeColor.b, 0) }
        }

        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
