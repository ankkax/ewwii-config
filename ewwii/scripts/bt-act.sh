#!/bin/bash
# bt-act.sh -- Bluetooth actions for the ewwii bar and panel.
#
# Usage:
#   bt-act.sh toggle-power                 # radio on/off (right-click on the bar)
#   bt-act.sh connect <mac>                # connect a device
#   bt-act.sh disconnect <mac>             # disconnect a device
#   bt-act.sh scan                         # discover for a few seconds

case "${1:-}" in
  toggle-power)
    if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
      bluetoothctl power off >/dev/null 2>&1
    else
      bluetoothctl power on  >/dev/null 2>&1
    fi
    ;;
  connect)    [ -n "${2:-}" ] && bluetoothctl connect    "$2" >/dev/null 2>&1 ;;
  disconnect) [ -n "${2:-}" ] && bluetoothctl disconnect "$2" >/dev/null 2>&1 ;;
  scan)       bluetoothctl --timeout 8 scan on >/dev/null 2>&1 ;;
  *)
    echo "usage: bt-act.sh {toggle-power|connect <mac>|disconnect <mac>|scan}" >&2
    exit 2 ;;
esac
