pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Installed apps for the launcher: matched by name first, then by initials
// ("vsc" → Visual Studio Code), description and keywords, then loosely
// letter by letter. Apps you open often float up.
Singleton {
    id: root

    function count(entry) {
        return store.counts[entry?.id ?? ""] ?? 0;
    }

    function search(query, limit) {
        const q = query.trim().toLowerCase();
        const list = Array.from(DesktopEntries.applications.values).filter(e => e && !e.noDisplay);

        if (q === "") {
            return list.sort((a, b) => count(b) - count(a) || a.name.localeCompare(b.name)).slice(0, limit);
        }

        const scored = [];
        for (const e of list) {
            const s = score(e, q);
            if (s > 0) scored.push({ entry: e, score: s });
        }
        scored.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return scored.slice(0, limit).map(x => x.entry);
    }

    function words(text) {
        return text.split(/[\s\-_.:]+/).filter(w => w !== "");
    }

    // q's letters in order inside text; the closer together, the better.
    function fuzzy(text, q) {
        let from = 0;
        let last = -1;
        let gaps = 0;
        for (const ch of q) {
            const at = text.indexOf(ch, from);
            if (at < 0) return 0;
            if (last >= 0) gaps += at - last - 1;
            last = at;
            from = at + 1;
        }
        return Math.max(1, 90 - gaps * 5);
    }

    function score(e, q) {
        const name = (e.name ?? "").toLowerCase();
        const nameWords = words(name);
        let s = 0;
        if (name === q) s = 1000;
        else if (name.startsWith(q)) s = 800;
        else if (nameWords.some(w => w.startsWith(q))) s = 650;
        else if (nameWords.map(w => w[0]).join("").startsWith(q)) s = 550;
        else if (name.includes(q)) s = 450;
        else {
            const more = [e.genericName ?? "", Array.from(e.keywords ?? []).join(" "),
                          e.id ?? "", Array.from(e.categories ?? []).join(" ")].join(" ").toLowerCase();
            if (more.includes(q)) s = 250;
            else if (q.length >= 2) s = fuzzy(name, q);
        }
        if (s > 0) s += Math.min(80, 16 * Math.log2(1 + count(e)));
        return s;
    }

    function launch(e) {
        if (!e) return;
        if (e.runInTerminal) {
            const context = { command: [Config.terminal, "-e"].concat(Array.from(e.command)) };
            if (e.workingDirectory) context.workingDirectory = e.workingDirectory;
            Quickshell.execDetached(context);
        } else {
            e.execute();
        }
        const counts = Object.assign({}, store.counts);
        counts[e.id] = count(e) + 1;
        store.counts = counts;
    }

    // ---- launch counts, kept between sessions ----
    FileView {
        id: file
        path: Quickshell.statePath("launches.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) writeAdapter();
        }

        JsonAdapter {
            id: store
            property var counts: ({})
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", Quickshell.stateDir]
    }
}
