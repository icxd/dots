import QtQuick
import qs.config

// Text in the island's typeface. `tabular` gives digits equal widths, so
// clocks and timers don't wiggle as they count.
Text {
    property bool tabular: false

    color: Theme.ink
    font.family: Theme.font
    font.pixelSize: 13
    font.features: tabular ? ({ "tnum": 1 }) : ({})
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    elide: Text.ElideRight
}
