import QtQuick
import Quickshell.Widgets
import qs.config

// Album art with rounded corners. A new cover fades in over the old one
// instead of popping; with no cover it shows a music note.
ClippingRectangle {
    id: root

    property string source: ""
    property Image front: null   // the image currently on top
    readonly property bool hasImage: front !== null && front.status === Image.Ready

    color: Theme.fill

    Glyph {
        anchors.centerIn: parent
        icon: Icons.music
        size: Math.max(8, root.width * 0.42)
        color: Theme.inkFaint
        opacity: root.hasImage ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }

    Image {
        id: a
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize.width: 256
        sourceSize.height: 256
        opacity: 0
        onStatusChanged: root.settle(a)
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    }

    Image {
        id: b
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        sourceSize.width: 256
        sourceSize.height: 256
        opacity: 0
        onStatusChanged: root.settle(b)
        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
    }

    function load() {
        if (source === "") {
            a.opacity = 0;
            b.opacity = 0;
            front = null;
            return;
        }
        if (front && String(front.source) === source) return;
        const back = front === a ? b : a;
        back.source = source;
        settle(back);   // already cached → ready right away
    }

    // A freshly loaded image comes to the front and fades in over the old one.
    function settle(img) {
        if (img.status !== Image.Ready || String(img.source) !== source || img === front) return;
        const other = img === a ? b : a;
        img.z = 1;
        other.z = 0;
        img.opacity = 1;
        other.opacity = 0;
        front = img;
    }

    onSourceChanged: load()
    Component.onCompleted: load()
}
