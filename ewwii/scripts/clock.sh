#!/bin/bash
# clock.sh -- eww bar clock. Alternates format like Omarchy's format/format-alt.
mode=$(cat "$HOME/.cache/eww-clock-mode" 2>/dev/null || echo 0)
case "$mode" in
  1) date '+%d %B W%V %Y' ;;
  *) date '+%A %H:%M' ;;
esac
