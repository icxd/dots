import QtQuick
import qs.config

// A thin rounded track with a black fill: the song's progress, the volume.
// Click or drag to set it; it thickens a little under the mouse.
Item {
    id: root

    property real value: 0             // 0..1
    property bool interactive: true
    property bool eased: false         // ease toward new values (for steps like volume ±5%)
    property real thickness: 4

    readonly property bool dragging: area.pressed
    readonly property bool hovered: area.containsMouse
    property real dragValue: 0

    signal moved(real value)      // while dragging
    signal released(real value)   // let go

    readonly property real target: dragging ? dragValue : Math.max(0, Math.min(1, value))
    property real shown: target

    Behavior on shown {
        enabled: root.eased && !root.dragging
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    implicitHeight: 16

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.thickness + (root.interactive && (area.containsMouse || area.pressed) ? 2 : 0)
        radius: height / 2
        color: Theme.fillStrong

        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Rectangle {
            width: Math.max(0, Math.min(track.width, track.width * root.shown))
            height: track.height
            radius: track.radius
            color: Theme.ink
            visible: root.shown > 0.001
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        enabled: root.interactive
        hoverEnabled: true
        preventStealing: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

        function at(x) { return Math.max(0, Math.min(1, x / width)); }

        onPressed: mouse => {
            root.dragValue = at(mouse.x);
            root.moved(root.dragValue);
        }
        onPositionChanged: mouse => {
            if (!pressed) return;
            root.dragValue = at(mouse.x);
            root.moved(root.dragValue);
        }
        onReleased: root.released(root.dragValue)
    }
}
