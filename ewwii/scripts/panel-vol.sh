#!/usr/bin/env bash
# panel-vol.sh -- volume actions for the eww audio panel.
#   panel-vol.sh set <0-100>   (from the slider :onchange)
#   panel-vol.sh mute
#   panel-vol.sh up | down
#   panel-vol.sh mixer         (open pulsemixer in a floating kitty)
EWW="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)/ewp"   # panels/OSD daemon

clamp() {
  local v=${1%.*}
  case "$v" in ''|*[!0-9]*) v=0 ;; esac
  [ "$v" -lt 0 ]   && v=0
  [ "$v" -gt 100 ] && v=100
  printf '%s' "$v"
}

case "${1:-}" in
  set)
    v=$(clamp "${2:-0}")
    pamixer --set-volume "$v" >/dev/null 2>&1
    $EWW update "vol_level=\"$v\"" >/dev/null 2>&1
    ;;
  mute)
    pamixer -t >/dev/null 2>&1
    ;;
  up)    pamixer -i 5 >/dev/null 2>&1 ;;
  down)  pamixer -d 5 >/dev/null 2>&1 ;;
  mixer) setsid -f kitty --class pulsemixer -e pulsemixer >/dev/null 2>&1 ;;
esac
