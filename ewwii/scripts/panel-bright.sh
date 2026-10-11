#!/usr/bin/env bash
# panel-bright.sh -- brightness action for the eww display panel.
#   panel-bright.sh set <0-100>   (from the slider :onchange)
EWW="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)/ewp"   # panels/OSD daemon

v=${2:-}
case "$v" in ''|*[!0-9.]*) exit 0 ;; esac
v=${v%.*}
[ "$v" -lt 1 ]   && v=1
[ "$v" -gt 100 ] && v=100

case "${1:-}" in
  set)
    brightnessctl set "${v}%" >/dev/null 2>&1
    $EWW update "bright_level=\"$v\"" >/dev/null 2>&1
    ;;
esac
