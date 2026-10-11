#!/bin/bash
# session-start.sh -- start the ewwii bar, the panels daemon and the watchers.
#
# Called once from oxwm autostart.  The bar has its own small config
# (~/.config/ewwii) so its daemon is ready quickly; the pop-up panels and OSD
# live in a second daemon (~/.config/ewwii-panels) that loads afterwards.

EWW=/usr/bin/ewwii
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

if ! "$EWW" ping >/dev/null 2>&1; then
    setsid "$EWW" daemon >/dev/null 2>&1 </dev/null &
fi

for _ in $(seq 1 100); do
    "$EWW" ping >/dev/null 2>&1 && break
    sleep 0.05
done

for _ in 1 2 3 4 5; do
    "$EWW" open bar >/dev/null 2>&1
    "$EWW" active-windows 2>/dev/null | grep -q '^bar:' && break
    sleep 0.3
done

# panels / OSD daemon: started after the bar is up
"$DIR/ewp" ping >/dev/null 2>&1 || setsid "$DIR/ewp" daemon >/dev/null 2>&1 </dev/null &

setsid "$DIR/tags-watch.sh" >/dev/null 2>&1 </dev/null &
setsid "$DIR/screen-watch.sh" >/dev/null 2>&1 </dev/null &
