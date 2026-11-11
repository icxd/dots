pragma Singleton

import Quickshell
import QtQuick

// Settings. Edit freely: Quickshell reloads the moment you save.
Singleton {
    readonly property string home: Quickshell.env("HOME") ?? ""

    // ---- desktop ----
    property string wallpaper: home + "/.config/shinrai/wallpaper.png"
    property int wallpaperRev: 0                        // bumped by `shinrai-wall` to reload
    property string terminal: home + "/.local/bin/shinrai-term"
    property string power: home + "/.local/bin/shinrai-power"
    property string clockFormat: "HH:mm"                // "h:mm AP" for 12-hour

    // ---- island ----
    property bool hoverToExpand: true   // rest the mouse on the music island to open the player
    property bool workspaceHint: true   // show the workspace dots for a moment when you switch
    property int hintTime: 1300         // ms the volume / workspace hint stays up
    property int notificationTime: 5000 // ms a notification stays, unless the app asks otherwise
    property int launcherRows: 7        // rows the launcher shows before it scrolls
    property bool tintWaveform: true    // color the little waveform with the album cover
    property int pausedLinger: 4        // seconds the music island stays after pausing, then the clock is back

    // ---- music (Spotify Soloist) ----
    property string soloistUrl: "ws://127.0.0.1:24879"   // must match the port in shinrai-soloist
    property string spotifyEnv: home + "/.config/shinrai/spotify.env"
    property int searchResults: 8                        // songs per search (Spotify allows 10)

    // Shown in the launcher's music mode while the search box is empty.
    // In Spotify: Share → Copy link, then paste it here.
    property var pinned: [
        // { name: "my playlist", uri: "https://open.spotify.com/playlist/..." },
    ]
}
