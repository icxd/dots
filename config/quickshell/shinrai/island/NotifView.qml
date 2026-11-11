import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components

// A notification: icon, app, summary, up to three lines of text and the
// app's buttons. Click it to open it, right-click to dismiss. It stays while
// the mouse is on it. When the next one is waiting, the text swaps in place.
Reveal {
    id: root

    property bool hovered: false

    // What's on screen, copied out of the notification so it can finish
    // fading after the notification itself is gone.
    property var showing: null
    property string app: ""
    property string summary: ""
    property string body: ""
    property string image: ""
    property string icon: ""
    property var actions: []

    implicitWidth: 400
    implicitHeight: Math.max(64, column.implicitHeight + 28)
    width: implicitWidth
    height: implicitHeight
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    function asUrl(path) {
        if (!path) return "";
        return path.startsWith("/") ? "file://" + path : path;
    }

    function take(n) {
        showing = n;
        app = n?.appName ?? "";
        summary = n?.summary ?? "";
        body = n?.body ?? "";
        image = asUrl(n?.image ?? "");
        const appIcon = n?.appIcon ?? "";
        icon = appIcon === "" ? ""
             : appIcon.startsWith("/") || appIcon.includes("://") ? asUrl(appIcon)
             : Quickshell.iconPath(appIcon, true);
        actions = Array.from(n?.actions ?? []).filter(a => a.identifier !== "default" && a.text !== "").slice(0, 3);
        if (life.running) life.restart();
    }

    readonly property var incoming: Notifs.current

    onIncomingChanged: {
        if (!incoming || incoming === showing) return;   // with none left, keep the last one while the island moves on
        if (!shown || showing === null) take(incoming);
        else swap.restart();
    }

    Component.onCompleted: if (incoming) take(incoming)

    // The app updated the notification that's showing (e.g. a progress text).
    Connections {
        target: root.showing
        ignoreUnknownSignals: true
        function onSummaryChanged() { root.take(root.showing); }
        function onBodyChanged() { root.take(root.showing); }
    }

    SequentialAnimation {
        id: swap
        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 110; easing.type: Easing.InQuad }
        ScriptAction { script: root.take(Notifs.current) }
        NumberAnimation { target: content; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
    }

    Timer {
        id: life
        interval: Math.max(1, Notifs.lifetime(root.showing))
        running: root.shown && root.showing !== null && Notifs.lifetime(root.showing) > 0 && !root.hovered
        onTriggered: Notifs.expire(root.showing)
    }

    Item {
        id: content
        anchors.fill: parent

        // the picture: the notification's own image, else the app's icon
        Item {
            x: 16
            y: 14
            width: 36
            height: 36

            ClippingRectangle {
                anchors.fill: parent
                radius: 10
                color: Theme.fill
                visible: root.image !== ""

                Image {
                    anchors.fill: parent
                    source: root.image
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 72
                    sourceSize.height: 72
                }
            }

            IconImage {
                anchors.fill: parent
                visible: root.image === "" && root.icon !== ""
                source: root.icon
                asynchronous: true
                mipmap: true
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: Theme.fill
                visible: root.image === "" && root.icon === ""

                Glyph {
                    anchors.centerIn: parent
                    icon: Icons.bell
                    size: 17
                }
            }
        }

        Column {
            id: column
            x: 64
            y: 14
            width: parent.width - x - 18
            spacing: 2

            Label {
                width: parent.width
                visible: text !== ""
                text: root.app
                color: Theme.accent
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Label {
                width: parent.width
                visible: text !== ""
                text: root.summary
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Label {
                width: parent.width
                visible: text !== ""
                text: root.body
                color: Theme.inkSoft
                font.pixelSize: 13
                wrapMode: Text.Wrap
                maximumLineCount: 3
                lineHeight: 1.1
            }

            Item {
                width: 1
                height: 6
                visible: root.actions.length > 0
            }

            Row {
                spacing: 6
                visible: root.actions.length > 0

                Repeater {
                    model: root.actions

                    Rectangle {
                        required property var modelData

                        width: actionLabel.implicitWidth + 22
                        height: 26
                        radius: 13
                        color: actionArea.pressed ? Theme.fillStrong : actionArea.containsMouse ? Theme.fillStrong : Theme.fill
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Label {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
