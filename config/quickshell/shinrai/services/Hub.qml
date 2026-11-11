pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config

// What the island has been asked to show, on top of its resting state:
//   panel  "launcher" or "power": opened by a key or a click, takes the keyboard
//   hint   "volume" or "workspace": flashes for a moment after a change
// Both appear on the monitor that has focus.
Singleton {
    id: hub

    property string panel: ""
    property string mode: "apps"         // launcher mode: apps, music or clip
    property string panelScreen: ""
    property int opened: 0               // counts opens, so views can start fresh

    property string hint: ""
    property string hintScreen: ""

    readonly property string focusedScreen: Hyprland.focusedMonitor?.name ?? ""

    // screen: the monitor's name (a click on its island), or the focused one.
    function open(name, launcherMode, screen) {
        if (launcherMode) mode = launcherMode;
        panelScreen = screen || focusedScreen;
        panel = name;
        opened++;
    }

    function close() {
        if (panel !== "") console.info("island: closing", panel);
        panel = "";
    }

    // The same key closes the panel again; a different mode switches to it.
    // A click on another monitor's island moves the panel over there.
    function toggle(name, launcherMode, screen) {
        if (panel === name && (!launcherMode || launcherMode === mode) && (!screen || screen === panelScreen))
            close();
        else
            open(name, launcherMode, screen);
    }

    function flash(kind, screen) {
        hint = kind;
        hintScreen = screen || focusedScreen;
        hintTimer.restart();
    }

    Timer {
        id: hintTimer
        interval: Config.hintTime
        onTriggered: hub.hint = ""
    }

    // ---- triggers ----
    // Stay quiet while the shell starts and when the speaker itself changes
    // (plugging in headphones "changes" the volume too).
    property real quietUntil: Date.now() + 2500

    Connections {
        target: Audio
        function onVolumeChanged() { hub.volumeMoved(); }
        function onMutedChanged() { hub.volumeMoved(); }
        function onSinkChanged() { hub.quietUntil = Date.now() + 1200; }
    }

    function volumeMoved() {
        if (Audio.ready && Date.now() > quietUntil) flash("volume");
    }

    // Each island calls this when its own monitor switches workspace. Focus
    // moving to another monitor (the mouse crossing screens) isn't a switch,
    // so the dots don't flash every time you look at another screen.
    function workspaceSwitched(screen) {
        if (Config.workspaceHint && Date.now() > quietUntil) flash("workspace", screen);
    }
}
