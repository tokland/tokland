#!/bin/bash
set -e

debug() { 
  echo "$@" >&2; 
}

scurl() {
  for TRY in $(seq 6); do
    curl "$@" && return 0 || debug "error: curl $@"
    sleep 10
  done
  return 1     
}

OUTPUTDIR="html"
mkdir -p "$OUTPUTDIR"
START_URL=${1:-"http://www.diccionari.cat/cgi-bin/AppDLC3.exe?APP=CERCADLC&GECART=0"}
URL=$START_URL
while true; do
  debug "page: $URL"
  echo "$URL"
  PAGE=$(scurl "$URL")
  echo "$PAGE" | sed "s#\(</[^>]*>\)#\1\n#g" | grep 'LLISTA_D' | recode html..utf8 | 
      sed -n 's/^.*href="\(.*\)".*CLASS.*>\(.*\)<.*$/\1 \2/p' | while read URL WORD; do
    test "$URL" -a "$WORD" || continue
    debug "$WORD: $URL"
    FILE="$OUTPUTDIR/$WORD.html"
    test -e "$FILE" -a -s "$FILE" && 
      { debug "skip existing file: $FILE"; continue; }
    scurl -o "$FILE" "$URL"
    echo $FILE
  done
  P=$(echo "$PAGE" | grep -o 'javascript:seguents([^)]*' | cut -d"(" -f2) || true
  test "$P" || break
  URL="http://www.diccionari.cat/cgi-bin/AppDLC3.exe?APP=SEGUENTS&P=$P"
done
