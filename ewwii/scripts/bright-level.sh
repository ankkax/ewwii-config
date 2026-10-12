#!/bin/bash
# bright-level.sh -- current display brightness percentage (number only).
exec "$(dirname "$(readlink -f "$0")")/bright.sh" pct
