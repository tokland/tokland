#!/bin/bash
#
# Upload using multiupload website (implementation not complete)
#
# 2008 Arnau Sanchez <tokland@gmail.com>
# License: GNU/GPL
# 
# Example:
#
# $ bash multiupload.sh "5 11" /etc/services "Services"
#
# This will upload /etc/services with description "Services" to 
# websites 5 (Rapidshare) and 11 (2shared)
 
set -e

debug() { echo "$@" >&2; }

parse() { 
  local STRING=$(sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1) && 
    test "$STRING" && echo "$STRING" || 
    { debug "parse failed: /$1/ $2"; return 1; } 
}

multiupload_upload() {
  SERVICES=$1
  FILE=$2
  DESCRIPTION=$3
  
  URL="http://www.multiupload.com"
  PAGE=$(curl -s "$URL")
  UPLOAD_IDENTIFIER=$(echo "$PAGE" | parse "UPLOAD_IDENTIFIER" 'value="\([^"]*\)"') || return 1
  U_VALUE=$(echo "$PAGE" | parse 'name="u"' 'value="\([^"]*\)"') || return 1
  UPLOAD_URL="$URL/upload/?UPLOAD_IDENTIFIER=$UPLOAD_IDENTIFIER"
  SERVICE_OPTS=($(echo "$SERVICES" | xargs -n1 | xargs -i echo -F "service_{}=1"))

  RESPONSE=$(curl -s --referer "$URL" \
    -F "u=$U_VALUE" \
    -F "file_0=@$FILE" \
    -F "description_0=$DESCRIPTION" \
    ${SERVICE_OPTS[@]} \
    "$UPLOAD_URL") || return 1
      
  ID=$(echo "$RESPONSE" | parse 'downloadid' '"downloadid":"\([^"]\+\)"') || return 1
  echo "http://www.multiupload.com/$ID"
}

test $# -eq 3 || { debug "Usage: $(basename $0) SERVICES_ARRAY FILE DESCRIPTION"; exit 1; }
multiupload_upload "$@"
