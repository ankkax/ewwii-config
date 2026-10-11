#!/bin/bash
# wfcast.sh d1|d2|d3 -- one daily forecast row for the ewwii weather panel.
#
# Fetches the 3-day forecast from wttr.in and caches the JSON for 30 min so the
# three per-day polls share a single network request.  Output is a single line
# (poll.sh-friendly):  <icon>  <Weekday>  <min>° / <max>°  <condition>

DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$DIR/icons.sh"

cache="${XDG_CACHE_HOME:-$HOME/.cache}/eww-wfcast.json"

now=$(date +%s)
mt=$(stat -c %Y "$cache" 2>/dev/null || echo 0)
if [ ! -s "$cache" ] || [ $(( now - mt )) -gt 1800 ]; then
  if curl -fsS --max-time 8 "https://wttr.in/${EWW_WEATHER_LOCATION:-}?format=j1" \
       -o "$cache.tmp" 2>/dev/null; then
    mv -f "$cache.tmp" "$cache"
  else
    rm -f "$cache.tmp"
  fi
fi

[ -s "$cache" ] || { printf 'Weather unavailable'; exit 0; }

icon() {
  case "$1" in
    *thunder*|*lightning*)           printf '%s' $'\U000f0593' ;;
    *snow*|*sleet*|*ice*|*blizzard*) printf '%s' $'\U000f0598' ;;
    *pour*|*heavy*)                  printf '%s' $'\U000f0596' ;;
    *rain*|*drizzle*|*shower*)       printf '%s' $'\U000f0597' ;;
    *fog*|*mist*|*haze*)             printf '%s' $'\U000f0591' ;;
    *overcast*)                      printf '%s' $'\U000f0590' ;;
    *cloud*)                         printf '%s' $'\U000f0595' ;;
    *wind*)                          printf '%s' $'\U000f059d' ;;
    *sun*|*clear*)                   printf '%s' $'\U000f0599' ;;
    *)                               printf '%s' $'\U000f0595' ;;
  esac
}

n=$(printf '%s' "${1:-d1}" | tr -dc '0-9')
idx=$(( ${n:-1} - 1 ))

row=$(jq -r --argjson i "$idx" '.weather[$i] // empty' "$cache" 2>/dev/null)
[ -n "$row" ] || { printf 'Weather unavailable'; exit 0; }

desc=$(printf '%s' "$row" | jq -r '.hourly[3].weatherDesc[0].value // .hourly[0].weatherDesc[0].value // "Unknown"')
desc=$(printf '%s' "$desc" | sed 's/[[:space:]]*$//')
tmax=$(printf '%s' "$row" | jq -r '.maxtempC')
tmin=$(printf '%s' "$row" | jq -r '.mintempC')
isodate=$(printf '%s' "$row" | jq -r '.date')
wd=$(date -d "$isodate" '+%a' 2>/dev/null || printf '%s' "$isodate")

printf '%s  %s  %s° / %s°  %s' \
  "$(icon "$(printf '%s' "$desc" | tr '[:upper:]' '[:lower:]')")" \
  "$wd" "$tmin" "$tmax" "$desc"
