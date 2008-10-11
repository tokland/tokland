#!/bin/bash
#
# Download files from Rapidshare.
#
# Author: <tokland@gmail.com>.
#
set -e

# Match a Perl-style regular expression for a grepped line.
#
# $1: POSIX-regexp to get the first line that matches.
# $2: Perl-regexp to match (using parentheses) on the line.
match_line() { grep "$1" | head -n1 | perl -nle "print m/$2/"; }

# Echo text to standard error.
debug() { echo "$@" >&2; }

# Get a rapidshare file download url
#
# $1: A rapidshare URL
get_rapidshare_url() {
    URL=$1
    trap "rm -f \$TEMPFILE" SIGINT SIGHUP SIGTERM
    TEMPFILE=$(mktemp)
    while true; do
        WAIT_URL=$(wget -O - "$URL" | match_line '<form' 'action="(.*?)"')
        test "$WAIT_URL" || { debug "can't get wait main page URL"; return 2; }
        wget -O $TEMPFILE --post-data="dl.start=Free" "$WAIT_URL"
        LIMIT=$(cat $TEMPFILE | match_line "try again in about" "about (\d+) minut")
        if [ -z "$LIMIT" ]; then break; fi
        debug "download limit reached: waiting $LIMIT minutes"
        sleep ${LIMIT}m
    done
    FILE_URL=$(cat $TEMPFILE | match_line "<form " "action=\"(.*?)\"") 
    SLEEP=$(cat $TEMPFILE | match_line "^var c=" "c=(\d+);")
    rm -f $TEMPFILE
    trap SIGINT SIGHUP SIGTERM
    test "$FILE_URL"  || { debug "can't get file URL"; return 3; }
    debug "URL File: $FILE_URL" 
    test "$SLEEP"  || { debug "can't get sleep time"; SLEEP=100; }
    debug "Waiting $SLEEP seconds" 
    sleep $SLEEP
    echo $FILE_URL
}

# Main

if [ $# -eq 0 ]; then
    debug "usage: $0 URL|FILE [...]"
    exit 1
fi

for ITEM in "$@"; do
    if [ $(expr match "$ITEM" "http://") == 0 ]; then
        # Item is a file path (it should be one link per file)
        cat $ITEM | while read URL; do 
            get_rapidshare_url $URL | xargs wget
        done
    else
        # Item is a Rapidshare URL, download directly
        get_rapidshare_url $ITEM | xargs wget
    fi
done
