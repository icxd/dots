import QtQuick
import qs.config
import qs.services
import qs.components

// Shown for a moment when the volume changes. Drag the bar, scroll the
// island, or click it to mute.
Reveal {
    id: root

    implicitWidth: 244
    implicitHeight: Theme.pill
    width: implicitWidth
    height: implicitHeight
    anchors.centerIn: parent

    Glyph {
        id: icon
        x: 14
        width: 18
        anchors.verticalCenter: parent.verticalCenter
        icon: Icons.volume(Audio.volume, Audio.muted)
        size: 15
    }

    Slider {
        x: 42
        width: parent.width - x - 60
        anchors.verticalCenter: parent.verticalCenter
        value: Audio.muted ? 0 : Audio.volume
        eased: true
        onMoved: v => Audio.set(v)
    }

    Label {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        horizontalAlignment: Text.AlignRight
        text: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
        tabular: true
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
