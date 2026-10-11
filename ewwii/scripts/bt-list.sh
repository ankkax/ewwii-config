#!/bin/bash
# bt-list.sh -- JSON list of known Bluetooth devices for the ewwii Bluetooth panel.
#
# Each element: { name, mac, connected, battery, glyph, check, esc }
#   connected : true/false
#   battery   : "85%" or "" when the device does not report it
#   glyph     : Nerd Font icon (connected devices get the "connected" icon)
#   check     : a trailing tick for the device that is currently connected
#   esc       : the MAC address, safe to splice into an onclick string
#
# Connected devices sort first, then alphabetically by name.

DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$DIR/icons.sh"

command -v bluetoothctl >/dev/null 2>&1 || { printf '[]'; exit 0; }

tmp=$(mktemp)
devs=$(mktemp)
trap 'rm -f "$tmp" "$devs"' EXIT

bluetoothctl devices 2>/dev/null \
  | sed -n 's/^Device \([0-9A-Fa-f:]\{17\}\) \(.*\)$/\1\t\2/p' > "$devs"

while IFS=$'\t' read -r mac name; do
  [ -n "$mac" ] || continue
  info=$(bluetoothctl info "$mac" 2>/dev/null)
  if grep -q 'Connected: yes' <<<"$info"; then
    conn=true; sk=0; check="✓"; glyph="$I_BT_CONNECTED"
  else
    conn=false; sk=1; check=""; glyph="$I_BT"
  fi
  batt=$(sed -n 's/.*Battery Percentage:.*(\([0-9]\+\)).*/\1%/p' <<<"$info" | head -1)
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$sk" "$mac" "$name" "$conn" "$batt" "$glyph" "$check" >> "$tmp"
done < "$devs"

jq -R -s '
  split("\n")
  | map(select(length > 0) | split("\t"))
  | map({
      sk: (.[0] | tonumber),
      mac: .[1],
      name: .[2],
      connected: (.[3] == "true"),
      battery: .[4],
      glyph: .[5],
      check: .[6]
    })
  | sort_by(.sk, (.name | ascii_downcase))
  | map({ name, mac, connected, battery, glyph, check, esc: .mac })
' "$tmp"
