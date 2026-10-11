#!/bin/bash
# bright-level.sh -- current display brightness percentage (number only).
brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'
