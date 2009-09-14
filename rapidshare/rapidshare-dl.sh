#!/bin/bash
#
# Download files from Rapidshare using free access (NOT premium accounts).
# Output files downloaded to standard output (one per line).
#
# Dependencies: sed, sleep, expr, wget.
#
# Web: http://code.google.com/p/megaupload-dl/wiki/RapidShare
# Contact: Arnau Sanchez <tokland@gmail.com>.
#
# License: GNU GPL v3.0: http://www.gnu.org/licenses/gpl-3.0-standalone.html
#
set -e

# Echo text to standard error.
#
debug() { echo "$@" >&2; }

# Get first line that matches a regular expression and extract string from it.
#
# $1: POSIX-regexp to filter (get only the first matching line).
# $2: POSIX-regexp to match (use parentheses) on the matched line.
#
parse() { sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1; }

# Check if a string ($2) matchs a regexp ($1)
#
match() { grep -q "$1" <<< "$2"; }

# Output a rapidshare file download URL given its rapidshare URL
#
# $1: A rapidshare URL
#
get_rapidshare_file_url() {
    URL=$1
    while true; do
        WAIT_URL=$(wget -O - "$URL" | parse '<form' 'action="\(.*\)"')
        test "$WAIT_URL" || { debug "file not found"; return 2; }
        DATA=$(wget -O - --post-data="dl.start=Free" "$WAIT_URL")
        test "$DATA" || { debug "can't get wait URL contents"; return 2; }
        LIMIT=$(echo "$DATA" | parse "try again" "\(\<[[:digit:]]\+\>\) minutes")
        test -z "$LIMIT" && break
        debug "download limit reached: waiting $LIMIT minutes"
        sleep ${LIMIT}m
    done
    FILE_URL=$(echo "$DATA" | parse "<form " 'action="\([^\"]*\)"') 
    SLEEP=$(echo "$DATA" | parse "^var c=" "c=\([[:digit:]]\+\);")
    test "$FILE_URL" || { debug "can't get file URL"; return 2; }
    debug "URL File: $FILE_URL" 
    test "$SLEEP" || { debug "can't get sleep time"; SLEEP=100; }
    debug "Waiting $SLEEP seconds" 
    sleep $(($SLEEP + 1))
    echo $FILE_URL    
}

# Guess is item is a rapidshare URL, a generic URL (to start a download)
# or a file with links
#
process_item() {
    ITEM=$1
    BASEURL="\(http://\)\?\(www\.\)\?rapidshare.com/files"
    if match "^$BASEURL/" "$ITEM"; then
        # Rapidshare URL
        echo "$ITEM" 
    elif match "^\(http://\)" "$ITEM"; then
        # Non-rapidshare URL, extract RS links (highly fallible!) and download
        wget -O - "$ITEM" | tr -d '\r' | grep -o "$BASEURL/[^\"<>]\+" | uniq
    else 
        # Assume it's a file and read links (discard comments and empty lines)
        grep -v "^[[:space:]]*\(#\|$\)" -- "$ITEM"
    fi
}

# Don't run main code on testing
#
test "$TESTMODE" = "1" && return

# Main
#
if test $# -eq 0; then
    debug "usage: $(basename $0) RS_URL|URL|FILE [RS_URL|URL|FILE ...]"
    exit 1
fi

for ITEM in "$@"; do
    process_item "$ITEM" | while read URL; do
        debug "start download: $URL"
        FILE_URL=$(get_rapidshare_file_url "$URL") && 
            wget "$FILE_URL" && echo $(basename "$FILE_URL") ||
            debug "could not download: $URL" 
    done
done
