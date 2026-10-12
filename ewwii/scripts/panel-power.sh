#!/usr/bin/env bash
# panel-power.sh -- actions for the eww power panel.
#
#   panel-power.sh set <Quiet|Balanced|Performance>   ASUS power profile (asusctl)
#   panel-power.sh session <lock|suspend|logout|reboot|shutdown>
#
# The profile picker mirrors Omarchy's, but the profiles come from asusctl
# instead of power-profiles-daemon (this is an ASUS ROG G14).

EWW="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)/ewp"   # panels/OSD daemon
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PANEL="$DIR/panel.sh"

case "${1:-}" in
  set)
    p=${2:-}
    case "$p" in
      Quiet|Balanced|Performance) ;;
      *) echo "panel-power.sh: unknown profile '$p'" >&2; exit 2 ;;
    esac
    # ewwii has no "poll" subcommand: push the new value straight in.  Do it
    # optimistically first so the highlight flips on click (asusctl takes
    # ~170ms), then reconcile with what asusctl actually reports.
    $EWW update "pactive=\"$p\"" >/dev/null 2>&1
    if command -v asusctl >/dev/null 2>&1; then
      asusctl profile set "$p" >/dev/null 2>&1
      act=$(asusctl profile get 2>/dev/null | sed -n 's/^Active profile: *//Ip')
    else
      case "$p" in
        Quiet)       pp=power-saver ;;
        Balanced)    pp=balanced ;;
        Performance) pp=performance ;;
      esac
      powerprofilesctl set "$pp" >/dev/null 2>&1
      act=$("$DIR/pactive.sh")
    fi
    [ -n "$act" ] && $EWW update "pactive=\"$act\"" >/dev/null 2>&1
    ;;

  session)
    case "${2:-}" in
      lock)
        if   command -v hyprlock    >/dev/null 2>&1; then hyprlock
        elif command -v swaylock    >/dev/null 2>&1; then swaylock -f
        elif command -v i3lock      >/dev/null 2>&1; then i3lock -n -c 1a1b26
        elif command -v xsecurelock >/dev/null 2>&1; then xsecurelock
        else
          notify-send -a eww "Lock" "No screen locker installed (i3lock / hyprlock / swaylock)"
        fi
        ;;
      suspend)  loginctl suspend ;;
      logout)
        sid="${XDG_SESSION_ID:-$(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$(id -un)" '$3==u{print $1; exit}')}"
        if [ -n "$sid" ]; then loginctl terminate-session "$sid" 2>/dev/null; fi
        pkill -x oxwm 2>/dev/null
        ;;
      reboot)   loginctl reboot ;;
      shutdown) loginctl poweroff ;;
      *) echo "panel-power.sh: unknown session action '${2:-}'" >&2; exit 2 ;;
    esac
    "$PANEL" close >/dev/null 2>&1
    ;;

  *)
    echo "usage: panel-power.sh set <Quiet|Balanced|Performance>" >&2
    echo "       panel-power.sh session <lock|suspend|logout|reboot|shutdown>" >&2
    exit 2
    ;;
esac
