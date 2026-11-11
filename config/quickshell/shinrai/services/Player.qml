pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import qs.config

// The one player the island shows and controls. Spotify Soloist (the music
// mode's background player) when it has a song, unless it's paused while some
// other app plays; otherwise the MPRIS player (Spotify app, Firefox, mpv, ...)
// that is playing, or the one that played last.
Singleton {
    id: root

    // ---- which MPRIS player ----
    property var lastPlaying: null

    Variants {
        model: Mpris.players.values

        Connections {
            required property var modelData
            target: modelData

            function onIsPlayingChanged() {
                if (modelData.isPlaying) root.lastPlaying = modelData;
            }
            Component.onCompleted: if (modelData.isPlaying) root.lastPlaying = modelData
        }
    }

    readonly property var mpris: {
        const list = Array.from(Mpris.players.values).filter(p => p && (p.trackTitle ?? "") !== "");
        const playing = list.filter(p => p.isPlaying);
        if (playing.length > 0) return playing.includes(lastPlaying) ? lastPlaying : playing[0];
        if (lastPlaying && list.includes(lastPlaying)) return lastPlaying;
        return list.length > 0 ? list[0] : null;
    }

    readonly property bool useSoloist: Soloist.hasTrack && (Soloist.playing || !(mpris?.isPlaying ?? false))

    // ---- what's playing ----
    readonly property bool active: useSoloist || mpris !== null
    readonly property bool playing: useSoloist ? Soloist.playing : (mpris?.isPlaying ?? false)
    readonly property string title: (useSoloist ? Soloist.title : mpris?.trackTitle) || ""
    readonly property string artist: (useSoloist ? Soloist.artist : mpris?.trackArtist) || ""
    readonly property string album: (useSoloist ? Soloist.album : mpris?.trackAlbum) || ""
    readonly property string art: (useSoloist ? Soloist.art : mpris?.trackArtUrl) || ""
    readonly property string app: useSoloist ? "Spotify" : (mpris?.identity || "")
    readonly property real length: useSoloist ? Soloist.length
        : (mpris?.lengthSupported ?? false) ? Math.max(0, mpris.length) : 0

    readonly property bool canSeek: length > 0
        && (useSoloist || ((mpris?.canSeek ?? false) && (mpris?.positionSupported ?? false)))
    readonly property bool canNext: useSoloist || (mpris?.canGoNext ?? false)
    readonly property bool canPrev: useSoloist || (mpris?.canGoPrevious ?? false)
    readonly property bool canShuffle: useSoloist || ((mpris?.canControl ?? false) && (mpris?.shuffleSupported ?? false))
    readonly property bool canRepeat: useSoloist || ((mpris?.canControl ?? false) && (mpris?.loopSupported ?? false))
    readonly property bool shuffle: useSoloist ? Soloist.shuffle : (mpris?.shuffle ?? false)
    // off, context (whole album / playlist) or track
    readonly property string repeat: {
        if (useSoloist) return Soloist.repeat;
        const loop = mpris?.loopState ?? MprisLoopState.None;
        return loop === MprisLoopState.Track ? "track" : loop === MprisLoopState.Playlist ? "context" : "off";
    }

    // ---- shown on the island ----
    // There's a song (playing or paused): the player can open, and the power
    // view shows it.
    readonly property bool hasTrack: active && title !== ""
    // The music island is the resting state only while something plays. After a
    // pause it stays a few seconds (so pause → play doesn't make it jump), then
    // the clock comes back.
    property bool lingering: false
    readonly property bool shown: hasTrack && (playing || lingering)

    onPlayingChanged: {
        if (playing) {
            linger.stop();
            lingering = false;
        } else {
            lingering = true;
            linger.restart();
        }
    }

    Timer {
        id: linger
        interval: Config.pausedLinger * 1000
        onTriggered: root.lingering = false
    }

    // The cover's most colorful shade, lightened enough to read on the dark island.
    // The color sampler reads local files only, so streamed covers (Spotify's
    // are https) are saved to ~/.cache first.
    property string localArt: ""

    function hash(text) {
        let h = 5381;
        for (let i = 0; i < text.length; i++) h = ((h * 33) ^ text.charCodeAt(i)) >>> 0;
        return h.toString(16);
    }

    onArtChanged: fetchArt()
    Component.onCompleted: fetchArt()

    function fetchArt() {
        if (!Config.tintWaveform || art === "") {
            localArt = "";
        } else if (art.startsWith("file:")) {
            localArt = art;
        } else if (art.startsWith("http")) {
            const path = Quickshell.cachePath("art/" + hash(art));
            artFetch.target = path;
            artFetch.exec(["sh", "-c", "[ -s \"$2\" ] || { mkdir -p \"${2%/*}\" && curl -fsSL -m 10 -o \"$2.part\" \"$1\" && mv \"$2.part\" \"$2\"; }", "sh", art, path]);
        }
    }

    Process {
        id: artFetch
        property string target: ""
        onExited: (code, status) => {
            if (code === 0) root.localArt = "file://" + target;
        }
    }

    ColorQuantizer {
        id: quantizer
        source: root.localArt
        depth: 2
        rescaleSize: 48
    }

    readonly property color tint: {
        let best = null;
        let bestSat = 0.28;   // greys and near-greys get the purple
        for (const c of Array.from(quantizer.colors ?? [])) {
            const sat = c.hslSaturation * Math.min(1, c.hslLightness * 3);
            if (sat > bestSat) {
                bestSat = sat;
                best = c;
            }
        }
        if (!best) return Theme.accent;
        // light enough to read on the dark island
        return Qt.hsla(best.hslHue, Math.min(0.8, best.hslSaturation), Math.min(0.76, Math.max(0.64, best.hslLightness)), 1);
    }

    // Seconds into the song, right now (cheap; call it every frame if you like).
    function position() {
        if (useSoloist) return Soloist.position();
        const p = mpris;
        if (!p || !p.positionSupported) return 0;
        const s = Math.max(0, p.position);
        return length > 0 ? Math.min(s, length) : s;
    }

    // ---- controls ----

    function toggle() {
        if (useSoloist) Soloist.toggle();
        else if (mpris?.canTogglePlaying) mpris.togglePlaying();
    }

    function next() {
        if (useSoloist) Soloist.next();
        else if (mpris?.canGoNext) mpris.next();
    }

    function prev() {
        if (useSoloist) Soloist.prev();
        else if (mpris?.canGoPrevious) mpris.previous();
    }

    function seek(seconds) {
        if (!canSeek) return;
        const to = Math.max(0, Math.min(length, seconds));
        if (useSoloist) Soloist.seek(to);
        else mpris.position = to;
    }

    function toggleShuffle() {
        if (useSoloist) Soloist.setShuffle(!Soloist.shuffle);
        else if (canShuffle) mpris.shuffle = !mpris.shuffle;
    }

    // off → context → track → off
    function cycleRepeat() {
        if (useSoloist) {
            Soloist.cycleRepeat();
        } else if (canRepeat) {
            mpris.loopState = repeat === "off" ? MprisLoopState.Playlist
                            : repeat === "context" ? MprisLoopState.Track
                            : MprisLoopState.None;
        }
    }

    // The app behind the music: its window, or for Soloist (which has none)
    // the launcher's music search.
    function raise() {
        if (useSoloist || !mpris) Hub.open("launcher", "music");
        else if (mpris.canRaise) mpris.raise();
    }
}
