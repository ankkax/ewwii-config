#!/bin/bash
# bright.sh -- display brightness for the bar, OSD and panel.
#
#   bright.sh pct          print the current brightness percentage
#   bright.sh step +N|-N   change brightness by N percent (saved)
#   bright.sh set N        set brightness to N percent (0-100)
#
# Laptop (battery present): the panel backlight, through brightnessctl.
# Desktop: software brightness through screentemp.sh (xrandr), so the level
# the bar shows is the same one --resume, --dim and the idle timers use.

SCREENTEMP="$HOME/.config/oxwm/scripts/screentemp.sh"
DIM_FLAG=/tmp/screentemp.dim

is_laptop() {
    local b
    for b in /sys/class/power_supply/BAT*; do [ -r "$b/capacity" ] && return 0; done
    return 1
}

pct() {
    if is_laptop; then
        brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'
    else
        "$SCREENTEMP" --status 2>/dev/null | awk '{ gsub(/%/, "", $2); print $2 }'
    fi
}

step() {
    local d="$1" n
    n=${d#[+-]}
    if is_laptop; then
        brightnessctl set "${d:0:1}${n}%" >/dev/null 2>&1
    else
        "$SCREENTEMP" --brightness "${d:0:1}${n}" >/dev/null 2>&1
    fi
}

set_abs() {
    local target="$1" cur delta
    case "$target" in ''|*[!0-9]*) return 1 ;; esac
    [ "$target" -lt 1 ] && target=1
    [ "$target" -gt 100 ] && target=100
    if is_laptop; then
        brightnessctl set "${target}%" >/dev/null 2>&1
        return
    fi
    cur=$(pct); cur=${cur:-$target}
    delta=$(( target - cur ))
    [ "$delta" -eq 0 ] && return
    if [ "$delta" -gt 0 ]; then step "+$delta"; else step "$delta"; fi
}

icon() {
    local p
    if [ -f "$DIM_FLAG" ]; then printf '%s' $'\U000f00dd'; return; fi   # moon: dimmed by idle
    p=$(pct | tr -dc '0-9'); p=${p:-0}
    if [ "$p" -le 30 ];   then printf '%s' $'\U000f00de'                # low
    elif [ "$p" -le 60 ]; then printf '%s' $'\U000f00df'                # medium
    else                       printf '%s' $'\U000f00e0'; fi            # high
}

case "${1:-}" in
    pct)  pct ;;
    icon) icon ;;
    step) step "${2:?usage: bright.sh step +N|-N}" ;;
    set)  set_abs "${2:?usage: bright.sh set N}" ;;
    *)    echo "usage: bright.sh pct | icon | step +N|-N | set N" >&2; exit 2 ;;
esac
