#!/usr/bin/env bash
# panel-text.sh <key> -- ready-made display strings for the ewwii panels.
#
# ewwii's template parser cannot group with parentheses and treats a `-`
# inside a quoted literal as subtraction, so the eww ternary strings
#   "${x == 'a' ? 'Wi-Fi is on' : 'Wi-Fi is off'}"
# cannot be ported literally.  They are resolved here instead and bound
# directly (text = global("...")).
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STS="$DIR/status.sh"

case "${1:-}" in
  nettoggle_class)
    [ "$(nmcli radio wifi 2>/dev/null)" = enabled ] \
      && printf '%s' "net-toggle enabled" || printf '%s' "net-toggle" ;;

  nettoggle_text)
    [ "$(nmcli radio wifi 2>/dev/null)" = enabled ] \
      && printf '%s' "Wi-Fi is on" || printf '%s' "Wi-Fi is off" ;;

  netnow_text)
    case "$("$STS" netmode)" in
      eth)  printf '%s' "Wired" ;;
      wifi) printf '%s' "Connected to" ;;
      *)    printf '%s' "Not connected" ;;
    esac ;;

  netnow_ssid)
    case "$("$STS" netmode)" in
      none) printf '%s' "" ;;
      *)    "$STS" netdetail ;;
    esac ;;

  batt_time_label)
    case "$("$STS" batstate)" in
      discharging) printf '%s' "Time left" ;;
      charging)    printf '%s' "Time to full" ;;
      *)           printf '%s' "Status" ;;
    esac ;;

  batt_time_mode)
    case "$("$STS" batstate)" in
      discharging) printf '%s' "Discharging" ;;
      charging)    printf '%s' "Charging" ;;
      *)           printf '%s' "Power" ;;
    esac ;;
esac
