#!/bin/bash
# bt-text.sh <key> -- display strings for the Bluetooth panel + bar.
#
#   toggle_class  "bt-toggle enabled" when the radio is on, else "bt-toggle"
#   toggle_text   "Bluetooth is on" / "Bluetooth is off"
#   state         "true" / "false"  (radio powered)

pwr=$(bluetoothctl show 2>/dev/null \
      | sed -n 's/^[[:space:]]*Powered: \(yes\|no\).*/\1/p' | head -1)

case "${1:-}" in
  toggle_class) [ "$pwr" = yes ] && printf '%s' "bt-toggle enabled" || printf '%s' "bt-toggle" ;;
  toggle_text)  [ "$pwr" = yes ] && printf '%s' "Bluetooth is on"  || printf '%s' "Bluetooth is off" ;;
  state)        [ "$pwr" = yes ] && printf '%s' "true" || printf '%s' "false" ;;
esac
