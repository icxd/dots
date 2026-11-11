import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components

// The power view (click the clock, or Super + Shift + E): the time, the song
// (when there is one, also while paused), the volume and the session buttons. Log out, restart and shut down ask once
// more: press the same button (or key) again within 3 seconds.
//
//   l lock · s sleep · e log out · r restart · p shut down
//   ← → / Tab to pick, Enter to press · ↑ ↓ volume · m play/pause · Esc close
Reveal {
    id: root

    readonly property var actions: [
        { id: "lock",     name: "Lock",      glyph: Icons.lock,    key: Qt.Key_L, confirm: false },
        { id: "suspend",  name: "Sleep",     glyph: Icons.sleep,   key: Qt.Key_S, confirm: false },
        { id: "logout",   name: "Log out",   glyph: Icons.logout,  key: Qt.Key_E, confirm: true },
        { id: "reboot",   name: "Restart",   glyph: Icons.restart, key: Qt.Key_R, confirm: true },
        { id: "poweroff", name: "Shut down", glyph: Icons.power,   key: Qt.Key_P, confirm: true }
    ]
    property int selected: -1
    property int armed: -1
    // a row for the song, while there is one (playing or paused)
    readonly property int extra: Player.hasTrack ? 62 : 0

    implicitWidth: 420
    implicitHeight: 238 + extra
    width: implicitWidth
    height: implicitHeight
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    function press(i) {
        const a = actions[i];
        if (!a) return;
        selected = i;
        if (a.confirm && armed !== i) {
            armed = i;
            disarm.restart();
            return;
        }
        armed = -1;
        Hub.close();
        Session.run(a.id);
    }

    onSelectedChanged: if (selected !== armed) armed = -1

    onShownChanged: {
        if (!shown) return;
        selected = -1;
        armed = -1;
        Session.refresh();
        Qt.callLater(() => keys.forceActiveFocus());
    }

    Connections {
        target: Hub
        function onOpenedChanged() {
            if (root.shown) Qt.callLater(() => keys.forceActiveFocus());
        }
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = -1
    }

    Item {
        id: keys
        focus: true

        Keys.onPressed: event => {
            const i = root.actions.findIndex(a => a.key === event.key);
            if (event.key === Qt.Key_Escape) Hub.close();
            else if (i >= 0) root.press(i);
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab)
                root.selected = root.selected <= 0 ? 0 : root.selected - 1;
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab)
                root.selected = Math.min(root.actions.length - 1, root.selected + 1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                if (root.selected >= 0) root.press(root.selected);
            }
            else if (event.key === Qt.Key_M) Player.toggle();
            else if (event.key === Qt.Key_Up) Audio.nudge(0.05);
            else if (event.key === Qt.Key_Down) Audio.nudge(-0.05);
            else return;
            event.accepted = true;
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- time and date ----
    Label {
        id: time
        x: 26
        y: 16
        text: Qt.formatDateTime(clock.date, Config.clockFormat)
        tabular: true
        font.pixelSize: 46
        font.weight: Font.Light
        font.letterSpacing: -0.5
    }

    Label {
        x: 28
        y: time.y + time.height - 4
        text: Qt.formatDateTime(clock.date, "dddd d MMMM")
        color: Theme.inkSoft
        font.pixelSize: 13
        font.weight: Font.Medium
    }

    Column {
        anchors.right: parent.right
        anchors.rightMargin: 26
        y: 30
        spacing: 3

        Label {
            anchors.right: parent.right
            text: Quickshell.env("USER") ?? ""
            color: Theme.inkSoft
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Label {
            anchors.right: parent.right
            text: Session.uptime
            color: Theme.inkFaint
            font.pixelSize: 12
        }
    }

    // ---- now playing ----
    Item {
        x: 20
        y: 104
        width: parent.width - 40
        height: 48
        visible: Player.hasTrack

        Cover {
            id: smallCover
            y: 4
            width: 40
            height: 40
            radius: 9
            source: Player.art

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Hub.close();
                    Player.raise();
                }
            }
        }

        Column {
            x: smallCover.width + 12
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - mediaButtons.width - 8
            spacing: 2

            Label {
                width: parent.width
                text: Player.title
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Label {
                width: parent.width
                text: Player.artist
                color: Theme.inkSoft
                font.pixelSize: 12
            }
        }

        Row {
            id: mediaButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.prev
                size: 17
                pad: 7
                dim: !Player.canPrev
                onClicked: Player.prev()
            }

            Item {
                width: 36
                height: 36
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.ink
                    scale: miniPlay.pressed ? 0.9 : miniPlay.containsMouse ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                PlayPause {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    playing: Player.playing
                    color: Theme.island
                }

                MouseArea {
                    id: miniPlay
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Player.toggle()
                }
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.next
                size: 17
                pad: 7
                dim: !Player.canNext
                onClicked: Player.next()
            }
        }
    }

    // ---- volume ----
    Item {
        x: 20
        y: 106 + root.extra
        width: parent.width - 40
        height: 30

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => Audio.nudge(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
        }

        IconButton {
            id: speaker
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.volume(Audio.volume, Audio.muted)
            size: 16
            pad: 6
            onClicked: Audio.toggleMute()
        }

        Slider {
            x: speaker.width + 8
            width: parent.width - x - 52
            anchors.verticalCenter: parent.verticalCenter
            value: Audio.muted ? 0 : Audio.volume
            eased: true
            onMoved: v => Audio.set(v)
        }

        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            horizontalAlignment: Text.AlignRight
            text: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
            tabular: true
            color: Theme.inkSoft
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    // ---- session ----
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 152 + root.extra
        spacing: 20

        Repeater {
            model: root.actions

            Item {
                id: button

                required property var modelData
                required property int index
                readonly property bool armed: root.armed === index
                readonly property bool lit: armed || root.selected === index || area.containsMouse

                width: 58
                height: 72

                Rectangle {
                    id: disc
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 48
                    height: 48
                    radius: 24
                    color: button.armed ? Theme.ink : button.lit ? Theme.fillStrong : Theme.fill
                    scale: area.pressed ? 0.92 : button.armed ? 1.06 : 1

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

                    Glyph {
                        anchors.centerIn: parent
                        icon: button.modelData.glyph
                        size: 19
                        color: button.armed ? Theme.island : Theme.ink
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 55
                    text: button.armed ? "Confirm" : button.modelData.name
                    color: button.armed || button.lit ? Theme.ink : Theme.inkSoft
                    font.pixelSize: 11
                    font.weight: button.armed ? Font.DemiBold : Font.Medium
                    elide: Text.ElideNone
                }

                MouseArea {
                    id: area
                    anchors.fill: disc
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.press(button.index)
                }
            }
        }
    }
}
