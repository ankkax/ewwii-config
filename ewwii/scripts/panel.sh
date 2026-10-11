#!/usr/bin/env bash
# panel.sh -- open/close/toggle the eww bar pop-up panels.
#
# A full-screen, fully transparent backdrop ("popback") is mapped *behind* the
# panels and closes them when it is clicked (click-outside, like Omarchy). Only
# one panel is ever open at a time.
#
# picom excludes the backdrop from blur (see picom.conf) so it cannot smear the
# desktop; the cards themselves keep the frosted look.
#
# Usage:
#   panel.sh open   <vol|bright|net|power|bt|cal>
#   panel.sh toggle <vol|bright|net|power|bt|cal>
#   panel.sh close

EWW="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)/ewp"   # panels/OSD daemon
PANELS="panel-vol panel-bright panel-net panel-power panel-bt panel-cal panel-weather"
BACKDROP=popback

close_all() {
  # Only close the panels that are actually open, so ewwii doesn't log
  # "no such window was open" every time.  ewwii prints "<id>: <name>".
  local open w
  open=$($EWW active-windows 2>/dev/null | awk -F': ' '{print $2}' | tr '\n' ' ')
  for w in $BACKDROP $PANELS; do
    case " $open " in *" $w "*) $EWW close "$w" >/dev/null 2>&1 ;; esac
  done
}

case "${1:-}" in
  open|toggle)
    name="panel-${2:-}"
    case " $PANELS " in
      *" $name "*) ;;
      *) echo "panel.sh: unknown panel '${2:-}'" >&2; exit 2 ;;
    esac
    if [ "$1" = toggle ] && $EWW active-windows 2>/dev/null | grep -q ": ${name}$"; then
      close_all
      exit 0
    fi
    close_all
    $EWW open "$BACKDROP" >/dev/null 2>&1
    $EWW open "$name"     >/dev/null 2>&1
    ;;
  close)
    close_all
    ;;
  *)
    echo "usage: panel.sh {open|close|toggle} [vol|bright|net|power|bt|cal|weather]" >&2
    exit 2
    ;;
esac
