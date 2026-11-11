import QtQuick
import QtQuick.Effects
import qs.config

// How content enters and leaves the island. Leaving is quick: a fade with a
// slight shrink (and blur, where effects are on). Arriving waits a beat, so
// the island's shape moves first and the new content settles into it.
Item {
    id: root

    property bool shown: false
    property int delay: 60
    property int inTime: 300
    property int outTime: 120
    property real minScale: 0.94
    property real p: 0   // 0 hidden → 1 shown

    opacity: p
    scale: minScale + (1 - minScale) * p
    visible: p > 0.002
    enabled: shown

    layer.enabled: Theme.effects && visible && p < 0.995
    layer.smooth: true
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 20
        blur: (1 - root.p) * 0.6
    }

    Component.onCompleted: p = shown ? 1 : 0

    onShownChanged: {
        if (shown) {
            leaving.stop();
            arriving.restart();
        } else {
            arriving.stop();
            leaving.restart();
        }
    }

    SequentialAnimation {
        id: arriving
        PauseAnimation { duration: root.p > 0.1 ? 0 : root.delay }
        NumberAnimation {
            target: root
            property: "p"
            to: 1
            duration: root.inTime
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation {
        id: leaving
        target: root
        property: "p"
        to: 0
        duration: root.outTime
        easing.type: Easing.OutQuad
    }
}
