#!/bin/bash
# weather.sh [text] -- current weather for the eww bar via wttr.in.
# No arg: "<icon> <temp>"   |   "text": "<icon>  <condition>  <temp>"

. "$(cd "$(dirname "$(readlink -f "$0")")" && pwd)/icons.sh"

loc="${EWW_WEATHER_LOCATION:-}"
out=$(curl -fsS --max-time 6 "https://wttr.in/${loc}?format=%C|%t" 2>/dev/null) \
  || { [ "$1" = text ] && echo "Weather unavailable"; exit 0; }

cond="${out%%|*}"; temp="${out#*|}"
c=$(printf '%s' "$cond" | tr '[:upper:]' '[:lower:]')

case "$c" in
  *thunder*|*lightning*)              ico=$'\U000f0593' ;;
  *snow*|*sleet*|*ice*|*blizzard*)    ico=$'\U000f0598' ;;
  *pour*|*heavy*)                     ico=$'\U000f0596' ;;
  *rain*|*drizzle*|*shower*)          ico=$'\U000f0597' ;;
  *fog*|*mist*|*haze*)                ico=$'\U000f0591' ;;
  *overcast*)                         ico=$'\U000f0590' ;;
  *cloud*)                            ico=$'\U000f0595' ;;
  *wind*)                             ico=$'\U000f059d' ;;
  *sun*|*clear*)                      ico=$'\U000f0599' ;;
  *)                                  ico=$'\U000f0595' ;;
esac

if [ "$1" = text ]; then
  printf '%s  %s  %s\n' "$ico" "$cond" "$temp"
else
  printf '%s %s' "$ico" "$temp"
fi
