import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components

// The launcher. Type to search; Tab switches between Apps, Music (Spotify)
// and Clipboard, keeping what you typed, so "daft punk" then Tab searches
// Spotify for it.
//
// Apps mode also does sums ("2*21", or "=" first to force it) and session
// words ("lock", "sleep", "log out", "restart", "shut down").
//
//   ↑ ↓  Ctrl+J/K  PgUp/PgDn   move        Enter   open / play / copy
//   Tab  Shift+Tab             mode         Shift+Enter   add a song to the queue
//   Shift+Del (clipboard)      forget it    Esc   close
Reveal {
    id: root

    readonly property var modes: ["apps", "music", "clip"]
    readonly property var modeNames: ({ apps: "Apps", music: "Music", clip: "Clipboard" })
    readonly property var modeGlyphs: [Icons.search, Icons.music, Icons.clipboard]
    readonly property string mode: Hub.mode
    readonly property string query: input.text
    readonly property int rowHeight: 44
    readonly property int listHeight: Math.min(list.count, Config.launcherRows) * rowHeight

    property string pending: ""   // "play" / "queue": Enter came before the search results
    property string note: ""      // a short confirmation, e.g. "Added to queue"

    implicitWidth: 560
    implicitHeight: 64 + (list.count > 0 ? listHeight + 10 : 0)
    width: implicitWidth
    height: implicitHeight
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    // ---- rows ----
    // Every row is a plain object: { key, kind, title, sub, ... }. The key
    // tells the list which rows stayed, so they glide to their new places as
    // you type instead of the whole list being redrawn.
    readonly property var rows: mode === "music" ? musicRows(query.trim())
                              : mode === "clip" ? clipRows(query.trim())
                              : appRows(query.trim())

    ScriptModel {
        id: rowModel
        values: root.rows
        objectProp: "key"
    }

    function info(title, sub) {
        return { key: "info:" + title + "|" + sub, kind: "info", title: title, sub: sub, glyph: "" };
    }

    function appRows(q) {
        const out = [];
        const sum = calc(q);
        if (sum !== null) out.push({ key: "calc:" + sum, kind: "calc", title: sum, sub: "Enter copies it", glyph: Icons.calc, value: sum });
        for (const p of sessionRows(q)) out.push(p);
        for (const e of Apps.search(q, 40)) {
            out.push({ key: "app:" + e.id, kind: "app", title: e.name, sub: e.genericName || "", icon: e.icon, entry: e });
        }
        if (out.length === 0 && q !== "") out.push(info("No matches", "Tab searches Spotify instead"));
        return out;
    }

    readonly property var sessionWords: [
        { action: "lock",     title: "Lock",      glyph: Icons.lock,    words: ["lock"] },
        { action: "suspend",  title: "Sleep",     glyph: Icons.sleep,   words: ["sleep", "suspend"] },
        { action: "logout",   title: "Log out",   glyph: Icons.logout,  words: ["log out", "logout", "sign out", "exit"] },
        { action: "reboot",   title: "Restart",   glyph: Icons.restart, words: ["restart", "reboot"] },
        { action: "poweroff", title: "Shut down", glyph: Icons.power,   words: ["shut down", "shutdown", "power off", "poweroff"] }
    ]

    function sessionRows(q) {
        const s = q.toLowerCase();
        if (s.length < 3) return [];
        return sessionWords.filter(p => p.words.some(w => w.startsWith(s)))
            .map(p => ({ key: "session:" + p.action, kind: "session", title: p.title, sub: "Session", glyph: p.glyph, action: p.action }));
    }

    function musicRows(q) {
        const out = [];
        if (!Soloist.connected) out.push(info("The player isn't running", "systemctl --user start soloist"));
        else if (!Soloist.paired) out.push(info("Pair the player once", "Pick “" + Spotify.deviceName + "” in a Spotify app's device list"));

        const link = toUri(q);
        if (link) {
            out.push({ key: "link:" + link, kind: "song", title: "Play this " + kindOf(link), sub: q, glyph: Icons.spotify, uri: link });
            return out;
        }
        if (q === "") {
            for (const p of Config.pinned) {
                const uri = toUri(p.uri ?? "") ?? p.uri;
                out.push({ key: "pin:" + uri, kind: "song", title: p.name ?? uri, sub: kindOf(uri), glyph: Icons.spotify, uri: uri });
            }
            if (Config.pinned.length === 0) out.push(info("Search Spotify", "Type a song, artist or album, or paste a Spotify link"));
            return out;
        }
        if (!Spotify.configured) {
            out.push(info("Add your Spotify keys", "~/.config/shinrai/spotify.env (see the README)"));
            return out;
        }
        if (Spotify.error !== "") out.push(info(Spotify.error, ""));
        for (const t of Spotify.results) {
            out.push({ key: "song:" + t.uri, kind: "song", title: t.title, sub: t.artist, image: t.cover, glyph: Icons.music, uri: t.uri, duration: t.duration });
        }
        if (Spotify.results.length === 0 && Spotify.error === "" && !Spotify.busy && !searchDelay.running)
            out.push(info("No songs found", ""));
        return out;
    }

    function clipRows(q) {
        if (!Clipboard.available) return [info("cliphist isn't installed", "sudo pacman -S cliphist")];
        const s = q.toLowerCase();
        const hits = Clipboard.entries.filter(e => s === "" || e.text.toLowerCase().includes(s)).slice(0, 80);
        if (hits.length === 0) return [info(q === "" ? "Nothing copied yet" : "No matches", "")];
        return hits.map(e => ({
            key: e.key,
            kind: "clip",
            title: e.text.replace(/\s+/g, " "),
            sub: "",
            glyph: e.text.startsWith("[[ binary") ? Icons.clipboard : Icons.copy,
            entry: e
        }));
    }

    // "https://open.spotify.com/track/ID?si=…" or "spotify:track:ID" → "spotify:track:ID"
    function toUri(text) {
        const m = (text ?? "").match(/^(?:https?:\/\/open\.spotify\.com\/(?:intl-[a-z-]+\/)?|spotify:)(track|album|playlist|artist|episode|show)[\/:]([A-Za-z0-9]+)/);
        return m ? "spotify:" + m[1] + ":" + m[2] : null;
    }

    function kindOf(uri) {
        const type = (uri ?? "").split(":")[1] ?? "";
        return ({ track: "song", album: "album", playlist: "playlist", artist: "artist", episode: "episode", show: "podcast" })[type] ?? "link";
    }

    // + - * / % ^ and brackets. Returns the result as text, or null when q
    // isn't a sum ("=" first forces it; a lone number isn't one).
    function calc(q) {
        const forced = q.startsWith("=");
        const src = (forced ? q.slice(1) : q).replace(/,/g, ".").replace(/×/g, "*").replace(/÷/g, "/").replace(/\s+/g, "");
        if (src === "" || !/^[0-9+\-*\/%^().]+$/.test(src) || !/[0-9]/.test(src)) return null;
        if (!forced && !/[0-9)][+\-*\/%^]/.test(src)) return null;

        let i = 0;
        const peek = () => src[i];
        function atom() {
            if (peek() === "(") {
                i++;
                const v = sum();
                if (peek() !== ")") throw new Error("bracket");
                i++;
                return v;
            }
            const m = src.slice(i).match(/^(\d+\.?\d*|\.\d+)/);
            if (!m) throw new Error("number");
            i += m[0].length;
            return parseFloat(m[0]);
        }
        function power() {
            const base = atom();
            if (peek() === "^") {
                i++;
                return Math.pow(base, unary());
            }
            return base;
        }
        function unary() {
            if (peek() === "-") { i++; return -unary(); }
            if (peek() === "+") { i++; return unary(); }
            return power();
        }
        function product() {
            let v = unary();
            while (peek() === "*" || peek() === "/" || peek() === "%") {
                const op = src[i++];
                const r = unary();
                v = op === "*" ? v * r : op === "/" ? v / r : v % r;
            }
            return v;
        }
        function sum() {
            let v = product();
            while (peek() === "+" || peek() === "-") {
                const op = src[i++];
                const r = product();
                v = op === "+" ? v + r : v - r;
            }
            return v;
        }

        try {
            const v = sum();
            if (i !== src.length || !isFinite(v)) return null;
            return String(Number(v.toPrecision(12)));
        } catch (e) {
            return null;
        }
    }

    // ---- actions ----

    function selectable(i) {
        const r = rows[i];
        return !!r && r.kind !== "info";
    }

    function firstSelectable() {
        for (let i = 0; i < rows.length; i++) {
            if (selectable(i)) return i;
        }
        return 0;
    }

    function selectFirst() {
        list.currentIndex = firstSelectable();
        list.positionViewAtBeginning();
    }

    function move(step) {
        let i = list.currentIndex;
        const dir = step > 0 ? 1 : -1;
        let left = Math.abs(step);
        let best = i;
        while (left > 0) {
            i += dir;
            if (i < 0 || i >= rows.length) break;
            if (selectable(i)) {
                best = i;
                left--;
            }
        }
        list.currentIndex = best;
        reveal(best);
    }

    // Scroll just enough to bring row i into view, smoothly.
    function reveal(i) {
        const item = list.itemAtIndex(i);
        if (!item) {
            list.positionViewAtIndex(i, ListView.Contain);
            return;
        }
        let to = list.contentY;
        if (item.y < list.contentY) to = item.y;
        else if (item.y + rowHeight > list.contentY + list.height) to = item.y + rowHeight - list.height;
        if (to !== list.contentY) {
            scroller.to = to;
            scroller.restart();
        }
    }

    function setMode(m) {
        if (m !== Hub.mode) Hub.mode = m;
    }

    function cycleMode(step) {
        const i = modes.indexOf(mode);
        setMode(modes[(i + step + modes.length) % modes.length]);
    }

    function enter(toQueue) {
        const q = query.trim();
        const searching = mode === "music" && q.length >= 2 && !toUri(q) && Spotify.configured
                          && (searchDelay.running || Spotify.busy);
        if (searching) {
            // play the top result as soon as it's in
            if (searchDelay.running) {
                searchDelay.stop();
                Spotify.search(q);
            }
            pending = toQueue ? "queue" : "play";
            return;
        }
        activate(list.currentIndex, toQueue);
    }

    function activate(i, toQueue) {
        const r = rows[i];
        if (!r || r.kind === "info") return;
        switch (r.kind) {
        case "app":
            Hub.close();
            Apps.launch(r.entry);
            break;
        case "calc":
            Quickshell.execDetached(["wl-copy", "--", r.value]);
            Hub.close();
            break;
        case "session":
            Hub.close();
            Session.run(r.action);
            break;
        case "clip":
            Clipboard.copy(r.entry);
            Hub.close();
            break;
        case "song":
            if (!Soloist.connected || !Soloist.paired) return;   // the top row says why
            if (toQueue) {
                if (r.uri.startsWith("spotify:track:")) {
                    Soloist.queue(r.uri);
                    say("Added to queue");
                } else {
                    say("Only songs can be queued");
                }
            } else {
                Soloist.play(r.uri);
                Hub.close();
            }
            break;
        }
    }

    function say(text) {
        note = text;
        noteTimer.restart();
    }

    function key(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        switch (event.key) {
        case Qt.Key_Escape: Hub.close(); break;
        case Qt.Key_Down: move(1); break;
        case Qt.Key_Up: move(-1); break;
        case Qt.Key_PageDown: move(Config.launcherRows); break;
        case Qt.Key_PageUp: move(-Config.launcherRows); break;
        case Qt.Key_Tab: cycleMode(1); break;
        case Qt.Key_Backtab: cycleMode(-1); break;
        case Qt.Key_Return:
        case Qt.Key_Enter: enter(shift); break;
        case Qt.Key_Delete:
            if (!(mode === "clip" && shift)) return;
            if (selectable(list.currentIndex)) Clipboard.remove(rows[list.currentIndex].entry);
            break;
        default:
            if (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N)) move(1);
            else if (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P)) move(-1);
            else return;
        }
        event.accepted = true;
    }

    // ---- life cycle ----

    function start() {
        input.text = "";
        pending = "";
        note = "";
        if (mode === "clip") Clipboard.refresh();
        input.forceActiveFocus();
        Qt.callLater(selectFirst);
    }

    // later, so the view is enabled (and its window has the keyboard) first
    onShownChanged: if (shown) Qt.callLater(start)

    Connections {
        target: Hub
        function onOpenedChanged() {
            if (root.shown) Qt.callLater(root.start);
        }
        function onModeChanged() {
            if (!root.shown) return;
            if (Hub.mode === "clip") Clipboard.refresh();
            if (Hub.mode === "music") searchDelay.restart();
            Qt.callLater(root.selectFirst);
        }
    }

    Connections {
        target: Spotify
        function onResultsChanged() {
            if (root.pending === "") return;
            const toQueue = root.pending === "queue";
            root.pending = "";
            Qt.callLater(() => root.activate(root.firstSelectable(), toQueue));
        }
        function onErrorChanged() {
            if (Spotify.error !== "") root.pending = "";
        }
    }

    // Search shortly after typing stops, to stay well inside Spotify's limits.
    Timer {
        id: searchDelay
        interval: 260
        onTriggered: if (root.mode === "music" && !root.toUri(root.query.trim())) Spotify.search(root.query)
    }

    Timer {
        id: noteTimer
        interval: 1600
        onTriggered: root.note = ""
    }

    // ---- search row ----
    Item {
        id: bar
        y: 12
        width: parent.width
        height: 40

        // the mode's icon; they cross-fade when the mode changes
        Item {
            x: 20
            width: 22
            height: parent.height

            Repeater {
                model: root.modes

                Glyph {
                    required property string modelData
                    required property int index

                    anchors.centerIn: parent
                    icon: root.modeGlyphs[index]
                    size: 18
                    color: Theme.accent
                    opacity: root.mode === modelData ? 1 : 0
                    scale: root.mode === modelData ? 1 : 0.6

                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                }
            }
        }

        TextInput {
            id: input
            x: 54
            width: chips.x - x - 16
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: 16
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentInk
            selectByMouse: true
            clip: true
            focus: true

            Keys.onPressed: event => root.key(event)
            onTextChanged: {
                if (root.mode === "music") searchDelay.restart();
                Qt.callLater(root.selectFirst);
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: root.mode === "music" ? "Search Spotify" : root.mode === "clip" ? "Search clipboard" : "Search apps"
                color: Theme.inkFaint
                font.pixelSize: 16
            }
        }

        Label {
            anchors.right: chips.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.note !== "" ? root.note : Spotify.busy && root.mode === "music" ? "…" : ""
            color: Theme.inkSoft
            font.pixelSize: 12
            opacity: text !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
        }

        // mode switch: a purple pill slides to the chosen one
        Item {
            id: chips
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: chipRow.width
            height: 28

            readonly property Item chosen: chipRepeater.count > 0
                ? chipRepeater.itemAt(Math.max(0, root.modes.indexOf(root.mode))) : null

            Spring {
                id: markX
                target: chips.chosen?.x ?? 0
                response: 0.34
                damping: 0.82
                epsilon: 0.05
            }

            Spring {
                id: markW
                target: chips.chosen?.width ?? 0
                response: 0.34
                damping: 0.82
                epsilon: 0.05
            }

            Rectangle {
                x: markX.value
                width: markW.value
                height: parent.height
                radius: height / 2
                color: Theme.accent
            }

            Row {
                id: chipRow
                height: parent.height

                Repeater {
                    id: chipRepeater
                    model: root.modes

                    Item {
                        required property string modelData

                        width: chipLabel.implicitWidth + 22
                        height: chipRow.height

                        Label {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: root.modeNames[modelData]
                            color: root.mode === modelData ? Theme.accentInk : chipArea.containsMouse ? Theme.ink : Theme.inkSoft
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }

                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.setMode(modelData);
                                input.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }
    }

    // hairline under the search row
    Rectangle {
        x: 20
        y: 58
        width: parent.width - 40
        height: 1
        color: Theme.fill
        opacity: list.count > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    // ---- results ----
    Spring {
        id: markY
        target: list.currentItem ? list.currentItem.y : 0
        response: 0.3
        damping: 0.86
        epsilon: 0.1
    }

    ListView {
        id: list
        x: 8
        y: 64
        width: parent.width - 16
        height: root.listHeight
        clip: true
        model: rowModel
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        highlightFollowsCurrentItem: false
        cacheBuffer: 400

        highlight: Rectangle {
            width: list.width
            height: root.rowHeight
            y: markY.value
            radius: 14
            color: Theme.accentFill
            opacity: list.currentItem && list.currentItem.selectable ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: 260; easing.type: Easing.OutCubic }
            }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 100 }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; to: 1; duration: 120 }
            NumberAnimation { property: "scale"; to: 1; duration: 120 }
        }

        NumberAnimation {
            id: scroller
            target: list
            property: "contentY"
            duration: 180
            easing.type: Easing.OutCubic
        }

        delegate: Item {
            id: row

            required property var modelData
            required property int index

            readonly property string kind: modelData.kind ?? ""
            readonly property bool selectable: kind !== "info"
            readonly property bool current: ListView.isCurrentItem
            readonly property bool twoLines: (kind === "song" || kind === "info") && (modelData.sub ?? "") !== ""
            readonly property bool hasCover: kind === "song" && (modelData.image ?? "") !== ""
            readonly property string iconUrl: {
                if (kind !== "app") return "";
                const icon = modelData.icon ?? "";
                if (icon === "") return "";
                return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true);
            }

            width: ListView.view.width
            height: root.rowHeight

            // leading picture: app icon, song cover, or a glyph on a tile
            Item {
                id: lead
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                visible: row.kind !== "info" || (row.modelData.glyph ?? "") !== ""

                IconImage {
                    anchors.fill: parent
                    visible: row.iconUrl !== ""
                    source: row.iconUrl
                    asynchronous: true
                    mipmap: true
                }

                Cover {
                    anchors.fill: parent
                    visible: row.hasCover
                    source: row.hasCover ? row.modelData.image : ""
                    radius: 6
                }

                Rectangle {
                    anchors.fill: parent
                    visible: row.iconUrl === "" && !row.hasCover
                    radius: 8
                    color: row.current ? Theme.island : Theme.fill
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Glyph {
                        anchors.centerIn: parent
                        visible: text !== ""
                        icon: row.modelData.glyph ?? ""
                        size: 15
                    }

                    // apps without an icon get their first letter
                    Label {
                        anchors.centerIn: parent
                        visible: row.kind === "app"
                        text: (row.modelData.title ?? "?").charAt(0).toUpperCase()
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }
            }

            Label {
                id: title
                x: lead.visible ? 50 : 14
                width: Math.min(implicitWidth, row.width - x - trail.width - 26)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: row.twoLines ? -8 : 0
                text: row.modelData.title ?? ""
                color: row.selectable ? Theme.ink : Theme.inkSoft
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Label {
                x: row.twoLines ? title.x : title.x + title.width + 8
                width: Math.max(0, row.width - x - trail.width - 26)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: row.twoLines ? 9 : 0
                visible: text !== ""
                text: row.modelData.sub ?? ""
                color: row.twoLines ? Theme.inkSoft : Theme.inkFaint
                font.pixelSize: row.twoLines ? 12 : 13
            }

            Row {
                id: trail
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: (row.modelData.duration ?? -1) >= 0
                    text: {
                        const s = row.modelData.duration ?? 0;
                        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
                    }
                    tabular: true
                    color: Theme.inkFaint
                    font.pixelSize: 12
                }

                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: Icons.enter
                    size: 14
                    color: Theme.accent
                    opacity: row.current && row.selectable ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: row.selectable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // only a real mouse move selects (not rows scrolling under a still pointer)
                onPositionChanged: if (list.currentIndex !== row.index) list.currentIndex = row.index
                onClicked: mouse => root.activate(row.index, (mouse.modifiers & Qt.ShiftModifier) !== 0)
            }
        }
    }
}
