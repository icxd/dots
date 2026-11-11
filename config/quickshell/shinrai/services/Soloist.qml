pragma Singleton

import Quickshell
import QtQuick
import QtWebSockets
import qs.config

// Spotify Soloist: Spotify's own player, running without a window as the
// `soloist` user service (bin/shinrai-soloist). It plays what you pick in the
// launcher's music mode; this talks to it over its local WebSocket.
Singleton {
    id: root

    readonly property bool connected: socket.status === WebSocket.Open
    property bool paired: false          // logged in to your Spotify account
    property bool isDevice: false        // Spotify is currently playing on it
    property string status: "idle"       // idle, playing, paused or buffering
    property var track: null             // the current song, as Soloist describes it
    property bool shuffle: false
    property string repeat: "off"        // off, context (album / playlist) or track

    // position = anchor + time since then × speed
    property real anchorMs: 0
    property real anchorAt: 0
    property real speed: 0

    readonly property bool hasTrack: connected && paired && (track?.uri ?? "") !== ""
    readonly property bool playing: status === "playing" || status === "buffering"
    readonly property string title: track?.decorations?.identity?.name ?? ""
    readonly property string artist: (track?.decorations?.creators ?? [])
        .map(c => c?.entity?.decorations?.identity?.name ?? "")
        .filter(name => name !== "")
        .join(", ")
    readonly property string album: track?.decorations?.parent?.entity?.decorations?.identity?.name ?? ""
    readonly property string art: coverOf(track)
    readonly property real length: (track?.decorations?.playback?.duration_ms ?? 0) / 1000

    // Seconds into the song, right now.
    function position() {
        const ms = anchorMs + (Date.now() - anchorAt) * speed;
        const s = Math.max(0, ms / 1000);
        return length > 0 ? Math.min(s, length) : s;
    }

    // The "large" cover if there is one (the island never shows it bigger).
    function coverOf(entity) {
        const own = entity?.decorations?.visual_identity?.cover ?? [];
        const album = entity?.decorations?.parent?.entity?.decorations?.visual_identity?.cover ?? [];
        const covers = own.length > 0 ? own : album;
        for (const size of ["large", "default", "xlarge", "small"]) {
            const hit = covers.find(c => c?.size === size && c?.url);
            if (hit) return hit.url;
        }
        return covers.length > 0 ? (covers[0]?.url ?? "") : "";
    }

    // ---- commands ----

    function send(command, fields) {
        if (!connected) return false;
        socket.sendTextMessage(JSON.stringify(Object.assign({ type: "command", command: command }, fields ?? {})));
        return true;
    }

    // A song / album / playlist URI, or "" to resume. Takes playback over from
    // another device if Spotify was playing somewhere else.
    function play(uri) {
        if (!isDevice) send("activate");
        return send("play", uri ? { uri: uri } : {});
    }
    function pause() { return send("pause"); }
    function toggle() { return playing ? pause() : play(""); }
    function next() { return send("skip_next"); }
    function prev() { return send("skip_prev"); }
    function queue(uri) { return send("add_to_queue", { uri: uri }); }

    function seek(seconds) {
        anchorMs = seconds * 1000;   // show it right away
        anchorAt = Date.now();
        return send("seek", { position_ms: Math.round(seconds * 1000) });
    }

    function setShuffle(on) {
        shuffle = on;
        return send("set_shuffle", { enabled: on });
    }

    // off → context → track → off
    function cycleRepeat() {
        if (repeat === "off") {
            repeat = "context";
            send("set_repeat_context", { enabled: true });
        } else if (repeat === "context") {
            repeat = "track";
            send("set_repeat_track", { enabled: true });
        } else {
            repeat = "off";
            send("set_repeat_track", { enabled: false });
            send("set_repeat_context", { enabled: false });
        }
    }

    // ---- events ----

    function options(o) {
        if (!o) return;
        shuffle = o.shuffle === true;
        repeat = o.repeat ?? "off";
    }

    function anchor(p) {
        if (!p) return;
        anchorMs = p.position_ms ?? 0;
        anchorAt = p.timestamp_ms ?? Date.now();
        speed = p.speed ?? 0;
    }

    function handle(e) {
        switch (e.type) {
        case "auth_state":
            paired = e.logged_in === true;
            isDevice = e.is_active === true;
            if (!paired) {
                track = null;
                status = "idle";
            }
            break;
        case "playback_state":
            status = e.status ?? "idle";
            track = e.item ?? null;
            isDevice = e.is_active === true;
            options(e.options);
            anchor(e.position);
            break;
        case "track_changed":
            track = e.item ?? null;
            break;
        case "playback_changed":
            status = e.status ?? status;
            break;
        case "position_sync":
            anchor(e.position);
            break;
        case "device_changed":
            isDevice = e.is_active === true;
            break;
        case "options_changed":
            options(e.options);
            break;
        case "error":
            console.warn("soloist:", e.message);
            break;
        }
    }

    WebSocket {
        id: socket
        url: Config.soloistUrl
        active: true

        onTextMessageReceived: message => {
            try {
                root.handle(JSON.parse(message));
            } catch (err) {
                console.warn("soloist: unreadable message:", err);
            }
        }

        onStatusChanged: () => {
            if (socket.status === WebSocket.Closed || socket.status === WebSocket.Error) {
                root.paired = false;
                root.track = null;
                root.status = "idle";
                reconnect.restart();
            }
        }
    }

    // Soloist may start after the shell, or restart for an update: keep trying.
    Timer {
        id: reconnect
        interval: 3000
        onTriggered: {
            socket.active = false;
            socket.active = true;
        }
    }
}
