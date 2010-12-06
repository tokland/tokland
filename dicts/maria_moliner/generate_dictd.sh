#!/bin/bash
set -e

debug() { echo "$@" >&2; }

remove_html_tags() { sed "s/<[^>]*>//g"; }

remove_leading_blank_lines() { sed '/./,$!d'; } 

html2text() {
  lynx -stdin -dump -pseudo_inlines -display_charset=utf-8 -assume_charset=utf-8 | \
    remove_leading_blank_lines 
}

generate_jargon_input() {
  local DIRECTORY=$1
  FILES=$(find "$DIRECTORY" -type f -name '*.html')
  NFILES=$(echo "$FILES" | wc -l) 
  echo "$FILES" | sort | head -n10 | cat -n | while read INDEX HTMLFILE; do
    WORD=$(basename "$HTMLFILE" ".html")
    DEFINITION=$(ruby process.rb "$HTMLFILE" | html2text) || return 1
    debug "[$INDEX/$NFILES] $WORD" 
    echo ":$WORD:$DEFINITION"    
  done
}

generate_dict() {
  local DIRECTORY=$1
  local NAME=$2  
  
  generate_jargon_input "$DIRECTORY" |
    dictfmt -j --utf8 --without-headword -s "$NAME" "$NAME"
  dictzip $NAME.dict
  echo $NAME.index $NAME.dict.dz
}

generate_dict "html" "mariamoliner"
