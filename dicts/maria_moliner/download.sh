#!/bin/bash
set -e

debug() { 
  echo "$@" >&2; 
}

# Get first line that matches regular expression $1 and parse string $2
parse_all() { local S=$(sed -n "/$1/I s/^.*$2.*$/\1/ip") && test "$S" && echo "$S"; }

# Curl wrapper (goal: robustness and responsiveness)
scurl() { curl -sS --connect-timeout 20 --speed-time 60 --retry 5 "$@"; }

OUTPUTDIR="html"
mkdir -p "$OUTPUTDIR"
RANGE=${1:-"{A..Z}"}
for LETTER in $(eval echo $RANGE); do  
  START_URL=${1:-"http://www.diclib.com/cgi-bin/d1.cgi?l=es&base=moliner&page=showletter&letter=$LETTER&start=0"}
  URL=$START_URL
  while true; do
    debug "page: $URL"
    echo "$URL"
    PAGE=$(scurl "$URL")
    echo "$PAGE" | sed "s/>/>\n/g" | parse_all "menu_blue.*show\/" 'href="\([^"]\+\)' | while read URL; do
      WORD=$(echo "$URL" | cut -d"/" -f4)
      test "$URL" -a "$WORD" || continue
      debug "$WORD: $URL"
      FILE="$OUTPUTDIR/$WORD.html"
      test -e "$FILE" -a -s "$FILE" && 
        { debug "skip existing file: $FILE"; continue; }
      scurl -o "$FILE" "$URL"
      echo $FILE
    done
    URL=$(echo "$PAGE" | sed "s/>/>\n/g" | parse_all "page=showletter" 'href="\([^"]\+\)' | head -n1) 
    test "$URL" || break
  done
done
