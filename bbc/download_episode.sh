#!/bin/bash
#
# Download radio episodes from the BBC website.
# 
# Example:
# 
#   $ bash download_episode.sh "http://www.bbc.co.uk/iplayer/episode/p005x3x5/World_Briefing_27_01_2010/"
#
# Author: Arnau Sanchez <tokland@gmail.com> (January 2010)
#
# Website: http://code.google.com/p/tokland/wiki/Projects
#
set -e

debug() { echo "$@" >&2; }

parse() { local S=$(sed -n "s/^.*$1.*$/\1/p") && test "$S" && echo "$S"; }

parse_attr() { echo "$1" | parse "$2=\"\([^\"]*\)\""; }

download() { curl -s "$@"; }

download_rtmp() {
  local HOST=$1
  local APP=$2
  local PLAYPATH=$3
  rtmpdump -r "rtmp://$HOST" -a "$APP" --playpath "$PLAYPATH" --flv -
}

download_episode() {
  EPISODE=$(echo $URL | grep -o "\(episode\|console\)/[^/]*" | cut -d"/" -f2) 
  test "$EPISODE" || { debug "cannot parse episode: $URL"; return 1; }
  debug "episode: $EPISODE"
  EPISODE_XML=$(download "http://www.bbc.co.uk/iplayer/playlist/$EPISODE") || return 1
  TITLE=$(echo "$EPISODE_XML" | grep -A1 "<item " | tail -n1 |  
    parse '<title>\(.*\)<\/title>') || return 1
  debug "title: $TITLE"
  ITEM=$(echo "$EPISODE_XML" | grep "<item " | parse 'identifier="\([^"]*\)"') || return 1
  XML=$(download "http://www.bbc.co.uk/mediaselector/4/mtis/stream/$ITEM") || return 1
  CONNECTIONS=$(echo $XML | sed "s/>/>\n/g" | grep "<connection")
  OUTPUT=$(echo "$TITLE.flv" | sed "s/\//_/g")
  if echo "$CONNECTIONS" | grep -q "wsondemandflash"; then
    CONNECTION=$(echo "$CONNECTIONS" | grep "wsondemandflash" | head -n1)
    SERVER=$(parse_attr "$CONNECTION" "server")
    IDENTIFIER=$(parse_attr "$CONNECTION" "identifier" | recode html..utf8)
    debug "rtmp-wsondemandfash: server=$SERVER, identifier=$IDENTIFIER"
    download_rtmp "$SERVER" "ondemand" "$IDENTIFIER" > "$OUTPUT" || return 1
  elif echo "$CONNECTIONS" | grep -q 'bbcmedia.fcod.llnwd.net'; then
    CONNECTION=$(echo "$CONNECTIONS" | grep 'bbcmedia.fcod.llnwd.net' | head -n1)
    SERVER=$(parse_attr "$CONNECTION" "server")
    IDENTIFIER=$(parse_attr "$CONNECTION" "identifier")
    APP=$(parse_attr "$CONNECTION" "application")
    AUTH=$(parse_attr "$CONNECTION" "authString")
    PLAYPATH=$(echo "$IDENTIFIER?$AUTH" | recode html..utf8)
    debug "rtmp-bbcmedia: server=$SERVER, identifier=$IDENTIFIER, auth=$AUTH"
    download_rtmp "$SERVER" "$APP" "$PLAYPATH" > "$OUTPUT" || return 1
  fi
  echo "$OUTPUT"
}

# Main

URL=$1
test "$URL" || { debug "Usage: $(basename $0) EPISODE_URL"; exit 1; }
download_episode "$URL"
