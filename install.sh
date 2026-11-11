#!/usr/bin/env bash
# shinrai · installer for Arch Linux + Hyprland 0.57+
#
#   bash install.sh                 install packages, place configs
#   bash install.sh --link          symlink configs to this folder instead (edits here apply live)
#   bash install.sh --no-packages   skip pacman and downloads, only place configs
#
# Anything it replaces is renamed to <name>.bak-<timestamp> first, never deleted.
# Leftovers of the previous rice (noir) are moved into one folder:
# ~/.local/share/shinrai/noir-leftovers-<timestamp>.

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN="$HOME/.local/bin"
STAMP="$(date +%Y%m%d-%H%M%S)"
MODE="copy"
PACKAGES=1

for arg in "$@"; do
    case "$arg" in
        --link)        MODE="link" ;;
        --no-packages) PACKAGES=0 ;;
        -h|--help)     sed -n '2,11p' "$0"; exit 0 ;;
        *)             echo "unknown option: $arg" >&2; exit 1 ;;
    esac
done

PKGS=(
    # compositor + shell
    hyprland quickshell qt6-svg qt6-imageformats qt6-websockets
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    hyprlock hypridle hyprpolkitagent libnotify
    # apps and tools the desktop uses
    kitty thunar cava fastfetch cliphist wl-clipboard grim slurp brightnessctl imagemagick xdg-utils curl
    neovim fd ripgrep git
    spotify-launcher
    # audio
    pipewire pipewire-pulse wireplumber pavucontrol playerctl
    # fonts: Inter for the island, JetBrains Mono Nerd Font for the terminal and icons
    inter-font ttf-jetbrains-mono-nerd
    # shell
    zsh zsh-autosuggestions zsh-syntax-highlighting eza
)

say()  { printf '\033[1;37m::\033[0m %s\n' "$*"; }
note() { printf '   %s\n' "$*"; }
warn() { printf '\033[0;37m!!\033[0m %s\n' "$*" >&2; }
tidy() { printf '%s' "${1/#"$HOME"/"~"}"; }

if [[ $EUID -eq 0 ]]; then
    warn "run this as your normal user, not root (it asks for sudo when it needs it)"
    exit 1
fi

SPOTIFY_ENV="$CONFIG/shinrai/spotify.env"
SOLOIST_DIR="$DATA/shinrai/soloist"
LEFTOVERS="$DATA/shinrai/noir-leftovers-$STAMP"

# ------------------------------------------------------------ packages
if [[ $PACKAGES -eq 1 ]]; then
    say "installing packages (pacman -Syu --needed)"
    sudo pacman -Syu --needed "${PKGS[@]}"

    # The island is the notification daemon now. Another daemon that's
    # installed can grab notifications first (D-Bus starts it on demand).
    others=()
    for p in mako dunst swaync; do
        pacman -Q "$p" >/dev/null 2>&1 && others+=("$p")
    done
    if [[ ${#others[@]} -gt 0 ]]; then
        warn "another notification daemon is installed: ${others[*]}. It can take notifications away from the island."
        if [[ -t 0 ]]; then
            read -r -p "   remove ${others[*]}? [Y/n] " answer
            if [[ ! $answer =~ ^[Nn] ]]; then
                sudo pacman -Rns "${others[@]}" || warn "couldn't remove ${others[*]}; remove it later with: sudo pacman -Rns ${others[*]}"
            fi
        else
            warn "remove it with: sudo pacman -Rns ${others[*]}"
        fi
    fi
fi

# ------------------------------------------------------------ the old rice
# Stop noir's shell before its files move away.
if pgrep -f "qs -c noir" >/dev/null 2>&1; then
    qs kill -c noir >/dev/null 2>&1 || pkill -f "qs -c noir" || true
fi
pkill -x mako 2>/dev/null || true

stash() {   # stash <path>: move one noir leftover into the leftovers folder
    local path="$1" dest
    [[ -e "$path" || -L "$path" ]] || return 0
    # Keep its place under ~ (several leftovers share a name, e.g. ~/.config/noir
    # and ~/.local/share/noir), so nothing collides.
    dest="$LEFTOVERS/${path#"$HOME"/}"
    mkdir -p "$(dirname -- "$dest")"
    if mv -- "$path" "$dest"; then
        note "moved   $(tidy "$path") -> $(tidy "$dest")"
    else
        warn "couldn't move $(tidy "$path") aside; it stays where it is"
    fi
}

# Carry the Spotify keys over, once, before the old folder moves.
mkdir -p "$CONFIG/shinrai"
if [[ ! -e "$SPOTIFY_ENV" && -f "$CONFIG/noir/spotify.env" ]]; then
    sed 's/^SOLOIST_DEVICE_NAME=Noir$/SOLOIST_DEVICE_NAME=Shinrai/' "$CONFIG/noir/spotify.env" > "$SPOTIFY_ENV"
    chmod 600 "$SPOTIFY_ENV"
    note "copied  your Spotify keys from ~/.config/noir/spotify.env"
fi

# Reuse the Soloist download instead of fetching it again.
if [[ ! -e "$SOLOIST_DIR" && -x "$DATA/noir/soloist/soloist" ]]; then
    mkdir -p "$(dirname -- "$SOLOIST_DIR")"
    mv -- "$DATA/noir/soloist" "$SOLOIST_DIR"
    note "moved   the Soloist player to $(tidy "$SOLOIST_DIR")"
fi

found=0
for path in "$BIN"/noir-* "$CONFIG/quickshell/noir" "$CONFIG/noir" "$CONFIG/mako" "$CONFIG/rofi" \
            "$CONFIG/spicetify/Themes/Noir" "$DATA/noir"; do
    if [[ -e "$path" || -L "$path" ]]; then
        [[ $found -eq 0 ]] && say "putting the old rice (noir) aside"
        found=1
        stash "$path"
    fi
done

# The Spotify app was themed purple by spicetify: put it back to stock.
if [[ -x "$HOME/.spicetify/spicetify" ]] && grep -qs 'current_theme *= *Noir' "$CONFIG/spicetify/config-xpui.ini"; then
    "$HOME/.spicetify/spicetify" config current_theme "" color_scheme "" >/dev/null 2>&1 || true
    if "$HOME/.spicetify/spicetify" restore >/dev/null 2>&1; then
        note "restored the Spotify app to its normal look (spicetify restore)"
    fi
fi

# noir's app-menu entries started noir scripts, which are gone now.
for entry in "$DATA/applications/spotify-launcher.desktop" "$DATA/applications/kitty.desktop"; do
    if grep -qs 'noir-' "$entry"; then
        stash "$entry"
    fi
done

# ------------------------------------------------------------ soloist download
if [[ $PACKAGES -eq 1 && ! -x "$SOLOIST_DIR/soloist" ]]; then
    say "downloading Spotify Soloist (from Spotify)"
    SHINRAI_SOLOIST_NO_RESTART=1 sh "$REPO/bin/shinrai-soloist-update" ||
        warn "the Soloist download failed; the player downloads it the first time it starts"
fi

# ------------------------------------------------------------ configs
place() {   # place <path in repo> <destination>
    local src="$REPO/$1" dst="$2"
    if [[ ! -e "$src" ]]; then
        warn "missing in the repo: $1 (skipped)"
        return
    fi
    mkdir -p "$(dirname -- "$dst")"
    if [[ -L "$dst" && "$(readlink -f -- "$dst")" == "$(readlink -f -- "$src")" ]]; then
        note "ok      $(tidy "$dst")"
        return
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        mv -- "$dst" "$dst.bak-$STAMP"
        note "backup  $(tidy "$dst") -> $(basename -- "$dst").bak-$STAMP"
    fi
    if [[ $MODE == "link" ]]; then
        ln -s -- "$src" "$dst"
    else
        cp -r -- "$src" "$dst"
    fi
    note "$MODE    $(tidy "$dst")"
}

say "placing configs ($MODE)"
place config/hypr/hyprland.lua   "$CONFIG/hypr/hyprland.lua"
place config/hypr/hyprlock.conf  "$CONFIG/hypr/hyprlock.conf"
place config/hypr/hypridle.conf  "$CONFIG/hypr/hypridle.conf"
place config/hypr/scripts        "$CONFIG/hypr/scripts"

# Quickshell ignores named configs (like shinrai) while ~/.config/quickshell
# has a shell.qml of its own, so an old top-level config moves aside.
if [[ -e "$CONFIG/quickshell/shell.qml" ]]; then
    mv -- "$CONFIG/quickshell" "$CONFIG/quickshell.bak-$STAMP"
    note "backup  ~/.config/quickshell -> quickshell.bak-$STAMP (its shell.qml would hide shinrai)"
fi
place config/quickshell/shinrai  "$CONFIG/quickshell/shinrai"
place config/kitty               "$CONFIG/kitty"
place config/cava                "$CONFIG/cava"
place config/fastfetch           "$CONFIG/fastfetch"
place config/nvim                "$CONFIG/nvim"
# Keep your plugin versions: a fresh ~/.config/nvim gets the old lockfile back.
if [[ -f "$CONFIG/nvim.bak-$STAMP/nvim-pack-lock.json" && ! -e "$CONFIG/nvim/nvim-pack-lock.json" ]]; then
    cp -- "$CONFIG/nvim.bak-$STAMP/nvim-pack-lock.json" "$CONFIG/nvim/nvim-pack-lock.json"
    note "kept    ~/.config/nvim/nvim-pack-lock.json (your plugin versions)"
fi
place home/.zshrc                "$HOME/.zshrc"
for script in "$REPO"/bin/shinrai-*; do
    place "bin/$(basename -- "$script")" "$BIN/$(basename -- "$script")"
done
place wallpaper.png              "$CONFIG/shinrai/wallpaper.png"

chmod +x "$REPO"/bin/shinrai-* "$REPO"/config/hypr/scripts/*.sh 2>/dev/null || true
chmod +x "$BIN"/shinrai-* "$CONFIG"/hypr/scripts/*.sh 2>/dev/null || true

# kitty through shinrai-term in the app list too (software rendering inside a VM).
# Written here because .desktop files can't use ~ or $HOME.
mkdir -p "$DATA/applications"
KITTY_DESKTOP="$DATA/applications/kitty.desktop"
if [[ -e "$KITTY_DESKTOP" ]] && ! grep -q 'shinrai-term' "$KITTY_DESKTOP"; then
    mv -- "$KITTY_DESKTOP" "$KITTY_DESKTOP.bak-$STAMP"
fi
cat > "$KITTY_DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=kitty
GenericName=Terminal emulator
Comment=Fast, GPU-based terminal (software-rendered inside VMs)
TryExec=kitty
Exec="$BIN/shinrai-term"
Icon=kitty
Categories=System;TerminalEmulator;
StartupNotify=true
EOF
note "write   ~/.local/share/applications/kitty.desktop"

# Spotify as a native Wayland app (sharp at scale 2); inside a VM also without
# the GPU it can't use there.
SPOTIFY_CONF="$CONFIG/spotify-launcher.conf"
spotify_args='"--enable-features=UseOzonePlatform", "--ozone-platform=wayland"'
if systemd-detect-virt --quiet --vm 2>/dev/null; then
    spotify_args+=', "--disable-gpu"'
fi
if [[ -e "$SPOTIFY_CONF" ]] && ! grep -qE 'noir|shinrai' "$SPOTIFY_CONF"; then
    mv -- "$SPOTIFY_CONF" "$SPOTIFY_CONF.bak-$STAMP"
    note "backup  ~/.config/spotify-launcher.conf -> spotify-launcher.conf.bak-$STAMP"
fi
cat > "$SPOTIFY_CONF" <<EOF
# shinrai · spotify-launcher (written by install.sh; re-running it rewrites this file)
# What Spotify gets started with:  spotify-launcher -v --skip-update --no-exec
[spotify]
extra_arguments = [$spotify_args]
EOF
note "write   ~/.config/spotify-launcher.conf"

# ------------------------------------------------------------ music (Soloist)
if [[ ! -e "$SPOTIFY_ENV" ]]; then
    install -m 600 "$REPO/config/shinrai/spotify.env.example" "$SPOTIFY_ENV"
    note "write   ~/.config/shinrai/spotify.env (your Spotify keys go here)"
else
    chmod 600 "$SPOTIFY_ENV"
    note "ok      ~/.config/shinrai/spotify.env (kept as it is)"
fi

# Always a copy, even with --link: systemd treats linked unit files differently.
UNIT="$CONFIG/systemd/user/soloist.service"
mkdir -p "$(dirname -- "$UNIT")"
if [[ -e "$UNIT" || -L "$UNIT" ]] && ! cmp -s "$REPO/config/systemd/user/soloist.service" "$UNIT"; then
    mv -- "$UNIT" "$UNIT.bak-$STAMP"
    note "backup  ~/.config/systemd/user/soloist.service -> soloist.service.bak-$STAMP"
fi
rm -f -- "$UNIT"
cp -- "$REPO/config/systemd/user/soloist.service" "$UNIT"
note "copy    ~/.config/systemd/user/soloist.service"

PLAYER_RUNNING=0
if systemctl --user daemon-reload 2>/dev/null; then
    systemctl --user enable soloist.service >/dev/null 2>&1 || warn "couldn't enable soloist.service"
    if grep -Eq '^[[:space:]]*SOLOIST_API_KEY=[^[:space:]#]+' "$SPOTIFY_ENV"; then
        if systemctl --user restart soloist.service; then
            PLAYER_RUNNING=1
            note "start   soloist.service"
        else
            warn "soloist.service didn't start, see: journalctl --user -u soloist"
        fi
    fi
else
    warn "no systemd user session here; turn the player on later with: systemctl --user enable --now soloist"
fi

# ------------------------------------------------------------ login screen (SDDM)
# What you see after a reboot or log out. It lives outside your home, so this
# part needs sudo, but only when something changed.
if command -v sddm >/dev/null 2>&1; then
    THEME_DIR=/usr/share/sddm/themes/shinrai
    WALL="$CONFIG/shinrai/wallpaper.png"
    [[ -f "$WALL" ]] || WALL="$REPO/wallpaper.png"

    # The login screen can't ask Hyprland for the monitors' scale, so its
    # theme.conf gets it from here: from the running desktop, else the value
    # installed last time, else 1.
    sddm_scale=$(hyprctl monitors 2>/dev/null | awk '$1 == "scale:" { print $2 + 0; exit }' || true)
    [[ -n $sddm_scale && $sddm_scale != 0 ]] ||
        sddm_scale=$(sed -n 's/^scale=//p' "$THEME_DIR/theme.conf" 2>/dev/null || true)
    [[ -n $sddm_scale ]] || sddm_scale=1
    SDDM_STAGE=$(mktemp -d)
    cp "$REPO"/config/sddm/shinrai/* "$SDDM_STAGE/"
    sed -i "s/^scale=.*/scale=$sddm_scale/" "$SDDM_STAGE/theme.conf"

    sddm_current=1
    for f in "$SDDM_STAGE"/*; do
        cmp -s "$f" "$THEME_DIR/$(basename -- "$f")" || sddm_current=0
    done
    cmp -s "$WALL" "$THEME_DIR/background.png" || sddm_current=0
    cmp -s "$REPO/config/sddm/shinrai.conf" /etc/sddm.conf.d/shinrai.conf || sddm_current=0

    if [[ $sddm_current -eq 1 ]]; then
        note "ok      the login screen (SDDM theme, scale $sddm_scale)"
    else
        say "installing the login screen (SDDM theme, asks for sudo)"
        if sudo install -d -m 755 "$THEME_DIR" &&
           sudo install -m 644 "$SDDM_STAGE"/* "$THEME_DIR/" &&
           sudo install -m 644 "$WALL" "$THEME_DIR/background.png" &&
           sudo install -D -m 644 "$REPO/config/sddm/shinrai.conf" /etc/sddm.conf.d/shinrai.conf; then
            note "copy    $THEME_DIR (scale $sddm_scale)"
            note "copy    /etc/sddm.conf.d/shinrai.conf (picks the theme)"
        else
            warn "couldn't install the login screen theme"
        fi
    fi
    rm -rf "$SDDM_STAGE"
    if grep -Eqs '^[[:space:]]*Current=' /etc/sddm.conf && ! grep -Eqs '^[[:space:]]*Current=shinrai' /etc/sddm.conf; then
        warn "/etc/sddm.conf chooses another login theme, and it wins over shinrai.conf: delete its Current= line"
    fi
else
    note "no SDDM here, so no login screen theme"
fi

# Dark GTK apps (thunar, pavucontrol, file pickers) with the island's typeface.
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'Inter 10' 2>/dev/null || true
fi

# ------------------------------------------------------------ switch over live
# Inside a running Hyprland session the new config has already been reloaded
# (Hyprland watches the file); start the new shell so the keys work right away.
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v qs >/dev/null; then
    "$BIN/shinrai-shell" --restart -d >/dev/null 2>&1 && note "start   the shell (island + wallpaper)"
fi

# ------------------------------------------------------------ done
echo
say "done."
case ":$PATH:" in
    *":$BIN:"*) ;;
    *) warn "~/.local/bin isn't in your PATH (the shinrai-* scripts live there)" ;;
esac
if [[ "$(basename -- "${SHELL:-}")" != "zsh" ]]; then
    warn "your login shell isn't zsh. To switch:  chsh -s /usr/bin/zsh"
fi
[[ -d "$LEFTOVERS" ]] && note "the old rice's files are in $(tidy "$LEFTOVERS"); delete that folder when you don't need them"
echo
say "check the Hyprland config:   Hyprland --verify-config -c ~/.config/hypr/hyprland.lua"
say "log out and back in (or run start-hyprland from a TTY) for a clean start."
if [[ $PLAYER_RUNNING -eq 1 ]]; then
    say "music: the player is running. Super + A searches Spotify."
else
    say "music: put your Spotify keys in ~/.config/shinrai/spotify.env, then: systemctl --user restart soloist"
fi
