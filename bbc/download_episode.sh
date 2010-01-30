#!/bin/bash
#
# Download radio episodes from the BBC website.
# 
# Example: 
#   $ bash download_episode.sh "http://www.bbc.co.uk/iplayer/episode/p005x3x5/World_Briefing_27_01_2010/"
#
# Author: Arnau Sanchez <tokland@gmail.com> (January 2010)
#
# Website: http://code.google.com/p/tokland/wiki/Projects
#
set -e

debug() { echo "$@" >&2; }

parse() { local S=$(sed -n "s/^.*$1.*$/\1/p") && test "$S" && echo "$S"; }

download() { curl -s "$@"; }

download_rtmp() {
  local HOST=$1
  local STREAM_NAME=$2
  rtmpdump -r "rtmp://$HOST/ondemand?slist=$STREAM_NAME" --flv -
}

download_episode() {
  EPISODE=$(echo $URL | grep -o "episode/[^/]*" | cut -d"/" -f2) ||
    { debug "cannot parse episode: $URL"; return 1; }
  debug "episode: $EPISODE"
  EPISODE_XML=$(download "http://www.bbc.co.uk/iplayer/playlist/$EPISODE") || return 1
  TITLE=$(echo "$EPISODE_XML" | grep "<title>" | head -n1 | 
    parse '<title>\(.*\)<\/title>') || return 1
  debug "title: $TITLE"
  ITEM=$(echo "$EPISODE_XML" | grep "<item " | parse 'identifier="\([^"]*\)"') || return 1
  XML=$(download "http://www.bbc.co.uk/mediaselector/4/mtis/stream/$ITEM") || return 1
  echo $XML | sed "s/>/>\n/g" | grep "<connection" | grep "wsondemandflash" | while read CONNECTION; do
    SERVER=$(echo $CONNECTION | parse 'server="\([^"]*\)"')
    IDENTIFIER=$(echo $CONNECTION | parse 'identifier="\([^"]*\)"')
    debug "rtmp: server=$SERVER, identifier=$IDENTIFIER"
    OUTPUT=$(echo "$TITLE.flv" | sed "s/\//_/g")
    download_rtmp "$SERVER" "$IDENTIFIER" > "$OUTPUT" || return 1
    echo "$OUTPUT"
  done
}

# Main

URL=$1
test "$URL" || { debug "Usage: $(basename $0) EPISODE_URL"; exit 1; }
download_episode "$URL"
