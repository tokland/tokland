#!/bin/bash
#
# Download a file from Rapidshare.
#
# Author: <tokland@gmail.com> September 2008.
#
set -e

# Match a Perl-style regular expression for a grepped line.
#
# $1: POSIX-regexp to get the first line that matches
# $2: Perl-regexp to match (use parentheses) a portion of the line.
match_line() { grep "$1" | head -n1 | perl -nle "print m/$2/"; }

# Echo text to standard error.
debug() { echo "$@" >&2; }

# Get a rapidshare file download url
#
# $1: Rapidshare URL
get_rapidshare_url() {
    URL=$1 
    WAIT_URL=$(wget -O - "$URL" | match_line '<form' 'action="(.*?)"')
    test "$WAIT_URL" || { debug "can't get wait main page URL"; return 2; }
    trap "rm -f \$TEMPFILE" SIGINT SIGHUP SIGTERM
    TEMPFILE=$(mktemp)
    wget -O $TEMPFILE --post-data="dl.start=Free" "$WAIT_URL" 
    FILE_URL=$(cat $TEMPFILE | match_line "document.dlf" "action=\\\\'(.*?)\\\\'")
    SLEEP=$(cat $TEMPFILE | match_line "^var c=" "c=(\d+);")
    rm -f $TEMPFILE
    trap SIGINT SIGHUP SIGTERM
    test "$FILE_URL"  || { debug "can't get file URL"; return 3; }
    test "$SLEEP"  || { debug "can't get sleep time"; SLEEP=100; }
    debug "URL File: $FILE_URL" 
    debug "Waiting $SLEEP seconds" 
    sleep $SLEEP
    echo $FILE_URL
}

# Main

URL=$1 
test "$URL" || { debug "usage: $0 rapidshare_url"; exit 1; }
FILE_URL=$(get_rapidshare_url "$URL")
test "$FILE_URL" && wget -c "$FILE_URL"
