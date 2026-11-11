pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Song search for the launcher's music mode, through Spotify's Web API with
// your own developer app's keys from ~/.config/shinrai/spotify.env. It uses
// the client-credentials flow: search only, no access to your account.
Singleton {
    id: root

    property string clientId: ""
    property string clientSecret: ""
    property string market: ""
    property string deviceName: "Shinrai"   // the player's name in Spotify's device list
    readonly property bool configured: clientId !== "" && clientSecret !== ""

    property var results: []   // [{ uri, title, artist, album, duration, cover }]
    property bool busy: false
    property string error: ""

    property string token: ""
    property real tokenExpires: 0
    property int request: 0

    function search(query) {
        const id = ++request;
        query = query.trim();
        if (query.length < 2) {
            results = [];
            busy = false;
            error = "";
            return;
        }
        if (!configured) {
            busy = false;
            return;
        }
        busy = true;
        withToken(t => fetch(id, query, t, true));
    }

    function fetch(id, query, accessToken, mayRetry) {
        const url = "https://api.spotify.com/v1/search?type=track"
            + "&limit=" + Math.max(1, Math.min(10, Config.searchResults))
            + (market !== "" ? "&market=" + encodeURIComponent(market) : "")
            + "&q=" + encodeURIComponent(query);
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || id !== root.request) return;
            if (xhr.status === 401 && mayRetry) {   // the token ran out early
                root.token = "";
                root.withToken(t => root.fetch(id, query, t, false));
                return;
            }
            root.busy = false;
            if (xhr.status === 200) {
                root.error = "";
                root.results = root.parse(xhr.responseText);
            } else if (xhr.status === 429) {
                root.error = "Spotify asks to slow down, try again in a moment";
            } else {
                root.error = "Search failed (" + (xhr.status || "no connection") + ")";
            }
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("Authorization", "Bearer " + accessToken);
        xhr.send();
    }

    function parse(text) {
        let data = null;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return [];
        }
        return (data?.tracks?.items ?? []).filter(t => t?.uri).map(t => {
            const images = t.album?.images ?? [];   // largest first
            const small = images.length > 0 ? images[images.length - 1] : null;
            return {
                uri: t.uri,
                title: t.name ?? "",
                artist: (t.artists ?? []).map(a => a.name).join(", "),
                album: t.album?.name ?? "",
                duration: Math.round((t.duration_ms ?? 0) / 1000),
                cover: small?.url ?? ""
            };
        });
    }

    // Calls back with a valid access token, asking for a new one when needed.
    function withToken(callback) {
        if (token !== "" && Date.now() < tokenExpires - 60000) {
            callback(token);
            return;
        }
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            let data = null;
            try {
                data = JSON.parse(xhr.responseText);
            } catch (e) {}
            if (xhr.status === 200 && data?.access_token) {
                root.token = data.access_token;
                root.tokenExpires = Date.now() + (data.expires_in ?? 3600) * 1000;
                callback(root.token);
            } else {
                root.busy = false;
                root.error = xhr.status === 400 || xhr.status === 401
                    ? "Spotify didn't accept the keys in ~/.config/shinrai/spotify.env"
                    : "Couldn't reach Spotify (" + (xhr.status || "no connection") + ")";
            }
        };
        xhr.open("POST", "https://accounts.spotify.com/api/token");
        xhr.setRequestHeader("Authorization", "Basic " + Qt.btoa(clientId + ":" + clientSecret));
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        xhr.send("grant_type=client_credentials");
    }

    // KEY=value lines; comments, `export` and quotes are fine.
    function readEnv(text) {
        const env = {};
        for (const line of text.split("\n")) {
            const m = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
            if (!m) continue;
            let value = m[2];
            if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")))
                value = value.slice(1, -1);
            env[m[1]] = value;
        }
        return env;
    }

    // The keys file is watched, so edits apply without restarting anything.
    FileView {
        id: envFile
        path: Config.spotifyEnv
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: {
            const env = root.readEnv(text());
            const id = env.SPOTIFY_CLIENT_ID ?? "";
            const secret = env.SPOTIFY_CLIENT_SECRET ?? "";
            if (id !== root.clientId || secret !== root.clientSecret) root.token = "";
            root.clientId = id;
            root.clientSecret = secret;
            root.market = (env.SPOTIFY_MARKET ?? "").toUpperCase();
            root.deviceName = env.SOLOIST_DEVICE_NAME || "Shinrai";
        }
    }
}
