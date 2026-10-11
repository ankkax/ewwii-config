#!/bin/bash
# ws_scroll.sh <up|down> -- step one workspace per wheel burst.
# A flick sends many wheel events; a burst (events less than GAP_MS apart)
# counts as one step, and steps are at least COOLDOWN_MS apart.
STATE="${XDG_RUNTIME_DIR:-/tmp}/ewwii-ws-scroll.state"
GAP_MS=150
COOLDOWN_MS=400

[ -z "$1" ] && exit 0

NOW=$(date +%s%3N)
[ -f "$STATE" ] && read -r LAST_SEEN LAST_STEP < "$STATE"
LAST_SEEN=${LAST_SEEN:-0}
LAST_STEP=${LAST_STEP:-0}

echo "$NOW $LAST_STEP" > "$STATE"
[ $((NOW - LAST_SEEN)) -lt "$GAP_MS" ] && exit 0
[ $((NOW - LAST_STEP)) -lt "$COOLDOWN_MS" ] && exit 0

echo "$NOW $NOW" > "$STATE"
case "$1" in
  up)   xdotool set_desktop --relative 1 ;;
  down) xdotool set_desktop --relative -- -1 ;;
esac
