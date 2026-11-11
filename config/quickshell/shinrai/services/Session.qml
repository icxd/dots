pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Lock, sleep, log out, restart, shut down (through bin/shinrai-power), and
// the uptime shown in the power view.
Singleton {
    id: root

    property string uptime: ""

    function run(action) {
        Quickshell.execDetached([Config.power, action]);
    }

    function refresh() {
        if (!reader.running) reader.running = true;
    }

    Process {
        id: reader
        command: ["cat", "/proc/uptime"]

        stdout: StdioCollector {
            onStreamFinished: {
                const s = Math.floor(parseFloat(text) || 0);
                const d = Math.floor(s / 86400);
                const h = Math.floor((s % 86400) / 3600);
                const m = Math.floor((s % 3600) / 60);
                root.uptime = "up " + (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "m";
            }
        }
    }
}
