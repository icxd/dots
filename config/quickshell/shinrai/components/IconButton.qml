import QtQuick
import qs.config

// A glyph you can click. A soft circle swells in behind it on hover, and it
// dips a little when pressed. `active` puts a small dot under it (shuffle on).
Item {
    id: root

    property string icon: ""
    property real size: 18
    property real pad: 9
    property color color: Theme.ink
    property bool dim: false
    property bool active: false

    signal clicked()

    implicitWidth: size + pad * 2
    implicitHeight: size + pad * 2

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: width
        radius: width / 2
        color: area.pressed ? Theme.fillStrong : Theme.fill
        opacity: area.containsMouse && !root.dim ? 1 : 0
        scale: area.containsMouse ? 1 : 0.6

        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    Glyph {
        anchors.centerIn: parent
        icon: root.icon
        size: root.size
        color: root.color
        opacity: root.dim ? 0.3 : 1
        scale: area.pressed && !root.dim ? 0.86 : 1

        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + root.size / 2 + 2
        width: 4
        height: 4
        radius: 2
        color: root.color
        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.2

        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.dim
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
