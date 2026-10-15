#!/bin/bash
# tags-watch.sh -- push OXWM workspace (tag) state + label into the ewwii bar.
#
# Event-driven: `xprop -spy` reports changes to the root properties oxwm
# publishes, so the bar updates the moment a workspace changes.  Requires the
# oxwm-ewmh build, which publishes:
#   _NET_CURRENT_DESKTOP   selected tag (0-based)
#   _OXWM_OCCUPIED_TAGS    bitmask of tags with at least one managed window
#                          (docks such as this bar are excluded by oxwm)
#
# Per tag it sets:
#   wsN  = current | occupied | vacant     (styling)
#   wsNl = the glyph/number to show        (active tag shows Omarchy's square)
#
# The Omarchy-style centre widgets (update badge, keyboard layout) change
# rarely, so they are refreshed every ~2s; everything is re-sent every ~5s so a
# bar reload cannot leave stale values behind.

DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$DIR/icons.sh"

EWW=/usr/bin/ewwii
STS="$DIR/status.sh"
TAGS=9

command -v xprop >/dev/null 2>&1 || exit 0
[ -x "$EWW" ] || exit 0

# Single instance per *login*: XAUTHORITY is a fresh file for every login, so
# a stale watcher left behind by a previous session can never block this one.
disp="${DISPLAY//:/_}"
sess="${XAUTHORITY:-nosession}"; sess="${sess##*/}"
lock="${XDG_RUNTIME_DIR:-/tmp}/oxwm-tags-watch${disp}-${sess}.lock"
exec 9>"$lock" 2>/dev/null
flock -n 9 2>/dev/null || exit 0

declare -A prev=()

read_prop() {
    local v
    v=$(xprop -root "$1" 2>/dev/null | sed -n 's/.*= *//p')
    [[ "$v" =~ ^[0-9]+$ ]] || v=0
    printf '%s' "$v"
}

# Build key=value pairs for the workspace widgets from the two root properties.
ws_args() {
    local cur occ i
    cur=$(read_prop _NET_CURRENT_DESKTOP)
    occ=$(read_prop _OXWM_OCCUPIED_TAGS)
    args=()
    for ((i = 0; i < TAGS; i++)); do
        if   [ "$i" = "$cur" ];              then s=current;  l="$I_WS_ACTIVE"
        elif (( (occ >> i) & 1 ));           then s=occupied; l="$((i + 1))"
        else                                      s=vacant;   l="$((i + 1))"
        fi
        args+=("ws$i=$s" "ws${i}l=$l")
    done
}

# Centre widgets: the keyboard-layout indicator.
centre_args() {
    args+=("kblstate=$("$STS" kbstate)")
}

# Push only the values that changed since the last push.
push() {
    local kv k val payload=""
    local -a diff=()
    for kv in "${args[@]}"; do
        k="${kv%%=*}"
        if [ "${prev[$k]:-}" != "${kv#*=}" ]; then
            diff+=("$kv")
            prev[$k]="${kv#*=}"
        fi
    done
    [ "${#diff[@]}" -gt 0 ] || return 0
    for kv in "${diff[@]}"; do
        k="${kv%%=*}"; val="${kv#*=}"
        [ -n "$payload" ] && payload="$payload,"
        payload="$payload${k}=\"${val}\""
    done
    "$EWW" update "$payload" >/dev/null 2>&1
}

refresh() {
    ws_args
    push
}

# Full re-send: forget what was pushed so every value goes out again.
resync() {
    prev=()
    ws_args
    centre_args
    push
}

resync

exec 8< <(xprop -root -spy _NET_CURRENT_DESKTOP _OXWM_OCCUPIED_TAGS 2>/dev/null 9>&-)

tick=0
while true; do
    IFS= read -r -t 1 -u 8 _
    rc=$?
    if [ "$rc" -eq 0 ]; then
        refresh
        continue
    fi
    # Exit 1 is EOF: xprop exited, so the X server (and this session) is gone.
    # Exit >128 is the 1-second timeout.
    [ "$rc" -ne 0 ] && [ "$rc" -le 128 ] && exit 0

    tick=$((tick + 1))
    if [ $((tick % 2)) -eq 0 ]; then
        args=(); centre_args; push
    fi
    if [ $((tick % 5)) -eq 0 ]; then
        resync
    fi
done
