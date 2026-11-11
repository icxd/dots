import QtQuick

// One quiet item in the login screen's bottom row: a word or an icon that
// brightens under the mouse.
Text {
    id: root

    property real s: 1
    property string textFont: "Inter"
    property string glyphFont: "JetBrainsMono Nerd Font"
    property bool glyph: false
    property bool clickable: true

    signal clicked()

    color: area.containsMouse && clickable ? "#e6ffffff" : "#66ffffff"
    font.family: glyph ? glyphFont : textFont
    font.pixelSize: Math.round((glyph ? 15 : 12.5) * s)

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -6 * root.s
        hoverEnabled: true
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
