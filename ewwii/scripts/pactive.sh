#!/bin/bash
# pactive.sh -- active power profile name: "Quiet" | "Balanced" | "Performance".
# asusctl on the ASUS laptop; power-profiles-daemon (power-saver/balanced/performance) elsewhere.
if command -v asusctl >/dev/null 2>&1; then
  asusctl profile get 2>/dev/null | sed -n 's/^Active profile: *//Ip'
else
  case "$(powerprofilesctl get 2>/dev/null)" in
    power-saver) echo Quiet ;;
    balanced)    echo Balanced ;;
    performance) echo Performance ;;
  esac
fi
