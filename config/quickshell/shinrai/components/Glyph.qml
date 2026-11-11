import QtQuick
import qs.config

// One Nerd Font icon (see Icons.qml).
Text {
    property string icon: ""
    property real size: 16

    text: icon
    color: Theme.ink
    font.family: Theme.icons
    font.pixelSize: Math.round(size)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
}
