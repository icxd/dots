import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Window
import qs.config
import qs.services
import qs.components

// The island on one monitor: a white shape at the top middle that changes
// into whatever it needs to be. Every monitor has one. The clock and music
// show on all of them; the launcher, power view, notifications and volume on
// the monitor you're on (or whose island you clicked); the workspace dots on
// the monitor that switched.
//
//   clock       resting state
//   music       something plays (paused: back to the clock after a moment)
//   player      the music island opened (hover it, or click)
//   volume      a moment after the volume changes
//   workspace   a moment after you switch workspaces
//   notif       a notification
//   launcher    apps / Spotify / clipboard  (Super + Space, A, C; right click)
//   power       clock, volume, lock … shut down  (Super + Shift + E; click the clock)
//
// The shape's width and height are springs (components/Spring.qml): every
// change of view just gives them a new target, so changes that interrupt
// each other blend instead of restarting.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property string screenName: modelData?.name ?? ""
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
    readonly property bool focused: Hub.focusedScreen === "" || Hub.focusedScreen === screenName
    readonly property bool panelHere: Hub.panel !== "" && (Hub.panelScreen === "" || Hub.panelScreen === screenName)
    readonly property bool hintHere: Hub.hint !== "" && (Hub.hintScreen === "" || Hub.hintScreen === screenName)
    property bool expanded: false   // the music island opened into the player

    readonly property string view: panelHere ? Hub.panel
        : expanded && Player.hasTrack ? "player"
        : hintHere ? Hub.hint
        : focused && Notifs.current !== null ? "notif"
        : Player.shown ? "music"
        : "clock"

    readonly property bool small: view === "clock" || view === "music" || view === "volume" || view === "workspace"

    // One line per change in the shell's log (`qs log -c shinrai`), to see what
    // the island did and why.
    onViewChanged: console.info("island", screenName + ":", view,
                                "| panel:", Hub.panel || "-", "hint:", Hub.hint || "-",
                                "expanded:", expanded, "hovered:", hover.hovered,
                                "music:", Player.shown ? "shown" : Player.hasTrack ? "paused" : "none")

    readonly property Item current: {
        switch (view) {
        case "music":
        case "player": return music;
        case "volume": return volume;
        case "workspace": return workspace;
        case "notif": return notif;
        case "launcher": return launcher;
        case "power": return power;
        default: return clock;
        }
    }

    // ---- shape ----
    // A small island swells a touch under the mouse, so it feels alive.
    readonly property real lift: small && hover.hovered ? 1 : 0

    Spring {
        id: w
        target: win.current.implicitWidth + win.lift * 10
        from: Theme.pill
        response: 0.5
        damping: 0.76
        epsilon: 0.05
    }

    Spring {
        id: h
        target: win.current.implicitHeight + win.lift * 2
        from: Theme.pill
        response: 0.46
        damping: 0.8
        epsilon: 0.05
    }

    // ---- window ----
    // Only as tall as the island needs (in steps, so it isn't resized on every
    // frame): the smaller the window, the less there is to redraw, which
    // matters with software rendering in a VM.
    readonly property real reach: Math.max(h.value, h.target)

    anchors.top: true
    exclusiveZone: Theme.gap + Theme.pill
    implicitWidth: Theme.windowWidth
    implicitHeight: reach <= Theme.pill + 4
        ? Theme.gap + Theme.pill + 14
        : Math.ceil((reach + Theme.gap + 60) / 80) * 80
    color: "transparent"

    WlrLayershell.namespace: "shinrai-island"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: panelHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Only the island takes clicks; the rest of the window lets them through.
    mask: Region {
        id: hit
        item: shape
    }

    // Clicking anywhere else closes the launcher / power view.
    //
    // The grab is armed only once the island actually has the keyboard: when a
    // layer switches to exclusive keyboard focus, Hyprland drops whatever grab
    // exists (LayerSurface.cpp: setGrab(nullptr)). Armed together, the grab was
    // wiped straight away and the panel closed the moment it opened. If the
    // keyboard never arrives, the timer arms it anyway, by then safely after
    // the switch.
    readonly property bool hasKeyboard: shape.Window.active
    property bool grabArmed: false

    onPanelHereChanged: {
        grabArmed = false;
        if (panelHere) armFallback.restart();
        else armFallback.stop();
    }

    onHasKeyboardChanged: {
        if (!hasKeyboard || !panelHere || grabArmed) return;
        console.info("island: has the keyboard, click-outside armed");
        grabArmed = true;
    }

    Timer {
        id: armFallback
        interval: 400
        onTriggered: {
            if (!win.panelHere || win.grabArmed) return;
            console.info("island: no keyboard yet, click-outside armed anyway");
            win.grabArmed = true;
        }
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.panelHere && win.grabArmed
        onCleared: {
            console.info("island: clicked outside");
            Hub.close();
        }
    }

    Loader {
        active: Theme.effects
        source: "IslandShadow.qml"
        x: shape.x
        y: shape.y
        width: shape.width
        height: shape.height
        opacity: Math.max(0, Math.min(1, (shape.height - Theme.pill - 8) / 60))
        visible: opacity > 0.01
    }

    ClippingRectangle {
        id: shape

        x: (win.width - width) / 2
        y: Theme.gap
        width: w.value
        height: h.value
        radius: Math.min(height / 2, Theme.radius)
        color: Theme.island
        antialiasing: true

        onXChanged: hit.changed()
        onWidthChanged: hit.changed()
        onHeightChanged: hit.changed()

        // fades in as the shell starts, while it grows from a dot into the pill
        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: 600
            easing.type: Easing.OutCubic
        }

        // Clicks and scrolls that no button takes.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: win.view === "clock" || win.view === "music" || win.view === "notif"
                         ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: mouse => win.clicked(mouse.button)

            onWheel: wheel => {
                if (!win.small && win.view !== "player" && win.view !== "notif") {
                    wheel.accepted = false;
                    return;
                }
                if (wheel.angleDelta.y !== 0) Audio.nudge(wheel.angleDelta.y > 0 ? 0.05 : -0.05);
            }
        }

        HoverHandler {
            id: hover
        }

        ClockView {
            id: clock
            shown: win.view === "clock"
        }

        MusicView {
            id: music
            shown: win.view === "music" || win.view === "player"
            open: win.view === "player"
        }

        VolumeView {
            id: volume
            shown: win.view === "volume"
        }

        WorkspaceView {
            id: workspace
            monitor: win.monitor
            shown: win.view === "workspace"
        }

        NotifView {
            id: notif
            shown: win.view === "notif"
            hovered: hover.hovered
        }

        LauncherView {
            id: launcher
            shown: win.view === "launcher"
        }

        PowerView {
            id: power
            shown: win.view === "power"
        }
    }

    // ---- clicks ----
    //   left    clock → power view · music → player · notification → open it
    //   right   launcher (or dismiss a notification)
    //   middle  play / pause
    //   scroll  volume
    function clicked(button) {
        if (button === Qt.MiddleButton) {
            Player.toggle();
            return;
        }
        if (button === Qt.RightButton) {
            if (view === "notif") Notifs.dismiss();
            else Hub.toggle("launcher", "apps", screenName);
            return;
        }
        switch (view) {
        case "clock":
            Hub.open("power", "", screenName);
            break;
        case "music":
            dwell.stop();
            expanded = true;
            break;
        case "notif":
            Notifs.activate();
            break;
        case "volume":
            Audio.toggleMute();
            break;
        }
    }

    // ---- hover ----
    // Resting on the music island opens the player; it closes again shortly
    // after the mouse leaves (not while dragging the seek bar).
    Timer {
        id: dwell
        interval: 180
        onTriggered: if (hover.hovered && win.view === "music") win.expanded = true
    }

    Timer {
        id: linger
        interval: 320
        onTriggered: {
            if (hover.hovered) return;
            if (music.busy) linger.restart();
            else win.expanded = false;
        }
    }

    Connections {
        target: hover
        function onHoveredChanged() {
            if (hover.hovered) {
                linger.stop();
                if (Config.hoverToExpand) dwell.restart();
            } else {
                dwell.stop();
                if (win.expanded) linger.restart();
            }
        }
    }

    Connections {
        target: Player
        function onHasTrackChanged() {
            if (!Player.hasTrack) win.expanded = false;
        }
    }

    Connections {
        target: Hub
        function onPanelChanged() {
            if (Hub.panel !== "") win.expanded = false;
        }
    }

    // The workspace dots, when this monitor switches workspace.
    Connections {
        target: win.monitor
        function onActiveWorkspaceChanged() { Hub.workspaceSwitched(win.screenName); }
    }

    // A volume / workspace hint stays while the mouse rests on it.
    Timer {
        interval: 400
        repeat: true
        running: hover.hovered && win.hintHere && !win.panelHere
        onTriggered: Hub.flash(Hub.hint, win.screenName)
    }
}
