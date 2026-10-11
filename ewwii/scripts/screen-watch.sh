#!/bin/bash
# screen-watch.sh -- reopen the bar when the screen size changes.
#
# The bar window is sized when it opens, so a resolution change or a monitor
# being plugged in or out leaves it at the old width.  Polling the display
# size every few seconds is cheap, and closing and reopening the bar fixes it.

EWW=/usr/bin/ewwii
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/ewwii-screen-watch.lock" 2>/dev/null
flock -n 9 2>/dev/null || exit 0

last=$(xdotool getdisplaygeometry 2>/dev/null)
while true; do
    sleep 3 9>&-
    cur=$(xdotool getdisplaygeometry 2>/dev/null)
    [ -n "$cur" ] || continue
    if [ "$cur" != "$last" ]; then
        last=$cur
        sleep 1
        "$DIR/ewp" close-all >/dev/null 2>&1
        "$EWW" close-all >/dev/null 2>&1
        "$EWW" open bar >/dev/null 2>&1
    fi
done
