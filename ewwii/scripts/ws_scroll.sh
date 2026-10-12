#!/bin/bash
# ws_scroll.sh <up|down> -- one workspace per wheel step, like the old eww bar:
# scroll up goes to the previous workspace, down to the next (wrapping around).
# Steps that arrive during COOLDOWN are dropped; the lock keeps this safe when
# ewwii runs several copies at once. Other directions (left/right) are ignored.
COOLDOWN=0.08
LOCK="${XDG_RUNTIME_DIR:-/tmp}/ewwii-ws-scroll.lock"

desk() { xprop -root _NET_CURRENT_DESKTOP 2>/dev/null | sed 's/.*= //'; }

case "$1" in
  up)   step=-1 ;;
  down) step=1 ;;
  *)    exit 0 ;;
esac

exec 9>"$LOCK"
flock -n 9 || exit 0
xdotool set_desktop --relative -- "$step"
sleep "$COOLDOWN"
