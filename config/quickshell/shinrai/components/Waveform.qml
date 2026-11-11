import QtQuick
import qs.config
import qs.services

// A few rounded bars that dance with the music (fed by cava) and sink to
// dots when it pauses.
Item {
    id: root

    property int bars: 5
    property real barWidth: 3
    property real gap: 2.5
    property color color: Theme.ink
    property bool live: Player.playing

    implicitWidth: bars * barWidth + (bars - 1) * gap
    implicitHeight: 14

    Repeater {
        model: root.bars

        Rectangle {
            required property int index

            readonly property real level: root.live ? Cava.level(index, root.bars) : 0

            x: index * (root.barWidth + root.gap)
            y: (root.height - height) / 2
            width: root.barWidth
            height: Math.max(root.barWidth, level * root.height)
            radius: width / 2
            color: root.color

            Behavior on height {
                NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
            }
            Behavior on color {
                ColorAnimation { duration: 600 }
            }
        }
    }
}
