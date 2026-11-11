pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The music's spectrum from cava (assets/cava.conf: 12 bands, 0..1), running
// only while something plays. Without cava installed, a gentle made-up motion
// stands in so the waveform still moves.
Singleton {
    id: root

    readonly property int bands: 12
    property var values: []
    property bool installed: true
    readonly property bool wanted: Player.playing

    // bar i of n → a band. Neighbouring bars take bands far apart, so they
    // don't all rise together, and the top quarter (mostly hiss) is skipped.
    function level(i, n) {
        const v = values;
        if (!v || v.length === 0 || n <= 0) return 0;
        const band = Math.floor(((i * 7) % n) * (bands * 0.75) / n);
        const x = v[Math.min(v.length - 1, band)] ?? 0;
        return Math.min(1, 0.12 + Math.pow(x, 0.85) * 0.95);
    }

    onWantedChanged: sync()

    function sync() {
        const run = wanted && installed;
        if (cava.running !== run) cava.running = run;
        if (!wanted) values = [];
    }

    Process {
        id: cava
        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = [];
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i] !== "") out.push(Math.min(1, Number(parts[i]) / 1000));
                }
                root.values = out;
            }
        }

        // cava stops when PipeWire restarts; start it again
        onExited: (code, status) => {
            if (root.wanted && root.installed) retry.restart();
        }
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: root.sync()
    }

    Process {
        id: probe
        running: true
        command: ["sh", "-c", "command -v cava >/dev/null && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.installed = text.trim() === "yes";
                root.sync();
            }
        }
    }

    // ---- stand-in motion ----
    property real phase: 0

    Timer {
        running: root.wanted && !root.installed
        interval: 70
        repeat: true
        onTriggered: {
            root.phase += 0.07;
            const out = [];
            for (let i = 0; i < root.bands; i++) {
                const t = root.phase * (1.3 + i * 0.17) + i * 1.9;
                out.push(0.35 + 0.3 * Math.sin(t) + 0.2 * Math.sin(t * 2.3 + i));
            }
            root.values = out;
        }
    }
}
