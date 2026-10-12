#!/bin/bash
# gamepad.sh state | icon | toggle -- controller Home button mode.
#
# "Off" (default): Home switches to tty2 (switch-to-tty2).
# "On" (desktop mode): the controller is a plain gamepad, Home does nothing.
# The state is a file; home-button reads it on every press.

STATE_FILE="$HOME/.local/state/gamepad-desktop"
ON_GLYPH=$'\U000f0297'   # md-gamepad_variant

is_on() {
    [ -e "$STATE_FILE" ]
}

case "$1" in
    state)
        if is_on; then echo on; else echo off; fi ;;
    icon)
        printf '%s' "$ON_GLYPH" ;;
    toggle)
        mkdir -p "$(dirname "$STATE_FILE")"
        if is_on; then rm -f "$STATE_FILE"; else : > "$STATE_FILE"; fi
        if is_on; then st=on; else st=off; fi
        # push the new state straight away so the bar does not wait for the poll
        /usr/bin/ewwii update "gamepad_state=\"$st\"" >/dev/null 2>&1 ;;
    *)
        echo "usage: gamepad.sh state|icon|toggle" >&2; exit 2 ;;
esac
