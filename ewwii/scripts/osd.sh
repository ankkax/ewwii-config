#!/bin/bash
# osd.sh -- Omarchy-style on-screen display (eww) for volume & brightness.
#
# Mirrors Omarchy's Quickshell OSD plugin: a bottom-centre card with an icon,
# a progress bar and a percentage readout, shown for ~1.2s.
#
# Usage:
#   osd.sh vol    up|down|mute|set <0-100>     # discrete: media keys, clicks
#   osd.sh bright up|down|set <0-100>%         # discrete: media keys, clicks
#   osd.sh scroll vol    up|down               # wheel/touchpad on the bar
#   osd.sh scroll bright up|down
#   osd.sh show   -i <icon> -p <0-100> [-d <ms>]
#
# A wheel/touchpad streams scroll events far faster than the volume should
# change. eww runs `:onscroll` fire-and-forget, so a burst spawns many
# concurrent copies of this script; `scroll` therefore takes a non-blocking
# lock and coalesces them -- the first event applies, the rest are dropped --
# and holds the slot for THROTTLE_MS to bound the change rate.

EWW="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)/ewp"   # panels/OSD daemon
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$DIR/icons.sh"

BAR_W=142           # must match the :width of the OSD bar in eww.yuck
DEFAULT_MS=1200     # how long the card stays up after the last change

STEP_KEY=5          # percent per media-key press / click
STEP_SCROLL=4       # percent per applied scroll notch (tune for feel)
THROTTLE_MS=80      # minimum time between applied scroll changes

RT="${XDG_RUNTIME_DIR:-/tmp}"
GEN_FILE="$RT/eww-osd.gen"     # generation counter for the hide timer
TIME_FILE="$RT/eww-osd.time"   # timestamp of the last arm (staleness check)
OPEN_FILE="$RT/eww-osd.open"   # marker dir: the OSD window is currently mapped
LOCK_FILE="$RT/eww-osd.lock"   # serialises scroll handling

# -- helpers ----------------------------------------------------------------
# Milliseconds since the epoch, without forking. EPOCHREALTIME uses the locale
# decimal separator (a comma under fi_FI), so strip either before the maths.
now_ms() { local t=${EPOCHREALTIME/[.,]/}; printf '%s' "$(( t / 1000 ))"; }

seconds() { printf '%d.%03d' $(( $1 / 1000 )) $(( $1 % 1000 )); }

# (Re)arm the hide timer. A newer show bumps the generation, so older timers
# become no-ops and a fast burst keeps the card up instead of flickering shut.
arm_timer() {
    local ms="$1" gen
    printf '%s' "$(now_ms)" > "$TIME_FILE" 2>/dev/null
    gen=$(( $(cat "$GEN_FILE" 2>/dev/null || echo 0) + 1 ))
    printf '%s' "$gen" > "$GEN_FILE" 2>/dev/null
    (
        sleep "$(seconds "$ms")"
        if [ "$(cat "$GEN_FILE" 2>/dev/null)" = "$gen" ]; then
            "$EWW" close osd >/dev/null 2>&1
            rmdir "$OPEN_FILE" 2>/dev/null
        fi
    ) &
}

# -- paint ------------------------------------------------------------------
# Set the card contents and map the window on the first change of a burst.
paint_osd() {
    local icon="$1" pct="$2" fill now last

    case "$pct" in ''|*[!0-9]*) pct=0 ;; esac
    [ "$pct" -gt 100 ] && pct=100
    fill=$(( pct * BAR_W / 100 ))

    "$EWW" update "osd_icon=\"$icon\",osd_pct=\"${pct}%\",osd_fill=\"$fill\"" \
        >/dev/null 2>&1

    # Map the window at most once per burst. `mkdir` is atomic, so concurrent
    # scroll events cannot race, and re-opening a mapped window makes eww
    # destroy+recreate it (a visible flicker). If a marker was left behind by
    # an external close (e.g. `eww reload`), drop it once it looks abandoned.
    if [ -d "$OPEN_FILE" ]; then
        now=$(now_ms); read -r last < "$TIME_FILE" 2>/dev/null; last=${last:-0}
        [ $(( now - last )) -gt 2500 ] && rmdir "$OPEN_FILE" 2>/dev/null
    fi
    if mkdir "$OPEN_FILE" 2>/dev/null; then
        "$EWW" open osd >/dev/null 2>&1
    fi
}

show_osd() { paint_osd "$1" "$2"; arm_timer "${3:-$DEFAULT_MS}"; }

# -- volume -----------------------------------------------------------------
render_volume() {
    local v m a b icon
    read -r a b <<<"$(pamixer --get-volume --get-mute 2>/dev/null)"
    case "$a" in
        true|false) m="$a"; v="$b" ;;
        *)          v="$a"; m="$b" ;;
    esac
    [ -z "$v" ] && v=0
    if [ "$m" = "true" ] || [ "$v" -eq 0 ]; then icon="$I_VOL_MUTE"
    elif [ "$v" -le 33 ];                then icon="$I_VOL_LOW"
    else                                      icon="$I_VOL_UP"; fi
    paint_osd "$icon" "$v"
}

volume() {          # media keys / clicks
    case "$1" in
        up)   pamixer -i "$STEP_KEY" -u    >/dev/null 2>&1 ;;
        down) pamixer -d "$STEP_KEY" -u    >/dev/null 2>&1 ;;
        mute) pamixer -t                   >/dev/null 2>&1 ;;
        set)  pamixer --set-volume "$2" -u >/dev/null 2>&1 ;;
    esac
    render_volume
    arm_timer "$DEFAULT_MS"
}

# -- brightness -------------------------------------------------------------
render_brightness() {
    local p
    p=$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/[^0-9]/,"",$4); print $4}')
    [ -z "$p" ] && p=0
    paint_osd "$I_BRIGHT" "$p"
}

brightness() {      # media keys / clicks
    case "$1" in
        up)   brightnessctl set "+${STEP_KEY}%"  >/dev/null 2>&1 ;;
        down) brightnessctl set "${STEP_KEY}%-"  >/dev/null 2>&1 ;;
        max)  brightnessctl set 100%            >/dev/null 2>&1 ;;
        min)  brightnessctl set 1%              >/dev/null 2>&1 ;;
        set)  brightnessctl set "$2"            >/dev/null 2>&1 ;;
    esac
    render_brightness
    arm_timer "$DEFAULT_MS"
}

# -- scroll (coalesced) -----------------------------------------------------
# Only one scroll change runs at a time; events that arrive while the slot is
# open are dropped. This bounds the rate to roughly one change per THROTTLE_MS
# however fast the touchpad streams events.
run_scroll() {
    local kind="$1" dir="$2" t0 dt
    (
        flock -n 9 || exit 1        # lock held -> coalesced, nothing applied

        t0=$(now_ms)
        case "$kind" in
            vol)
                if [ "$dir" = up ]; then
                    pamixer -i "$STEP_SCROLL" -u >/dev/null 2>&1
                else
                    pamixer -d "$STEP_SCROLL" -u >/dev/null 2>&1
                fi
                render_volume ;;
            bright)
                if [ "$dir" = up ]; then
                    brightnessctl set "+${STEP_SCROLL}%" >/dev/null 2>&1
                else
                    brightnessctl set "${STEP_SCROLL}%-" >/dev/null 2>&1
                fi
                render_brightness ;;
        esac

        # Keep the slot closed for the remainder of THROTTLE_MS.
        dt=$(( $(now_ms) - t0 ))
        [ "$dt" -lt "$THROTTLE_MS" ] && sleep "$(seconds $(( THROTTLE_MS - dt )))"

        exit 0
    ) 9>"$LOCK_FILE"

    # Arm the hide timer only if this event actually applied a change. Done
    # outside the locking subshell so the timer never inherits the lock.
    [ $? -eq 0 ] && arm_timer "$DEFAULT_MS"
}

# -- CLI --------------------------------------------------------------------
case "$1" in
    vol)    shift; volume "$@" ;;
    bright) shift; brightness "$@" ;;
    scroll)
        shift
        case "$1" in
            vol|bright) run_scroll "$@" ;;
        esac ;;
    show)
        shift
        icon="" pct="" ms="$DEFAULT_MS"
        while [ $# -gt 0 ]; do
            case "$1" in
                -i|--icon)     icon="$2"; shift 2 ;;
                -p|--progress) pct="$2";  shift 2 ;;
                -d|--duration) ms="$2";   shift 2 ;;
                *) shift ;;
            esac
        done
        show_osd "$icon" "${pct:-0}" "$ms"
        ;;
    *)
        echo "usage: osd.sh vol up|down|mute|set N | bright up|down|set N% | scroll vol|bright up|down | show -i ICON -p N [ -d MS]" >&2
        exit 2 ;;
esac
