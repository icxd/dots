//@ pragma Env QT_LOGGING_RULES=qt.qpa.wayland.textinput=false

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.services
import qs.island
import qs.wallpaper

// shinrai · the whole desktop shell: the wallpaper and the island on every
// monitor, plus the notification daemon.
//
// Start:      shinrai-shell            (qs -c shinrai, software rendering inside VMs)
// Keys:       Hyprland binds them to the global shortcuts below (shinrai:launcher …)
// Scripts:    qs -c shinrai ipc call island launcher | music | clipboard | power | close
//             qs -c shinrai ipc call media toggle | next | prev
//             qs -c shinrai ipc call wallpaper reload
ShellRoot {
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }

    Variants {
        model: Quickshell.screens
        IslandWindow {}
    }

    // Start the notification daemon right away, before anything sends one.
    Component.onCompleted: Notifs.queue

    // ---- keys (Hyprland: hl.dsp.global("shinrai:<name>")) ----
    GlobalShortcut {
        appid: "shinrai"
        name: "launcher"
        description: "Open the launcher"
        onPressed: {
            console.info("key: launcher");
            Hub.toggle("launcher", "apps");
        }
    }

    GlobalShortcut {
        appid: "shinrai"
        name: "music"
        description: "Search Spotify"
        onPressed: {
            console.info("key: music");
            Hub.toggle("launcher", "music");
        }
    }

    GlobalShortcut {
        appid: "shinrai"
        name: "clipboard"
        description: "Clipboard history"
        onPressed: {
            console.info("key: clipboard");
            Hub.toggle("launcher", "clip");
        }
    }

    GlobalShortcut {
        appid: "shinrai"
        name: "power"
        description: "Power view"
        onPressed: {
            console.info("key: power");
            Hub.toggle("power");
        }
    }

    // ---- scripts ----
    IpcHandler {
        target: "island"

        function launcher(): void { Hub.toggle("launcher", "apps"); }
        function music(): void { Hub.toggle("launcher", "music"); }
        function clipboard(): void { Hub.toggle("launcher", "clip"); }
        function power(): void { Hub.toggle("power"); }
        function close(): void { Hub.close(); }
    }

    // Media keys come through here, so they control the same player the
    // island shows (Spotify Soloist included, which playerctl can't see).
    IpcHandler {
        target: "media"

        function toggle(): void { Player.toggle(); }
        function next(): void { Player.next(); }
        function prev(): void { Player.prev(); }
    }

    IpcHandler {
        target: "wallpaper"

        function reload(): void { Config.wallpaperRev++; }
    }
}
