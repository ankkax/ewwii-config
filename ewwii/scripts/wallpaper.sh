#!/bin/bash
# wallpaper.sh [file|next|prev] -- set/cycle the desktop wallpaper.
# Defaults to the Omarchy tokyo-night set downloaded under
# ~/Pictures/omarchy-tokyo-night/jpg/ (Omarchy themes ship several and cycle).

dir="$HOME/Pictures/omarchy-tokyo-night/jpg"
[ -d "$dir" ] || dir="$HOME/Pictures/omarchy-tokyo-night"

set_wall() {
  xwallpaper --maximize "$1" 2>/dev/null
  echo "$1" > "$HOME/.cache/eww-wallpaper"
}

case "$1" in
  next|prev|"")
    mapfile -t list < <(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' \) | sort)
    [ "${#list[@]}" -gt 0 ] || { echo "wallpaper.sh: no wallpapers in $dir" >&2; exit 1; }
    cur=$(cat "$HOME/.cache/eww-wallpaper" 2>/dev/null)
    idx=0
    for i in "${!list[@]}"; do [ "${list[$i]}" = "$cur" ] && idx=$i; done
    if [ "$1" = prev ]; then idx=$(( (idx - 1 + ${#list[@]}) % ${#list[@]} ))
    else                     idx=$(( (idx + 1) % ${#list[@]} )); fi
    set_wall "${list[$idx]}" ;;
  *)
    [ -f "$1" ] && set_wall "$1" || { echo "wallpaper.sh: no such file: $1" >&2; exit 1; } ;;
esac
