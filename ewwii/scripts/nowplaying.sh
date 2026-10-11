#!/bin/bash
# nowplaying.sh <field> -- now-playing info for the eww bar (Omarchy style).
#
#   chip      play/pause glyph
#   text      "Title — Artist" for the bar label
#   tooltip   multi-line hover tooltip (track, artist, station/source, position)
#   visible   true while a player is running
#   state     playing | paused | stopped
#   toggle | next | prev | stop | scroll <up|down>   transport controls
#
# Sources, in order: cliamp (its IPC socket, `cliamp status --json`), then
# Spotify over MPRIS (playerctl).  Nothing running -> hidden.
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$DIR/icons.sh"
export LC_ALL=C.UTF-8
JQ=/usr/bin/jq

cliamp_json() {
    local j
    j="$(cliamp status --json 2>/dev/null)" || return 1
    printf '%s' "$j" | "$JQ" -e '.ok == true' >/dev/null 2>&1 || return 1
    printf '%s' "$j"
}

# Sets SRC plus the track fields for whichever source is running.
load() {
    local j st
    SRC=""; state=stopped; title=""; artist=""; station=""; pos=0; dur=0
    if j=$(cliamp_json); then
        SRC=cliamp
        # NB: tab-separated so spaces inside the title/artist survive.
        IFS=$'\t' read -r state title artist station pos dur < <(
            printf '%s' "$j" | "$JQ" -r '[.state // "stopped",
                                         (.track.title  // ""),
                                         (.track.artist // ""),
                                         (.station      // ""),
                                         (.position     // 0),
                                         (.duration     // 0)] | @tsv'
        )
        [ "$artist"  = "-" ] && artist=""
        [ "$station" = "-" ] && station=""
    elif st=$(playerctl -p spotify status 2>/dev/null); then
        SRC=spotify
        st=$(printf '%s' "$st" | tr 'A-Z' 'a-z')
        case "$st" in playing|paused) state=$st ;; *) state=stopped ;; esac
        title=$(playerctl -p spotify metadata xesam:title 2>/dev/null)
        artist=$(playerctl -p spotify metadata xesam:artist 2>/dev/null)
        station=Spotify
        pos=$(playerctl -p spotify position 2>/dev/null || echo 0)
        dur=$(playerctl -p spotify metadata mpris:length 2>/dev/null || echo 0)
        dur=$(awk -v u="${dur:-0}" 'BEGIN { printf "%.0f", u / 1000000 }')
    fi
}

mmss() { awk -v s="$1" 'BEGIN { if (s < 0) s = 0; printf "%d:%02d", int(s/60), int(s)%60 }'; }

load

case "$1" in
  visible) [ -n "$SRC" ] && printf 'true' || printf 'false' ;;
  state)   printf '%s' "$state" ;;
  chip)
    case "$state" in
      playing) printf '%s' "$I_PAUSE" ;;
      *)       printf '%s' "$I_PLAY"  ;;
    esac ;;
  text)
    if [ -n "$artist" ]; then t="$title — $artist"
    else                     t="$title"; fi
    # keep the label clear of the centre clock: the room left between the
    # logo/workspaces and the centre group scales with the screen width
    W=$(xdotool getdisplaygeometry 2>/dev/null | awk '{print $1}')
    max=$(( (${W:-1920} / 2 - 480) / 12 ))
    [ "$max" -gt 40 ] && max=40
    [ "$max" -lt 10 ] && max=10
    [ "${#t}" -gt "$max" ] && t="${t:0:$((max - 1))}…"
    printf '%s' "$t" ;;
  tooltip)
    line1="$title"; [ -n "$artist" ] && line1="$title — $artist"
    case "$state" in
      playing) line2="Playing" ;;
      paused)  line2="Paused"  ;;
      *)       line2="Stopped" ;;
    esac
    [ -n "$station" ] && line2="$station · $line2"
    if [ "${dur%%.*}" -gt 0 ] 2>/dev/null; then
      line2="$line2 · $(mmss "$pos") / $(mmss "$dur")"
    fi
    printf '%s\n%s' "$line1" "$line2" ;;
  toggle)
    case "$SRC" in
      cliamp)  cliamp toggle >/dev/null 2>&1 ;;
      spotify) playerctl -p spotify play-pause >/dev/null 2>&1 ;;
    esac ;;
  next)
    case "$SRC" in
      cliamp)  cliamp next >/dev/null 2>&1 ;;
      spotify) playerctl -p spotify next >/dev/null 2>&1 ;;
    esac ;;
  prev)
    case "$SRC" in
      cliamp)  cliamp prev >/dev/null 2>&1 ;;
      spotify) playerctl -p spotify previous >/dev/null 2>&1 ;;
    esac ;;
  stop)
    case "$SRC" in
      cliamp)  cliamp stop >/dev/null 2>&1 ;;
      spotify) playerctl -p spotify stop >/dev/null 2>&1 ;;
    esac ;;
  scroll)
    case "$2" in
      up)   "$0" next ;;
      down) "$0" prev ;;
    esac ;;
  *) : ;;
esac
exit 0
