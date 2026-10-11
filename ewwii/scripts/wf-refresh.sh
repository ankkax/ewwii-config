#!/bin/bash
# wf-refresh.sh -- force a weather refresh and push the new values to ewwii.
# Used by the "Refresh" button in the native weather panel.

DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
EWW=/usr/bin/ewwii       # bar daemon
EWP="$DIR/ewp"           # panels daemon

# drop the cache so wfcast.sh re-fetches
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/eww-wfcast.json"

now=$("$DIR/weather.sh")
txt=$("$DIR/weather.sh" text)
d1=$("$DIR/wfcast.sh" d1)
d2=$("$DIR/wfcast.sh" d2)
d3=$("$DIR/wfcast.sh" d3)

"$EWW" update "weather=$now" >/dev/null 2>&1
"$EWP" update "weather=$now,wfc=$txt,wfd1=$d1,wfd2=$d2,wfd3=$d3" >/dev/null 2>&1
