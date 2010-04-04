#!/bin/bash

# Download files from Rapidshare.
#
# Dependencies: curl
#
# Web: http://code.google.com/p/megaupload-dl/wiki/RapidShare
# Web: http://code.google.com/p/plowshare
# Contact: Arnau Sanchez <tokland@gmail.com>.
#
# License: GNU GPL v3.0: http://www.gnu.org/licenses/gpl-3.0-standalone.html

set -e

# Echo a debug message to stderr.
debug() { echo "$@" >&2; }

# Echo a error message to stderr.
error() { debug "ERROR: $@"; }

# Get first line that matches a regular expression ($1) and parse a string ($2)
parse() { S=$(sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1) && test "$S" && echo "$S"; }

# Check if a regexp ($1) matches a string ($2)
match() { grep -q "$1" <<< "$2"; }

# Output the file URL for a Rapidshare link ($1)
get_rapidshare_file_url() {
    URL=$1
    while true; do
        PAGE=$(curl "$URL") || 
            { error "cannot get main page"; return 1; }
        WAIT_URL=$(echo "$PAGE" | parse '<form' 'action="\(.*\)"') ||
            { error "file not found"; return 2; }
        DATA=$(curl --data "dl.start=Free" "$WAIT_URL") || 
            { error "can't get wait URL contents"; return 1; }
        WAIT=$(echo "$DATA" | parse "try again" "\(\<[[:digit:]]\+\>\) minute") || 
            break 
        debug "download limit reached: waiting $WAIT minutes"
        sleep ${WAIT}m
    done
    FILE_URL=$(echo "$DATA" | parse "<form " 'action="\([^\"]*\)"') ||
        { error "cannot parse form"; return 1; }
    debug "File URL: $FILE_URL" 
    SLEEP=$(echo "$DATA" | parse "^var c=" "c=\([[:digit:]]\+\);") ||
        { error "can't get sleep time"; return 1; }
    debug "Waiting $SLEEP seconds" 
    sleep $SLEEP
    echo $FILE_URL    
}

# Return Rapidshare URL (detecting if $1 is a RS URL or a file with links)
process_item() {
    ITEM=$1
    if match "\(http://\)\?\(www\.\)\?rapidshare.com/" "$ITEM"; then        
        echo "$ITEM" # Rapidshare URL 
    else 
        grep -v "^[[:space:]]*\(#\|$\)" -- "$ITEM" # File with links (one per line)
    fi
}

### Main

test "$TESTMODE" = "1" && return
test $# -ge 1 || {
    debug "usage: $(basename "$0") RAPIDSHARE_URL|FILE_WITH_LINKS [...]"
    exit 2
}

RETVAL=0
for ITEM in "$@"; do
    process_item "$ITEM" | while read URL; do
        debug "start download: $URL"
        FILE_URL=$(get_rapidshare_file_url "$URL") ||
            { error "processing URL: $URL"; RETVAL=1; continue; }        
        FILE=$(basename "$FILE_URL") 
        curl -o "$FILE" "$FILE_URL" ||
            { error "cannot download file: $FILE_URL"; RETVAL=1; continue; } 
        echo "$FILE" 
    done
done
exit $RETVAL
