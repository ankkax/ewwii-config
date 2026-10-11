#!/bin/bash
# updates-watch.sh -- keep a cached count of pending pacman updates for the
# eww "system-update" widget (Omarchy shows a badge only when updates wait).
#
# Polls every 6h (Omarchy parity).  The loop sleeps in short chunks and
# schedules against CLOCK_REALTIME (date +%s) rather than one long `sleep`,
# because `sleep` uses CLOCK_MONOTONIC which stops while the machine is
# suspended -- on a laptop that suspends overnight a single 6h sleep would
# otherwise not fire for many extra hours after waking.
#
# checkupdates exit codes: 0 = updates available, 2 = up to date, anything
# else = error.  On error the previous cache is kept, so a brief network
# outage (e.g. in the seconds right after a resume) does not hide the badge.

cache="$HOME/.cache/eww/updates"
mkdir -p "$(dirname "$cache")"

# Single instance per user.
lock="${XDG_RUNTIME_DIR:-/tmp}/eww-updates-watch.lock"
exec 9>"$lock" 2>/dev/null
flock -n 9 2>/dev/null || exit 0

INTERVAL=21600   # 6h, matching Omarchy's update poll
CHUNK=60         # re-check the schedule at least this often, so a resume
                 # triggers an overdue check within a minute
last=0
while true; do
  now=$(date +%s)
  if [ $((now - last)) -ge "$INTERVAL" ]; then
    out=$(checkupdates 2>/dev/null 9>&-); rc=$?
    case "$rc" in
      0) printf '%s\n' "$out" | grep -c . > "$cache" ;;   # updates pending
      2) echo 0 > "$cache" ;;                              # up to date
      *) : ;;                                              # error: keep cache
    esac
    last=$(date +%s)
  fi
  sleep "$CHUNK" 9>&-
done
