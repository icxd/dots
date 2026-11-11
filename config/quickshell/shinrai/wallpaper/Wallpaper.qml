import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config

// The wallpaper, behind everything, on pure black. It fades in when the
// shell starts and when `shinrai-wall` swaps it.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "#000000"

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "shinrai-wallpaper"

    Image {
        anchors.fill: parent
        // ?rev=… makes it reload when shinrai-wall replaces the file
        source: Config.wallpaper !== "" ? "file://" + Config.wallpaper + "?rev=" + Config.wallpaperRev : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 900; easing.type: Easing.OutCubic }
        }
    }
}
