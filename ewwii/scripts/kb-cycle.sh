#!/bin/bash
# kb-cycle.sh -- cycle configured keyboard layouts (Omarchy keyboard-layout widget).
# No-op unless more than one layout is configured (e.g. "us,fi").

layouts=$(setxkbmap -query 2>/dev/null | awk '/^layout:/{print $2}')
case "$layouts" in
  ""|*,*) : ;;
  *) exit 0 ;;   # only one layout -> nothing to cycle
esac

IFS=',' read -r -a all <<< "$layouts"
# Track the position in a cache file, since setxkbmap cannot report the group.
cache="$HOME/.cache/eww-kb-index"
i=$(cat "$cache" 2>/dev/null || echo 0)
i=$(( (i + 1) % ${#all[@]} ))
echo "$i" > "$cache"
sel="${all[$i]}"
setxkbmap -layout "$sel" >/dev/null 2>&1
