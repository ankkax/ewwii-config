#!/usr/bin/env bash
# net-act.sh -- actions for the eww network panel.
#   net-act.sh toggle-wifi
#   net-act.sh rescan
#   net-act.sh connect <ssid>
#   net-act.sh dns
export LC_ALL=C
DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

notify()      { notify-send -a "Network" "$@" 2>/dev/null || :; }
wifi_enabled(){ [ "$(nmcli radio wifi 2>/dev/null)" = enabled ]; }
wifi_dev()    { nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'; }
active_wifi() { nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="802-11-wireless"{print $1; exit}'; }
active_conn() { nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2!="loopback"{print $1; exit}'; }

ask_pw() { zenity --password --title="Wi-Fi" --text="Password for “$1”" 2>/dev/null; }

case "${1:-}" in
  toggle-wifi)
    if wifi_enabled; then nmcli radio wifi off >/dev/null 2>&1 && notify "Wi-Fi off"
    else nmcli radio wifi on >/dev/null 2>&1 && notify "Wi-Fi on"; fi ;;

  rescan)
    nmcli device wifi rescan >/dev/null 2>&1 ;;

  connect)
    ssid="${2:-}"
    [ -n "$ssid" ] || exit 0
    if [ "$(active_wifi)" = "$ssid" ]; then
      nmcli device disconnect "$(wifi_dev)" >/dev/null 2>&1
      notify "Disconnected from $ssid"
    elif nmcli -t -f NAME connection show 2>/dev/null | grep -qxF "$ssid"; then
      if nmcli --wait 25 connection up "$ssid" >/dev/null 2>&1; then notify "Connected to $ssid"
      else notify "Could not connect to $ssid"; fi
    elif nmcli --wait 25 device wifi connect "$ssid" >/dev/null 2>&1; then
      notify "Connected to $ssid"
    else
      pw=$(ask_pw "$ssid") || exit 0
      [ -n "$pw" ] || exit 0
      if nmcli --wait 25 device wifi connect "$ssid" password "$pw" >/dev/null 2>&1; then
        notify "Connected to $ssid"
      else
        notify "Could not connect to $ssid"
      fi
    fi ;;

  dns)
    conn=$(active_conn)
    if [ -z "$conn" ]; then notify "No active connection"; exit 0; fi
    pick=$(zenity --list --title="DNS provider" --text="DNS for “$conn”" --height=320 \
             --column="Provider" "Automatic (from network)" \
             "Cloudflare  1.1.1.1" "Google  8.8.8.8" "Quad9  9.9.9.9" 2>/dev/null)
    [ -n "$pick" ] || exit 0
    case "$pick" in
      Automatic*)  nmcli connection modify "$conn" ipv4.ignore-auto-dns no  ipv6.ignore-auto-dns no  >/dev/null 2>&1 ;;
      Cloudflare*) nmcli connection modify "$conn" ipv4.dns "1.1.1.1 1.0.0.1"        ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes >/dev/null 2>&1 ;;
      Google*)     nmcli connection modify "$conn" ipv4.dns "8.8.8.8 8.8.4.4"        ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes >/dev/null 2>&1 ;;
      Quad9*)      nmcli connection modify "$conn" ipv4.dns "9.9.9.9 149.112.112.112" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes >/dev/null 2>&1 ;;
    esac
    nmcli connection up "$conn" >/dev/null 2>&1
    notify "DNS: $pick" ;;
esac
