#!/bin/bash
# status.sh <module> -- one-line status for the eww bar (Omarchy-style).
#
#   cpu  cput | vol  volt | bat  batt | net  nett | bt  btt
#
# The bare module prints a glyph; the *t variant prints tooltip text.

DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$DIR/icons.sh"

pam()   { pamixer "$@" 2>/dev/null; }
cpu_value() { "$DIR/cpu.sh" 2>/dev/null || echo 0; }
bat_dev() { local b; for b in /sys/class/power_supply/BAT*; do [ -r "$b/capacity" ] && { echo "$b"; return; }; done; }

vol_icon() {
  local v; v=$(pam --get-volume)
  [ -z "$v" ] && { printf '%s' "$I_VOL_OFF"; return; }
  [ "$(pam --get-mute)" = "true" ] && { printf '%s' "$I_VOL_MUTE"; return; }
  if pactl list sinks 2>/dev/null | grep -qi 'Active Port:.*headphone'; then
    printf '%s' "$I_VOL_HEADPHONES"; return
  fi
  if   [ "$v" -lt 34 ]; then printf '%s' "$I_VOL_OFF"
  elif [ "$v" -lt 67 ]; then printf '%s' "$I_VOL_LOW"
  else                       printf '%s' "$I_VOL_UP"; fi
}

vol_text() {
  local v; v=$(pam --get-volume)
  [ -z "$v" ] && { echo "Volume n/a"; return; }
  if [ "$(pam --get-mute)" = "true" ]; then echo "Muted"
  else printf '%s%%' "$v"; fi
}

bat_icon() {
  local d cap st idx; d="$(bat_dev)"; [ -z "$d" ] && { printf '%s' "$I_PLUG"; return; }
  cap=$(cat "$d/capacity" 2>/dev/null || echo 50)
  st=$(cat "$d/status" 2>/dev/null || echo Unknown)
  idx=$(( cap / 10 )); [ "$idx" -lt 1 ] && idx=1; [ "$idx" -gt 10 ] && idx=10
  case "$st" in
    Charging)       printf '%s' "${I_BAT_CHG[$idx]}" ;;
    Full)           printf '%s' "${I_BAT_CHG[10]}" ;;
    "Not charging") printf '%s' "$I_PLUG" ;;
    *)              printf '%s' "${I_BAT_DIS[$idx]}" ;;
  esac
}

bat_text() {
  local d; d="$(bat_dev)"
  if [ -z "$d" ]; then echo "AC power"; return; fi
  local r; r=$(bat_watts)
  printf '%s%% · %s%s' "$(cat "$d/capacity" 2>/dev/null)" "$(cat "$d/status" 2>/dev/null)" "${r:+ · $r}"
}

net_mode() {
  local s; s=$(nmcli -t -f TYPE,STATE device status 2>/dev/null)
  if   grep -q '^ethernet:connected' <<<"$s"; then echo eth
  elif grep -q '^wifi:connected'     <<<"$s"; then echo wifi
  else echo none; fi
}

net_icon() {
  case "$(net_mode)" in
    eth) printf '%s' "$I_ETH" ;;
    wifi)
      local sig; sig=$(nmcli -t -f IN-USE,SIGNAL device wifi 2>/dev/null | awk -F: '$1=="*"{print $2; exit}'); sig=${sig:-0}
      if   [ "$sig" -ge 75 ]; then printf '%s' "${I_WIFI[4]}"
      elif [ "$sig" -ge 50 ]; then printf '%s' "${I_WIFI[3]}"
      elif [ "$sig" -ge 25 ]; then printf '%s' "${I_WIFI[2]}"
      else                         printf '%s' "${I_WIFI[1]}"; fi ;;
    *) printf '%s' "$I_WIFI_OFF" ;;
  esac
}

net_text() {
  case "$(net_mode)" in
    eth)  nmcli -t -f TYPE,DEVICE,STATE device status 2>/dev/null | awk -F: '$1=="ethernet"&&$3=="connected"{print "Ethernet ("$2")"; exit}' ;;
    wifi) local ssid; ssid=$(nmcli -t -f IN-USE,SSID device wifi 2>/dev/null | awk -F: '$1=="*"{print $2; exit}'); printf '%s' "${ssid:-Wi-Fi}" ;;
    *)    echo "Disconnected" ;;
  esac
}

# short detail for the panel's "Connected to ..." line:
# the SSID on Wi-Fi, the interface name on Ethernet, empty when nothing is up.
net_detail() {
  case "$(net_mode)" in
    eth)  nmcli -t -f TYPE,DEVICE,STATE device status 2>/dev/null | awk -F: '$1=="ethernet"&&$3=="connected"{print $2; exit}' ;;
    wifi) nmcli -t -f IN-USE,SSID device wifi 2>/dev/null | awk -F: '$1=="*"{print $2; exit}' ;;
    *)    : ;;
  esac
}

bt_icon() {
  bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' || { printf '%s' "$I_BT_OFF"; return; }
  bluetoothctl devices Connected 2>/dev/null | grep -q '^Device' && { printf '%s' "$I_BT_CONNECTED"; return; }
  printf '%s' "$I_BT"
}

bt_text() {
  bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' || { echo "Bluetooth off"; return; }
  local d; d=$(bluetoothctl devices Connected 2>/dev/null | head -n1 | sed 's/^Device [0-9A-Fa-f:]* //')
  printf '%s' "${d:-Bluetooth on}"
}

# --- Omarchy quattro widgets ------------------------------------------------
# display / monitor (brightness)
bright_pct() { brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'; }
bright_icon() { printf '%s' "$I_BRIGHT"; }
bright_text() { local p; p=$(bright_pct); printf 'Brightness %s%%' "${p:-?}"; }

# system updates (count cached by updates-watch.sh; see autostart)
upd_count() { cat "$HOME/.cache/eww/updates" 2>/dev/null || echo 0; }
upd_icon()  { local n; n=$(upd_count); if [ "${n:-0}" -gt 0 ] 2>/dev/null; then printf '%s' "$I_UPDATE"; fi; return 0; }
upd_state() { local n; n=$(upd_count); if [ "${n:-0}" -gt 0 ] 2>/dev/null; then echo true; else echo false; fi; return 0; }
upd_text()  { local n; n=$(upd_count); printf '%s system update(s) pending' "${n:-0}"; return 0; }

# keyboard layout (shown only when more than one layout is configured, per Omarchy)
kb_layouts() { setxkbmap -query 2>/dev/null | awk '/^layout:/{print $2}'; }
kb_icon()  { kb_layouts | cut -d, -f1; }
kb_state() { local l; l=$(kb_layouts); case "$l" in *,*) echo true ;; *) echo false ;; esac; }
kb_text()  { printf 'Keyboard layout: %s' "$(kb_layouts)"; }

# battery percentage (toggled on the power widget with right-click)
bat_pct() { local d; d="$(bat_dev)"; [ -z "$d" ] && { echo "AC"; return; }; printf '%s%%' "$(cat "$d/capacity" 2>/dev/null)"; }

# --- battery detail (eww power panel) ---------------------------------------
# Everything is read straight from sysfs so the open panel stays live.

bat_pctnum() { local d; d=$(bat_dev); [ -z "$d" ] && { echo 0; return; }; cat "$d/capacity" 2>/dev/null || echo 0; }

# pixel width of the fill for the 300px progress track (see .power-bar in eww.scss)
bat_fill() { awk -v p="$(bat_pctnum)" 'BEGIN { printf "%d", p * 3 }'; }

bat_state() {
  local d; d=$(bat_dev); [ -z "$d" ] && { echo ac; return; }
  case "$(cat "$d/status" 2>/dev/null)" in
    Charging)       echo charging ;;
    Discharging)    echo discharging ;;
    Full)           echo full ;;
    "Not charging") echo holding ;;
    *)              echo unknown ;;
  esac
}

bat_watts() {
  local d; d=$(bat_dev); [ -z "$d" ] && return
  local w=""
  if   [ -r "$d/power_now" ]; then
    w=$(awk -v u="$(cat "$d/power_now")" 'BEGIN { printf "%.1f", u/1000000 }')
  elif [ -r "$d/current_now" ] && [ -r "$d/voltage_now" ]; then
    w=$(awk -v i="$(cat "$d/current_now")" -v v="$(cat "$d/voltage_now")" \
        'BEGIN { i=(i<0?-i:i); printf "%.1f", i*v/1000000000000 }')
  fi
  [ -z "$w" ] && return
  awk -v w="$w" 'BEGIN { sub(/\.0$/, "", w); printf "%sW", w }'
}

bat_size() {
  local d; d=$(bat_dev); [ -z "$d" ] && return
  local e=""
  if   [ -r "$d/energy_full" ];        then e=$(cat "$d/energy_full")
  elif [ -r "$d/charge_full" ];        then e=$(cat "$d/charge_full")
  elif [ -r "$d/energy_full_design" ]; then e=$(cat "$d/energy_full_design")
  fi
  [ -z "$e" ] && return
  awk -v u="$e" 'BEGIN { printf "%.0fWh", u/1000000 }'
}

bat_cycles() { local d; d=$(bat_dev); [ -z "$d" ] && return; [ -r "$d/cycle_count" ] && cat "$d/cycle_count" 2>/dev/null; }

bat_time() {
  local d; d=$(bat_dev); [ -z "$d" ] && return
  local st now full pw secs
  st=$(bat_state)
  now=$(cat "$d/energy_now"  2>/dev/null)
  full=$(cat "$d/energy_full" 2>/dev/null)
  pw=$(cat "$d/power_now"   2>/dev/null)
  if [ -z "$now" ] || [ -z "$pw" ]; then return; fi
  case "$st" in
    discharging) secs=$(awk -v n="$now" -v p="$pw" 'BEGIN { if (p>0) printf "%.0f", n/p*3600 }') ;;
    charging)    if [ -z "$full" ]; then return; fi
                 secs=$(awk -v n="$now" -v f="$full" -v p="$pw" 'BEGIN { if (p>0) printf "%.0f", (f-n)/p*3600 }') ;;
    *)           return ;;
  esac
  [ -z "$secs" ] && return
  awk -v s="$secs" 'BEGIN {
    h = int(s/3600); m = int((s%3600)/60);
    if      (h > 0 && m > 0) printf "%dh %dm", h, m;
    else if (h > 0)          printf "%dh", h;
    else                     printf "%dm", m;
  }'
}

bat_threshold() {
  local d; d=$(bat_dev); [ -z "$d" ] && return
  local e=""
  [ -r "$d/charge_control_end_threshold" ] && e=$(cat "$d/charge_control_end_threshold" 2>/dev/null)
  case "$e" in ""|0|100) return ;; esac
  printf '%s%%' "$e"
}

# hero status line: rotates Omarchy's phrases while current flows
bat_status_text() {
  local st idx; st=$(bat_state)
  case "$st" in
    charging)
      local p=( "Pumping power" "Injecting electrons" "Pouring juice" "Amassing watts" "Soaking amps" )
      idx=$(( $(date +%s) / 3 % ${#p[@]} )); printf '%s' "${p[$idx]}" ;;
    discharging)
      local p=( "Slurping power" "Spending joules" "Draining watts" "Burning electrons" "Sipping juice" )
      idx=$(( $(date +%s) / 3 % ${#p[@]} )); printf '%s' "${p[$idx]}" ;;
    full)    echo "Fully charged" ;;
    holding) printf 'Holding at %s' "$(bat_threshold)" ;;
    ac)      echo "AC power" ;;
    *)       echo "Battery" ;;
  esac
}

case "$1" in
  cpu)  printf '%s' "$I_CPU" ;;
  cput) printf 'CPU %s%%' "$(cpu_value)" ;;
  vol)  vol_icon ;;
  volt) vol_text ;;
  bat)  bat_icon ;;
  batt) bat_text ;;
  net)  net_icon ;;
  nett) net_text ;;
  netmode)   net_mode ;;
  netdetail) net_detail ;;
  bt)   bt_icon ;;
  btt)  bt_text ;;
  bright)   bright_icon ;;
  brightt)  bright_text ;;
  upd)      upd_icon ;;
  updstate) upd_state ;;
  updt)     upd_text ;;
  kb)       kb_icon ;;
  kbstate)  kb_state ;;
  kbt)      kb_text ;;
  batp)      bat_pct ;;
  batpct)    bat_pctnum ;;
  batfill)   bat_fill ;;
  batstate)  bat_state ;;
  haslaptop)  if [ -n "$(bat_dev)" ]; then echo true; else echo false; fi ;;
  hasdesktop) if [ -n "$(bat_dev)" ]; then echo false; else echo true; fi ;;
  batrate)   bat_watts ;;
  batsize)   bat_size ;;
  batcycles) bat_cycles ;;
  battime)   bat_time ;;
  batthresh) bat_threshold ;;
  batstatus) bat_status_text ;;
  close)    printf '%s' "$I_CLOSE" ;;
  *)    : ;;
esac
exit 0
