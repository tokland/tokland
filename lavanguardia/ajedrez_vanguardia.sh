#!/bin/bash
set -e

debug() {
  echo "$@" >&2
}

match() {
  local S=$(sed -n "/$1/s/^.*$2.*$/\1/p") && test "$S" && echo "$S" ||
    { debug "parse failed: sed -n \"/$1/$2\""; return 1; }
}

login() { local EMAIL=$1; local PASSWORD=$2  
  local COOKIES="cookies.txt"
  local URL="http://registro.lavanguardia.com/reg2006/Registro"
  local PARAMS="p_action=loginconfig&email=$EMAIL&password=$PASSWORD"
  debug "GET $URL"
  curl -sS -c $COOKIES "$URL?$PARAMS" || return 1
  echo $COOKIES
}

download() { local COOKIES=$1; local DATE0=$2   
  local DATE=$(test "$DATE0" && echo $DATE0 || date "+%Y%m%d")
  local FILENAME="lvg-chess-$DATE.pdf"  
  local INDEX_URL="http://edicionimpresa.lavanguardia.com/free/epaper/$DATE/index.html"
  debug "GET $INDEX_URL"
  INDEX=$(curl -sS -b $COOKIES -c $COOKIES "$INDEX_URL") || return 1
  URL=$(echo "$INDEX" | match "Pasatiempos" 'href="\(.*\)"') || return 1
  
  debug "GET $URL"
  PAGE=$(curl -sS -L -b $COOKIES -c $COOKIES "$URL") || return 1
  PDF_URL=$(echo "$PAGE" | match strPdf "'\(.*\)'") || return 1
  
  debug "GET $PDF_URL"
  curl -o "$FILENAME" -b $COOKIES -c $COOKIES "$PDF_URL" || return 1
  echo $FILENAME
}

read USER PASSWORD < auth 
COOKIES=$(login $USER $PASSWORD)
download $COOKIES
