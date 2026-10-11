#!/bin/bash
# toggle.sh <var> -- flip an eww boolean defvar (used by the power widget to
# show/hide the battery percentage, like Omarchy's right-click on power).

EWW=/usr/bin/ewwii
v="$1"
[ -n "$v" ] || exit 1

# ewwii has no "get"; read the current value out of `ewwii state` (a JSON-ish
# dump of every variable).
cur=$("$EWW" state 2>/dev/null \
      | sed -n "s/.*\"$v\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
      | head -1)
if [ "$cur" = "true" ]; then
  "$EWW" update "$v=false" >/dev/null 2>&1
else
  "$EWW" update "$v=true" >/dev/null 2>&1
fi
