-- shinrai · Hyprland (Lua config, Hyprland 0.57+)
-- A dark violet desktop with one dark island at the top (Quickshell, see
-- ~/.config/quickshell/shinrai). Wiki: https://wiki.hypr.land/
--
-- Check this file without starting a session:
--   Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
-- Inside a session:  hyprctl configerrors


------------------
---- MONITORS ----
------------------

-- Every screen gets the wallpaper and its own island. The launcher, the power
-- view, notifications and the volume open on the screen you're on.
--
-- The VM: 3440x1440 at 100 Hz, scale 2 (the desktop is laid out as 1720x720).
hl.monitor({
    output   = "Virtual-1",
    mode     = "3440x1440@100",
    position = "auto",
    scale    = 2,
})

-- Every other screen: its highest resolution at its fastest refresh rate,
-- scale 1, each placed to the right of the last one.
hl.monitor({
    output   = "",
    mode     = "highres",
    position = "auto",
    scale    = 1,
})

-- Hyprland lines the screens up in the order it finds them, which may not be
-- the order on your desk. To fix the order, name each screen (`hyprctl monitors
-- all` lists them) and give each a position: x is the total width of the
-- screens to its left. For three 2560x1440 screens, left to right:
--
-- hl.monitor({ output = "DP-1",     mode = "2560x1440@165", position = "0x0",    scale = 1 })
-- hl.monitor({ output = "DP-2",     mode = "2560x1440@165", position = "2560x0", scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "5120x0", scale = 1 })
--
-- `desc:` + the start of a description (also in that list) instead of a name
-- keeps working if the cables move to other ports.


------------------
---- PROGRAMS ----
------------------

local terminal = "~/.local/bin/shinrai-term"    -- kitty (software-rendered inside VMs)
local files    = "thunar"
local shell    = "~/.local/bin/shinrai-shell"   -- Quickshell: wallpaper, island, notifications
local ipc      = "qs -c shinrai ipc call "


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd(shell)
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("wl-paste --watch cliphist store")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Dark violet, with the wallpaper's purple as the accent. Windows get a
-- hairline purple border when focused and a faint one otherwise. No blur:
-- there's nothing behind them but the dark wallpaper, and it's expensive
-- inside a VM.
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 12,   -- the island reserves its own strip at the top

        border_size = 1,

        col = {
            active_border   = "rgba(b287e399)",
            inactive_border = "rgba(b287e31a)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 16,
        rounding_power = 2.5,   -- a little squarer than a circle arc, like the island

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 26,
            render_power = 3,
            color        = 0x99000000,
        },

        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,   -- Quickshell draws the wallpaper
        disable_hyprland_logo   = true,
        background_color        = 0xff0a0512,   -- the wallpaper's own background
    },
})

-- Motion. Springs for things that move (they settle naturally and blend when
-- interrupted), quick ease-outs for fades.
hl.curve("out",    { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0},    {1, 1}   } })
hl.curve("soft",   { type = "spring", mass = 1, stiffness = 210, damping = 25 })   -- a hint of bounce
hl.curve("firm",   { type = "spring", mass = 1, stiffness = 300, damping = 32 })   -- no bounce

hl.animation({ leaf = "global",           enabled = true, speed = 8,   bezier = "default" })
hl.animation({ leaf = "windows",          enabled = true, speed = 5,   spring = "soft" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4.5, spring = "soft", style = "popin 92%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 1.6, bezier = "out",  style = "popin 92%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 5,   spring = "firm" })
hl.animation({ leaf = "border",           enabled = true, speed = 4,   bezier = "out" })
hl.animation({ leaf = "fade",             enabled = true, speed = 3,   bezier = "out" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 2,   bezier = "out" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 1.6, bezier = "out" })
hl.animation({ leaf = "layers",           enabled = true, speed = 3.5, bezier = "out" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3.5, bezier = "out",  style = "fade" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 2,   bezier = "out",  style = "fade" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 4.5, spring = "firm", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4,   spring = "soft", style = "slidefadevert 15%" })
hl.animation({ leaf = "zoomFactor",       enabled = true, speed = 7,   bezier = "out" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


---------------------
---- KEYBINDINGS ----
---------------------

local mod = "SUPER"

-- The island (Quickshell's global shortcuts: `hyprctl globalshortcuts` lists them)
hl.bind(mod .. " + Space", hl.dsp.global("shinrai:launcher"))    -- apps (Tab: Spotify, clipboard)
hl.bind(mod .. " + D",     hl.dsp.global("shinrai:launcher"))
hl.bind(mod .. " + A",     hl.dsp.global("shinrai:music"))       -- search Spotify
hl.bind(mod .. " + C",     hl.dsp.global("shinrai:clipboard"))   -- clipboard history
-- Power view. If the shell isn't running, this logs out instead, so there's
-- always a way out.
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd(ipc .. "island power || ~/.local/bin/shinrai-power logout"))

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd(files))
hl.bind(mod .. " + L",      hl.dsp.exec_cmd("loginctl lock-session"))

-- Windows
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))

-- Restart the shell (wallpaper + island)
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd(shell .. " --restart -d"))

-- Screenshots: region → clipboard, whole screen → ~/Pictures/Screenshots
hl.bind("Print",         hl.dsp.exec_cmd([[grim -g "$(slurp -d)" - | wl-copy]]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd([[mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png]]))

-- Focus / move with the arrow keys
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. dir,         hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- Workspaces 1-10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Drag / resize with the mouse
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume and brightness keys (the island shows the change)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media keys go through the island, which knows Spotify Soloist as well as
-- normal (MPRIS) players. playerctl takes over if the shell isn't running.
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(ipc .. "media toggle || playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(ipc .. "media toggle || playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(ipc .. "media next || playerctl next"),         { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(ipc .. "media prev || playerctl previous"),     { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Keeps drag-and-drop from XWayland apps working
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name   = "float-utilities",
    match  = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|nm-connection-editor|blueman-manager|xdg-desktop-portal-gtk|org.gnome.FileRoller)$" },
    float  = true,
    size   = { 900, 600 },
    center = true,
})

hl.window_rule({
    name   = "float-thunar-dialogs",
    match  = { class = "^(thunar)$", title = "^(File Operation Progress|Confirm to replace files)$" },
    float  = true,
    center = true,
})


----------------
---- LAYERS ----
----------------

-- The island and the wallpaper animate themselves (Quickshell); Hyprland's
-- own layer animation on top would fight them.
hl.layer_rule({
    name    = "shinrai-no-anim",
    match   = { namespace = "^shinrai-(island|wallpaper)$" },
    no_anim = true,
})
