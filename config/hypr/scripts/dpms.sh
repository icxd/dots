#!/bin/sh
# dpms.sh on | off — turn every monitor on or off (hypridle calls this).
# A script because hypridle's config can't hold the { } of a Lua dispatcher.
case "$1" in
    on)  hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' ;;
    off) hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })' ;;
    *)   echo "usage: dpms.sh on|off" >&2; exit 1 ;;
esac
