#!/bin/bash
#
# Download files from Rapidshare using free access (NOT premium accounts).
# Outputs files downloaded to standard output.
#
# Dependencies: sed, sleep, expr, wget.
#
# Web: http://code.google.com/p/megaupload-dl/wiki/RapidShare
# Contact: <tokland@gmail.com>.
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
match() { sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1; }

# Check if a string is (or seems) a rapidshare URL.
#
is_rapidshare_url() { 
    test ! -z $(expr match "$1" "^\(http://\|\(www\.\)\?rapidshare.com/files\)")
}

# Guess is item is a rapidshare URL or file (then return contents)
#
process_item() {
    ITEM=$1
    if is_rapidshare_url "$ITEM"; then
        echo "$ITEM" 
    else
        grep -v "^[[:space:]]*\(#\|$\)" -- "$ITEM" 
    fi
}

# Output a rapidshare file download URL given its rapidshare URL
#
# $1: A rapidshare URL
#
get_rapidshare_file_url() {
    URL=$1
    while true; do
        WAIT_URL=$(wget -O - "$URL" | match '<form' 'action="\(.*\)"')
        test "$WAIT_URL" || { debug "can't get wait-page URL"; return 1; }
        DATA=$(wget -O - --post-data="dl.start=Free" "$WAIT_URL")
        LIMIT=$(echo "$DATA" | match "try again" "about \([[:digit:]]\+\) min")
        test -z "$LIMIT" && break
        debug "download limit reached: waiting $LIMIT minutes"
        sleep ${LIMIT}m
    done
    FILE_URL=$(echo "$DATA" | match "<form " 'action="\([^\"]*\)"') 
    SLEEP=$(echo "$DATA" | match "^var c=" "c=\([[:digit:]]\+\);")
    test "$FILE_URL" || { debug "can't get file URL"; return 2; }
    debug "URL File: $FILE_URL" 
    test "$SLEEP" || { debug "can't get sleep time"; SLEEP=100; }
    debug "Waiting $SLEEP seconds" 
    sleep $(($SLEEP + 1))
    echo $FILE_URL    
}

# Return on testing (don't run main code)
#
test "$1" = "--test" && return

# Main
#
if test $# -eq 0; then
    debug "usage: $(basename $0) URL|FILE [URL|FILE ...]"
    exit 1
fi

for ITEM in "$@"; do
    process_item "$ITEM" | while read URL; do
        FILE_URL=$(get_rapidshare_file_url "$URL") && 
            wget "$FILE_URL" && echo $(basename "$FILE_URL") ||
            debug "could not download URL: $URL" 
    done
done
