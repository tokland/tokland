#!/bin/bash
#
# Download files from Rapidshare.
#
# Contact: <tokland@gmail.com>.
#
set -e

# Echo text to standard error.
debug() { echo "$@" >&2; }

# Get first line that matches a regular expression and parse it.
#
# $1: POSIX-regexp to filter (get only the first matching line).
# $2: POSIX-regexp to match (using parentheses) on the matched line.
match_line() { sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1; }

# Output a rapidshare file download url given its Rapidshare URL
#
# $1: A rapidshare URL
get_rapidshare_url() {
    URL=$1
    # Get Wait URL (use a loop, because there is a download limit)
    while true; do
        WAIT_URL=$(wget -O - "$URL" | match_line '<form' 'action="\(.*\)"')
        test "$WAIT_URL" || { debug "can't get wait-page URL"; return 2; }
        DATA=$(wget -O - --post-data="dl.start=Free" "$WAIT_URL")
        LIMIT=$(echo "$DATA" | match_line "try again" "about \([[:digit:]]\+\) min")
        if [ -z "$LIMIT" ]; then break; fi
        debug "download limit reached: waiting $LIMIT minutes"
        sleep ${LIMIT}m
    done
    FILE_URL=$(echo "$DATA" | match_line "<form " 'action="\([^\"]*\)"') 
    SLEEP=$(echo "$DATA" | match_line "^var c=" "c=\([[:digit:]]\+\);")
    test "$FILE_URL" || { debug "can't get file URL"; return 3; }
    debug "URL File: $FILE_URL" 
    test "$SLEEP" || { debug "can't get sleep time"; SLEEP=100; }
    debug "Waiting $SLEEP seconds" 
    sleep $(($SLEEP + 1))
    echo $FILE_URL
}

# Check if a string is a http url
#
# $1: string to check
is_url() { test $(expr match "$1" "http://") -ne 0; }

### Main

if [ $# -eq 0 ]; then
    debug "usage: $(basename $0) URL|FILE [URL|FILE ...]"
    exit 1
fi

for ITEM in "$@"; do
    { is_url "$ITEM" && echo "$ITEM" || { cat $ITEM | grep -v "^#"; }; } | \
        while read URL; do
            FILE_URL=$(get_rapidshare_url "$URL")
            [ $? -eq 0 ] && wget "$FILE_URL"
        done
done
