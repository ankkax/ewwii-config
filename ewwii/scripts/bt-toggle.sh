#!/bin/bash
# bt-toggle.sh -- power the bluetooth adapter on/off.
if bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
  bluetoothctl power off >/dev/null 2>&1
else
  bluetoothctl power on  >/dev/null 2>&1
fi
