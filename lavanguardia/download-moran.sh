#!/bin/bash
set -u -e -o pipefail

debug() { echo "$@" >&2; }

login() { local EMAIL=$1 PASSWORD=$2  
  local COOKIES="/tmp/cookies.txt"
  local URL="http://registrousuarios.lavanguardia.com/accesoJson.html"
  local PARAMS="email=$EMAIL&password=$PASSWORD&callback=loginForm_1626708556"
  debug "GET $URL"
  curl -sS -c $COOKIES "$URL?$PARAMS" >/dev/null || return 1
  echo $COOKIES
}

download() { local COOKIES=$1; local DATE=$2
  test "$DATE" || DATE=$(date "+%Y-%m-%d")
  IFS="-" read YEAR MONTH DAY <<< "$DATE"
  FILENAME="lvg-moran-$YEAR-$MONTH-$DAY.pdf"
  #URL="http://hemeroteca.lavanguardia.com/dynamic/edition/editionThumbnails.html"
  URL="http://hemeroteca.lavanguardia.com/search.html"
  SEARCH="q=sabatinas+intempestivas&bd=$DAY&bm=$MONTH&by=$YEAR&ed=$DAY&em=$MONTH&ey=$YEAR"
  URL2="$URL?$SEARCH"
  PDF_URL0=$(curl -L -b $COOKIES -c $COOKIES -sS "$URL2" |  
             grep -o "http://hemeroteca.*pdf.html" | head -n1) || return 1
  debug "GET $PDF_URL0"
  PDF_URL=$(curl -L -b $COOKIES -c $COOKIES -sS "$PDF_URL0" |  
            grep -o "http://hemeroteca-paginas.lavanguardia[^\"]*" | head -n1) || return 1
  debug "GET $PDF_URL"   
  curl -sS -b $COOKIES -c $COOKIES -L -o $FILENAME "$PDF_URL" || return 1
  echo $FILENAME
}

#read USER PASSWORD < /etc/lvg-auth.conf 
#COOKIES=$(login $USER $PASSWORD)
#DATE=$(date --date="35 days ago" "+%Y-%m-%d")
read USER PASSWORD < auth 
COOKIES=$(login $USER $PASSWORD)
DATE=$(date "+%Y-%m-%d")
download "$COOKIES" "$DATE"
