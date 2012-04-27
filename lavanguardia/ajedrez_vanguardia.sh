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
  DATE=$(date "+%Y %m %d")
  read YEAR MONTH DAY <<< "$DATE"
  FILENAME="lvg-chess-$(echo $DATE | tr -d ' ').pdf"
  URL="http://hemeroteca.lavanguardia.com/dynamic/edition/editionThumbnails.html"
  
  URL2="$URL?edition=Vivir+Barcelona+Cat&bd=$DAY&bm=$MONTH&by=$YEAR"
  debug "GET $URL2"
  PDF_URL0=$(curl -L -b $COOKIES -c $COOKIES -sS "$URL2" |   
             grep -o "http://hemeroteca.*pagina-12.*.pdf.html" | head -n1)
  test "$PDF_URL0" || return 1          
  debug "GET $PDF_URL0"
  PDF_URL=$(curl -L -b $COOKIES -c $COOKIES -sS "$PDF_URL0" |  
            grep -o "http://hemeroteca-paginas.lavanguardia[^\"]*" | head -n1)
  test "$PDF_URL" || return 1
  debug "GET $PDF_URL"   
  curl -b $COOKIES -c $COOKIES -L -o $FILENAME "$PDF_URL" || return 1
  echo $FILENAME
}

read USER PASSWORD < auth 
COOKIES=$(login $USER $PASSWORD)
download $COOKIES
