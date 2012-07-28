#!/bin/bash
set -u -e -o pipefail

debug() { echo "$@" >&2; }

login() { local EMAIL=$1 PASSWORD=$2  
  local COOKIES="/tmp/cookies.txt"
  local URL="http://registro.lavanguardia.com/reg2006/Registro"
  local PARAMS="p_action=loginconfig&email=$EMAIL&password=$PASSWORD"
  debug "GET $URL"
  curl -sS -c $COOKIES "$URL?$PARAMS" || return 1
  echo $COOKIES
}

download() { local COOKIES=$1; local DATE=$2
  test "$DATE" || DATE=$(date "+%Y-%m-%d")
  IFS="-" read YEAR MONTH DAY <<< "$DATE"
  FILENAME="lvg-moran-$YEAR-$MONTH-$DAY.pdf"
  URL="http://hemeroteca.lavanguardia.com/dynamic/edition/editionThumbnails.html"
  URL="http://hemeroteca.lavanguardia.com/search.html"
  SEARCH="q=sabatinas+intempestivas&bd=$DAY&bm=$MONTH&by=$YEAR&ed=$DAY&em=$MONTH&ey=$YEAR"
  URL2="$URL?$SEARCH"
  PDF_URL0=$(curl -L -b $COOKIES -c $COOKIES -sS "$URL2" |  
             grep -o "http://hemeroteca.*pdf.html" | head -n1)
  debug "GET $PDF_URL0"
  PDF_URL=$(curl -L -b $COOKIES -c $COOKIES -sS "$PDF_URL0" |  
            grep -o "http://hemeroteca-paginas.lavanguardia[^\"]*" | head -n1)
  debug "GET $PDF_URL"   
  curl -b $COOKIES -c $COOKIES -L -o $FILENAME "$PDF_URL"
  echo $FILENAME
}

#read USER PASSWORD < /etc/lvg-auth.conf 
#COOKIES=$(login $USER $PASSWORD)
DATE=$(date --date="35 days ago" "+%Y-%m-%d")
download "cookies.txt" "$DATE" # $COOKIES
