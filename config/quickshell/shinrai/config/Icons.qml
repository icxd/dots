pragma Singleton

import Quickshell
import QtQuick

// Material Design glyphs from the Nerd Font (JetBrainsMono Nerd Font).
// They sit in Unicode's private area, so editors without the font show boxes.
// More: https://www.nerdfonts.com/cheat-sheet (search "md-")
Singleton {
    function g(code) { return String.fromCodePoint(code); }

    readonly property string play:       g(0xf040a)
    readonly property string pause:      g(0xf03e4)
    readonly property string next:       g(0xf04ad)
    readonly property string prev:       g(0xf04ae)
    readonly property string shuffle:    g(0xf049d)
    readonly property string repeat:     g(0xf0456)
    readonly property string repeatOnce: g(0xf0458)
    readonly property string music:      g(0xf075a)
    readonly property string spotify:    g(0xf04c7)

    readonly property string search:     g(0xf0349)
    readonly property string apps:       g(0xf003b)
    readonly property string clipboard:  g(0xf014c)
    readonly property string copy:       g(0xf018f)
    readonly property string calc:       g(0xf00ec)
    readonly property string bell:       g(0xf009c)
    readonly property string enter:      g(0xf0311)
    readonly property string close:      g(0xf0156)

    readonly property string volHigh:    g(0xf057e)
    readonly property string volMid:     g(0xf0580)
    readonly property string volLow:     g(0xf057f)
    readonly property string volMute:    g(0xf075f)

    readonly property string lock:       g(0xf0341)
    readonly property string sleep:      g(0xf0f65)
    readonly property string logout:     g(0xf0343)
    readonly property string restart:    g(0xf0709)
    readonly property string power:      g(0xf0425)

    function volume(level, muted) {
        if (muted || level <= 0.001) return volMute;
        if (level < 0.34) return volLow;
        if (level < 0.67) return volMid;
        return volHigh;
    }
}
