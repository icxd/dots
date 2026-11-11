pragma Singleton

import Quickshell
import QtQuick

// Colors, type and sizes. Black and white only: a white island on a black
// desktop, with black ink on the island.
Singleton {
    // ---- island ----
    readonly property color island:     "#ffffff"
    readonly property color ink:        "#0b0b0c"   // main text and icons
    readonly property color inkSoft:    "#6e6e73"   // secondary text
    readonly property color inkFaint:   "#aeaeb2"   // placeholders, hints
    readonly property color fill:       "#f2f2f4"   // hover, selection
    readonly property color fillStrong: "#e4e4e7"   // pressed, slider tracks

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
