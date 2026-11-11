import Quickshell
import QtQuick
import qs.config
import qs.components

// Resting state: the time. Click it for the power view.
Reveal {
    id: root

    implicitWidth: Math.max(108, time.implicitWidth + 48)
    implicitHeight: Theme.pill
    width: implicitWidth
    height: implicitHeight
    anchors.centerIn: parent

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Label {
        id: time
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, Config.clockFormat)
        tabular: true
        font.pixelSize: 14
        font.weight: Font.DemiBold
        font.letterSpacing: 0.3
    }
}
