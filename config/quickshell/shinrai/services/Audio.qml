pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Volume of the default speaker, through PipeWire.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: !!(sink && sink.audio)
    readonly property real volume: ready ? Math.max(0, sink.audio.volume) : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    // A node's volume can only be read and written while it's tracked.
    PwObjectTracker { objects: [root.sink] }

    function set(v) {
        if (!ready) return;
        sink.audio.volume = Math.max(0, Math.min(1, v));
        if (sink.audio.muted && v > 0) sink.audio.muted = false;
    }

    function nudge(delta) {
        set(volume + delta);
    }

    function toggleMute() {
        if (ready) sink.audio.muted = !sink.audio.muted;
    }
}
