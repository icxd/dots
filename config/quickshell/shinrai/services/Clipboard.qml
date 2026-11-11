pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard history from cliphist (Hyprland stores every copy through
// `wl-paste --watch cliphist store`), for the launcher's clipboard mode.
Singleton {
    id: root

    property var entries: []      // [{ key, line, text }], newest first
    property bool available: true

    function refresh() {
        if (!lister.running) lister.running = true;
    }

    // Put an old entry back on the clipboard.
    function copy(entry) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", entry.line]);
    }

    function remove(entry) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", entry.line]);
        entries = entries.filter(e => e.key !== entry.key);
    }

    Process {
        id: lister
        command: ["sh", "-c", "command -v cliphist >/dev/null || exit 3; cliphist list"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l !== "").map(l => {
                    const tab = l.indexOf("\t");
                    return {
                        key: "clip:" + (tab >= 0 ? l.slice(0, tab) : l),
                        line: l,
                        text: (tab >= 0 ? l.slice(tab + 1) : l).trim()
                    };
                });
            }
        }

        onExited: (code, status) => root.available = code !== 3
    }
}
