#!/bin/bash
# caffeine.sh state | icon | toggle -- keep the screen awake, using only xset.
#
# "On" = screen blanking and DPMS disabled (screensaver timeout 0).  "Off"
# restores the usual 600 s blanking and DPMS.

ON_GLYPH=$'\U000f0176'    # md-coffee
OFF_GLYPH=$'\U000f04b2'   # md-sleep

is_on() {
    xset q 2>/dev/null | awk '/timeout:/{print $2; exit}' | grep -q '^0$'
}

case "$1" in
    state)
        if is_on; then echo on; else echo off; fi ;;
    icon)
        if is_on; then printf '%s' "$ON_GLYPH"; else printf '%s' "$OFF_GLYPH"; fi ;;
    toggle)
        if is_on; then
            xset s 600 600
            xset +dpms
            xset s on
        else
            xset s off
            xset -dpms
            # undo an idle dim that is already on
            "$HOME/.config/oxwm/scripts/screentemp.sh" --resume >/dev/null 2>&1
        fi
        # push the new state straight away so the bar does not wait for the poll
        if is_on; then st=on; else st=off; fi
        if is_on; then gl=$ON_GLYPH; else gl=$OFF_GLYPH; fi
        /usr/bin/ewwii update "caffeine_state=\"$st\",caffeine_icon=\"$gl\"" >/dev/null 2>&1 ;;
    *)
        echo "usage: caffeine.sh state|icon|toggle" >&2; exit 2 ;;
esac
