#!/bin/bash
set -u -e -o pipefail

debug() { echo "$@" >&2; }

login() { local EMAIL=$1 PASSWORD=$2  
  local COOKIES="cookies.txt"
  local URL="http://registro.lavanguardia.com/reg2006/Registro"
  local PARAMS="p_action=loginconfig&email=$EMAIL&password=$PASSWORD"
  debug "GET $URL"
  curl -sS -c $COOKIES "$URL?$PARAMS" || return 1
  echo $COOKIES
}

download() { local COOKIES=$1
  DATE=$(date "+%Y%m%d")
  URL="http://hemeroteca.lavanguardia.com/search.html"
  FILENAME="lvg-chess-$DATE.pdf"
  PARAMS_START=$(date "+bd=%d&bm=%m&by=%Y")
  PARAMS_END=$(date "+ed=%d&em=%m&ey=%Y")
  COMPLETE_URL="$URL?q=MOTS+ENCREUATS+ANTERIORS+&${PARAMS_START}&${PARAMS_END}"
  debug "GET $COMPLETE_URL"
  PDF_URL0=$(curl -sS -b $COOKIES -c $COOKIES "$COMPLETE_URL" |
    grep -o "http://hemeroteca.lavanguardia.com/dynamic/preview/[^?]*" | head -n1)
  debug "GET $PDF_URL0"
  PDF_URL=$(curl -b $COOKIES -c $COOKIES -sS "$PDF_URL0" |  
    grep -o "http://hemeroteca-paginas.lavanguardia[^\"]*" | head -n1)

  debug "GET $PDF_URL"   
  curl -b $COOKIES -c $COOKIES -L -o $FILENAME "$PDF_URL"
    
  echo $FILENAME
}

read USER PASSWORD < auth 
COOKIES=$(login $USER $PASSWORD)
download $COOKIES
