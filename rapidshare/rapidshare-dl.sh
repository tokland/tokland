#!/bin/bash
#
# Download files from Rapidshare.
#
# Author: <tokland@gmail.com>.
#
set -e

# Get first line that matches a regular expression and parse it.
#
# $1: POSIX-regexp to filter (get only the first matching line).
# $2: POSIX-regexp to match (using parentheses) on the matched line.
match_line() { sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1; }

# Echo text to standard error.
debug() { echo "$@" >&2; }

# Get a rapidshare file download url
#
# $1: A rapidshare URL
get_rapidshare_url() {
    URL=$1
    while true; do
        WAIT_URL=$(wget -O - "$URL" | match_line '<form' 'action="\(.*\)"')
        test "$WAIT_URL" || { debug "can't get wait-page URL"; return 2; }
        DATA=$(wget -O - --post-data="dl.start=Free" "$WAIT_URL")
        LIMIT=$(echo "$DATA" | match_line "try again" "about \([[:digit:]]\+\) min")
        if [ -z "$LIMIT" ]; then break; fi
        debug "download limit reached: waiting $LIMIT minutes"
        sleep ${LIMIT}m
    done
    FILE_URL=$(echo "$DATA" | match_line "<form " 'action="\(.*\)"') 
    SLEEP=$(echo "$DATA" | match_line "^var c=" "c=\([[:digit:]]\+\);")
    test "$FILE_URL" || { debug "can't get file URL"; return 3; }
    debug "URL File: $FILE_URL" 
    test "$SLEEP" || { debug "can't get sleep time"; SLEEP=100; }
    debug "Waiting $SLEEP seconds" 
    sleep $(($SLEEP + 1))
    echo $FILE_URL
}

# Main

if [ $# -eq 0 ]; then
    debug "usage: $(basename $0) URL|FILE [URL|FILE ...]"
    exit 1
fi

for ITEM in "$@"; do
    if [ $(expr match "$ITEM" "http://") == 0 ]; then
        # Item is not an URL, treat as file path (expecting one link per file)
        while read URL; do 
            get_rapidshare_url "$URL" | xargs -r wget
        done < "$ITEM"
    else
        # Item is a Rapidshare URL, download directly
        get_rapidshare_url "$ITEM" | xargs -r wget
    fi
done
