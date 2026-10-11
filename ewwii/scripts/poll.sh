#!/bin/bash
# poll.sh -- normalise a status command's output for ewwii's Poll reader.
#
# ewwii runs each poll command inside a long-lived /bin/sh and reads exactly
# one newline-terminated line per tick (see crates/ewwii/src/updates/poll.rs).
# /bin/sh does NOT append a newline, and several of our helpers emit their
# value with `printf '%s'` (no trailing newline).  In that case the reader's
# read_line() blocks forever, so the variable is never updated and the widget
# stays empty.
#
# This wrapper runs the command, collapses its output to the first line and
# guarantees a single trailing newline.
out=$("$@" 2>/dev/null)
printf '%s\n' "${out%%$'\n'*}"
