#!/bin/bash
set -u -e -o pipefail

debug() { echo "$@" >&2; }

login() { local EMAIL=$1 PASSWORD=$2  
  local COOKIES="cookies.txt"
  local URL="http://hemeroteca.lavanguardia.com/dynamic/edition/login.html"
  local PARAMS="email=$EMAIL&password=$PASSWORD"
  debug "GET $URL"
  curl -sS -c $COOKIES "$URL?$PARAMS" || return 1
  echo $COOKIES
}

download() { local COOKIES=$1 DATE=$2
  IFS="-" read YEAR MONTH DAY <<< "$DATE"
  FILENAME="lvg-chess-$(echo $DATE | tr -d ' ').pdf"

  SEARCH_URL="http://hemeroteca.lavanguardia.com/search.html?q=els+mots+encreuats&bd=$DAY&bm=$MONTH&by=$YEAR&ed=$DAY&em=$MONTH&ey=$YEAR&keywords=els+mots+encreuats"
  
  PDF_URL0=$(
    curl -b $COOKIES -c $COOKIES -sS "$SEARCH_URL" |
      grep '<a class="edicion"' | 
      grep -m1 -o 'href="[^"]*"' | 
      cut -d"=" -f2 | tr -d '"'
  ) 
  
#  URL="http://hemeroteca.lavanguardia.com/edition.html"
#    
#  URL2="$URL?edition=Vivir+Barcelona+Cat&bd=$DAY&bm=$MONTH&by=$YEAR&page=2"
#  debug "GET $URL2"
#  PDF_URL0=$(curl -L -b $COOKIES -c $COOKIES -sS "$URL2" |   
#             grep -o "http://hemeroteca.*pagina-10.*.pdf.html" | head -n1)
#  test "$PDF_URL0" || return 1
#  debug "GET $PDF_URL0"
  PDF_URL=$(curl -L -b $COOKIES -c $COOKIES -sS "$PDF_URL0" |  
            grep -o "http://hemeroteca-paginas.lavanguardia[^\"]*" | head -n1)
  test "$PDF_URL" || return 1
  debug "GET $PDF_URL"   
  curl -b $COOKIES -c $COOKIES -L -o $FILENAME "$PDF_URL" || return 1
  echo $FILENAME
}

DEFAULT_DATE=$(date "+%Y-%m-%d")
DATE=${1:-$DEFAULT_DATE}
read USER PASSWORD < auth 
#COOKIES=$(login $USER $PASSWORD)
COOKIES=cookies.txt
download "$COOKIES" "$DATE"
