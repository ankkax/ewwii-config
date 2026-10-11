#!/bin/bash
# CPU usage (%) from two /proc/stat samples.
prev="$HOME/.cache/eww-cpu.prev"
read -r _ a b c idle rest < /proc/stat
total=$((a+b+c+idle))
for v in $rest; do total=$((total+v)); done
if [[ -r "$prev" ]]; then
  read -r ptotal pidle < "$prev"
  printf '%s %s\n' "$total" "$idle" > "$prev"
  dt=$((total-ptotal)); di=$((idle-pidle))
  if (( dt > 0 )); then awk -v d="$dt" -v i="$di" 'BEGIN{printf "%d", (d-i)*100/d}'; else echo 0; fi
else
  printf '%s %s\n' "$total" "$idle" > "$prev"
  echo 0
fi
