#!/bin/bash

FILES=$(find output/ -name "vgd-chess-*.html.template" | sort -n)
FILES2=$(echo "$FILES" | sed "s/.template$//; s/^output\///")
while read HTMLFILE; do
  DATE=$(echo "$HTMLFILE" | sed "s/^.*chess-\(.*\)\.html.template/\1/")
  PREVIOUS=$(echo "$FILES2" | grep "$DATE" -B1 | head -n1 | grep -v "$DATE") || true
  NEXT=$(echo "$FILES2" | grep "$DATE" -A1 | tail -n1 | grep -v "$DATE")  || true
  echo $HTMLFILE: "$PREVIOUS" - "$NEXT"
  OUTPUT="output/$(basename "$HTMLFILE" ".template")"
  sed "s@%PREVIOUS%@$PREVIOUS@; s@%NEXT%@$NEXT@" "$HTMLFILE" > "$OUTPUT"
done <<< "$FILES"

LAST=$(find output/ -name "vgd-chess-*.html" | sort -n | tail -n1)
test "$LAST" && cp "$LAST" output/index.html
