#!/bin/bash
v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%d", $2*100}')
echo "${v:-0}"
