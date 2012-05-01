#!/bin/bash
set -e

debug() { echo "$@" >&2; }

remove_html_tags() { sed "s/<[^>]*>//g"; }

remove_leading_blank_lines() { sed '/./,$!d'; } 

html2text() {
  grep '<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0">' | head -n1 |
    lynx -stdin -dump -pseudo_inlines | remove_leading_blank_lines 
}

generate_jargon_input() {
  local DIRECTORY=$1
  
  find "$DIRECTORY" -type f -name '*.html' | cat -n | while read INDEX HTMLFILE; do
    WORD=$(basename "$HTMLFILE" ".html")
    DEFINITION=$(cat "$HTMLFILE" | html2text | recode html..utf8)
    debug "$INDEX: $WORD" 
    echo ":$WORD:$DEFINITION"    
  done
}

generate_dict() {
  local DIRECTORY=$1
  local NAME=$2  
  
  generate_jargon_input "$DIRECTORY" |
    dictfmt -j --utf8 --without-headword -s "$NAME" "$NAME"
  dictzip $NAME.dict
  echo "$NAME.index $NAME.dict.dz"
}

generate_dict "html" "gdictcat"
