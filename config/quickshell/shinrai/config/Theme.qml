pragma Singleton

import Quickshell
import QtQuick

// Colors, type and sizes. A dark island on the dark violet wallpaper, light
// ink on it, and the wallpaper's purple for the few things that are "on":
// the sliders, the play button, the chosen tab, the current workspace.
Singleton {
    // ---- desktop ----
    readonly property color desktop:    "#0a0512"   // the wallpaper's background, shown while it loads

    // ---- island ----
    readonly property color island:     "#130e18"
    readonly property color edge:       Qt.rgba(accent.r, accent.g, accent.b, 0.16)   // hairline round the island
    readonly property color ink:        "#efeaf5"   // main text and icons
    readonly property color inkSoft:    "#a097aa"   // secondary text
    readonly property color inkFaint:   "#655e6e"   // placeholders, hints
    readonly property color fill:       "#211a28"   // hover
    readonly property color fillStrong: "#2d2537"   // pressed, slider tracks

    // ---- purple (the wallpaper's hue, brightened to read on the island) ----
    readonly property color accent:     "#b287e3"
    readonly property color accentInk:  "#110b19"   // text and icons on accent
    readonly property color accentFill: "#2a1d39"   // the highlighted row in lists

    // ---- type ----
    readonly property string font:  "Inter"
    readonly property string icons: "JetBrainsMono Nerd Font"

    // ---- geometry (logical pixels) ----
    readonly property int gap:    8     // screen edge → island
    readonly property int pill:   32    // height of the small island
    readonly property int radius: 28    // corner radius once it has grown

    // The island's window is a little wider than the widest view (the
    // launcher), so the shadow has room. Its height follows the island.
    readonly property int windowWidth: 680

    // ---- rendering ----
    // Inside a VM, shinrai-shell switches Qt to software rendering, where blur
    // and shadows cost real CPU, so they're left out there.
    // SHINRAI_EFFECTS=1 or =0 in the environment overrides the guess.
    readonly property bool software: (Quickshell.env("LIBGL_ALWAYS_SOFTWARE") ?? "") !== ""
    readonly property bool effects: {
        const forced = Quickshell.env("SHINRAI_EFFECTS");
        return forced == null ? !software : forced === "1";
    }
}
