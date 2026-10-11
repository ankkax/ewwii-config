#!/bin/bash
# set-theme.sh [name|menu|--list] -- switch the eww bar palette and reload.
#
#   set-theme.sh              -> list available themes
#   set-theme.sh menu         -> pick one with rofi
#   set-theme.sh tokyo-night  -> apply a theme

ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
THEMES="$ROOT/themes"

list() { ls "$THEMES" 2>/dev/null | sed 's/\.scss$//'; }

case "$1" in
  ""|-l|--list)
    list; exit 0 ;;
  menu)
    sel=$(list | rofi -dmenu -p "eww theme")
    [ -n "$sel" ] || exit 0
    exec "$0" "$sel" ;;
esac

src="$THEMES/$1.scss"
[ -f "$src" ] || { echo "set-theme: unknown theme '$1' (try: $(list | tr '\n' ' '))" >&2; exit 1; }

cp "$src" "$ROOT/theme.scss"
echo "$1" > "$HOME/.cache/eww-theme"

# eww watches its config files and auto-reloads when theme.scss changes, so no
# explicit `eww reload` is needed.  Issuing one here races that auto-reload
# (two reloads in quick succession) and segfaults the daemon in
# libdbusmenu-gtk3 during systray teardown -- so deliberately not reloading.
notify-send -a eww "Bar theme" "$1" 2>/dev/null
