pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.config

// The notification daemon. Notifications queue up and the island shows them
// one at a time on the focused monitor; urgent ones go to the front.
Singleton {
    id: root

    property var queue: []
    readonly property var current: queue.length > 0 ? queue[0] : null

    NotificationServer {
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.drop(n));
            if (n.urgency === NotificationUrgency.Critical && root.queue.length > 1)
                root.queue = [root.queue[0], n].concat(root.queue.slice(1));
            else
                root.queue = root.queue.concat([n]);
        }
    }

    function drop(n) {
        queue = queue.filter(x => x !== n && x !== null);
    }

    // How long (ms) a notification stays; 0 = until you dismiss it.
    function lifetime(n) {
        if (!n) return 0;
        if (n.urgency === NotificationUrgency.Critical) return 0;
        const t = n.expireTimeout;
        if (t > 0) return Math.max(2500, Math.min(15000, t * 1000));
        return Config.notificationTime;
    }

    function dismiss(n) {
        n = n ?? current;
        if (n) n.dismiss();
    }

    function expire(n) {
        n = n ?? current;
        if (n) n.expire();
    }

    // Clicking it: the app's default action if it has one, then it goes away.
    function activate(n) {
        n = n ?? current;
        if (!n) return;
        const action = Array.from(n.actions ?? []).find(a => a.identifier === "default");
        if (action) {
            action.invoke();
            Qt.callLater(() => {
                if (n && n.tracked) n.dismiss();
            });
        } else {
            n.dismiss();
        }
    }
}
