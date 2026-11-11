import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.components

// Shown for a moment when you switch workspaces: a dot per workspace, the
// current one stretched into a purple dash. Workspaces with windows are brighter.
// With several monitors, the dash is the workspace on this island's monitor.
Reveal {
    id: root

    property HyprlandMonitor monitor: null

    readonly property var list: Array.from(Hyprland.workspaces.values)
    readonly property int focusedId: monitor?.activeWorkspace?.id ?? Hyprland.focusedWorkspace?.id ?? 1
    readonly property int count: {
        let n = Math.max(5, focusedId);
        for (const ws of list) {
            if (ws.id > 0) n = Math.max(n, ws.id);
        }
        return Math.min(10, n);
    }

    implicitWidth: dots.implicitWidth + 40
    implicitHeight: Theme.pill
    width: implicitWidth
    height: implicitHeight
    anchors.centerIn: parent

    Row {
        id: dots
        anchors.centerIn: parent
        spacing: 7

        Repeater {
            model: root.count

            Rectangle {
                required property int index
                readonly property int wsId: index + 1
                readonly property bool current: root.focusedId === wsId
                readonly property bool used: root.list.some(ws => ws.id === wsId)

                anchors.verticalCenter: parent.verticalCenter
                width: current ? 22 : 7
                height: 7
                radius: 3.5
                color: current ? Theme.accent : used ? Theme.inkSoft : Theme.fillStrong

                Behavior on width { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 220 } }
            }
        }
    }
}
