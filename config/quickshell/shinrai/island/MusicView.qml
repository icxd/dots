import QtQuick
import qs.config
import qs.services
import qs.components

// Now playing.
//   small   the cover, the song's name and a little waveform
//   open    the player: big cover, title, artist, seek bar and controls
// Opening doesn't swap one layout for another: the cover and the waveform
// travel to their places in the player while the rest fades in around them.
Reveal {
    id: root

    property bool open: false
    readonly property bool busy: seek.dragging

    readonly property int smallWidth: 300
    readonly property int openWidth: 452
    readonly property int openHeight: 180

    implicitWidth: open ? openWidth : smallWidth
    implicitHeight: open ? openHeight : Theme.pill
    anchors.fill: parent
    minScale: 0.97

    // 0 small → 1 open. No overshoot here: the island's own spring already has it.
    Spring {
        id: o
        target: root.open ? 1 : 0
        response: 0.38
        damping: 1
        epsilon: 0.002
    }

    readonly property real k: Math.max(0, Math.min(1, o.value))
    readonly property real strip: Math.min(height, Theme.pill + 2)   // the small island's height

    function mix(a, b) { return a + (b - a) * k; }
    function ramp(from, to) { return Math.max(0, Math.min(1, (k - from) / (to - from))); }

    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // Where the song is, read every frame while the player is open and playing
    // (so the bar glides), once a second while paused.
    property real pos: 0

    FrameAnimation {
        running: root.k > 0.01 && root.visible && Player.playing
        onTriggered: root.pos = Player.position()
    }

    Timer {
        running: root.k > 0.01 && root.visible && !Player.playing
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pos = Player.position()
    }

    // ---- shared: cover ----
    Cover {
        id: cover
        readonly property real s: root.mix(22, 64)

        x: root.mix(5, 20)
        y: root.mix((root.strip - 22) / 2, 20)
        width: s
        height: s
        radius: root.mix(11, 12)
        source: Player.art

        MouseArea {
            anchors.fill: parent
            enabled: root.k > 0.9
            cursorShape: Qt.PointingHandCursor
            onClicked: Player.raise()
        }
    }

    // ---- shared: waveform ----
    Waveform {
        id: wave
        bars: 5
        barWidth: root.mix(3, 3.5)
        gap: root.mix(2.5, 3)
        height: root.mix(14, 22)
        x: root.width - root.mix(13, 22) - width
        y: root.mix((root.strip - height) / 2, 25)
        color: Config.tintWaveform ? Player.tint : Theme.accent
    }

    // ---- small: the song's name ----
    Label {
        x: 37
        width: root.smallWidth - x - 13 - 25 - 12
        y: (root.strip - height) / 2
        text: Player.title
        font.pixelSize: 13
        font.weight: Font.Medium
        opacity: 1 - root.ramp(0, 0.3)
        visible: opacity > 0
    }

    // ---- open: the player ----
    Item {
        id: player
        anchors.fill: parent
        visible: root.k > 0.2
        enabled: root.k > 0.8

        // The title comes in with the cover; the seek bar and the buttons fade
        // in as the growing shape reaches them, so they're never cut off by it.
        function reached(y) { return Math.max(0, Math.min(1, (root.height - y) / 16)); }
        readonly property real r1: root.ramp(0.2, 0.7)                           // title, artist
        readonly property real r2: Math.min(root.ramp(0.3, 0.8), reached(110))   // seek bar
        readonly property real r3: Math.min(root.ramp(0.4, 0.9), reached(160))   // controls
        readonly property int textX: 100

        Marquee {
            x: player.textX
            y: 24
            width: root.width - x - 22 - wave.width - 14
            text: Player.title
            size: 15
            weight: Font.DemiBold
            opacity: player.r1
            transform: Translate { y: (1 - player.r1) * 8 }
        }

        Label {
            x: player.textX
            y: 47
            width: root.width - x - 22
            text: Player.artist
            color: Theme.inkSoft
            font.pixelSize: 13
            opacity: player.r1
            transform: Translate { y: (1 - player.r1) * 8 }
        }

        Label {
            x: player.textX
            y: 66
            width: root.width - x - 22
            text: Player.app
            color: Theme.inkFaint
            font.pixelSize: 11
            font.weight: Font.Medium
            opacity: player.r1
            transform: Translate { y: (1 - player.r1) * 8 }
        }

        // seek bar with the time on each side
        Item {
            x: 20
            y: 98
            width: root.width - 40
            height: 16
            opacity: player.r2
            transform: Translate { y: (1 - player.r2) * 8 }

            Label {
                id: elapsed
                width: 40
                anchors.verticalCenter: parent.verticalCenter
                text: root.time(seek.dragging ? seek.dragValue * Player.length : root.pos)
                tabular: true
                color: Theme.inkSoft
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Slider {
                id: seek
                x: 44
                width: parent.width - 88
                anchors.verticalCenter: parent.verticalCenter
                value: Player.length > 0 ? root.pos / Player.length : 0
                interactive: Player.canSeek
                onReleased: v => {
                    Player.seek(v * Player.length);
                    root.pos = v * Player.length;
                }
            }

            Label {
                width: 40
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: Player.length > 0
                      ? "-" + root.time(Player.length - (seek.dragging ? seek.dragValue * Player.length : root.pos))
                      : ""
                tabular: true
                color: Theme.inkSoft
                font.pixelSize: 11
                font.weight: Font.Medium
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 144 - height / 2
            spacing: 12
            opacity: player.r3
            transform: Translate { y: (1 - player.r3) * 10 }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.shuffle
                size: 16
                dim: !Player.canShuffle
                active: Player.shuffle
                onClicked: Player.toggleShuffle()
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.prev
                size: 22
                dim: !Player.canPrev
                onClicked: Player.prev()
            }

            Item {
                width: 44
                height: 44
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.accent
                    scale: playArea.pressed ? 0.9 : playArea.containsMouse ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                PlayPause {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    playing: Player.playing
                    color: Theme.accentInk
                }

                MouseArea {
                    id: playArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Player.toggle()
                }
            }

            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.next
                size: 22
                dim: !Player.canNext
                onClicked: Player.next()
            }

            // off → whole album / playlist → this song
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: Player.repeat === "track" ? Icons.repeatOnce : Icons.repeat
                size: 16
                dim: !Player.canRepeat
                active: Player.repeat !== "off"
                onClicked: Player.cycleRepeat()
            }
        }
    }
}
