#!/bin/bash
# clock-cycle.sh -- toggle the eww clock between its two formats.
f="$HOME/.cache/eww-clock-mode"
mode=$(cat "$f" 2>/dev/null || echo 0)
echo $(( (mode + 1) % 2 )) > "$f"
