#!/bin/bash
#
# Download radio episodes from the BBC website.
# 
# Example:
# 
#   $ bash download_episode.sh "http://www.bbc.co.uk/iplayer/episode/p005x3x5/World_Briefing_27_01_2010/"
#
# Author: Arnau Sanchez <tokland@gmail.com> 
# Date: January 2010
# Website: http://code.google.com/p/tokland/wiki/Projects
#
set -e

# Generic functions

debug() { echo "$@" >&2; }

parse() { local S=$(sed -n "s/^.*$1.*$/\1/p") && test "$S" && echo "$S"; }

parse_attr() { echo "$1" | parse "$2=\"\([^\"]*\)\""; }

match() { grep -q "$1" <<< "$2"; }

download() { curl -s "$@"; }

# RTMP functions

download_rtmp() {
  local HOST=$1
  local APP=$2
  local PLAYPATH=$3
  rtmpdump -r "rtmp://$HOST" -a "$APP" --playpath "$PLAYPATH" --flv -
}

# BBC functions

download_episode() {
  local URL=$1
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
  
  if match "wsondemandflash" "$CONNECTIONS"; then
    CONNECTION=$(echo "$CONNECTIONS" | grep "wsondemandflash" | head -n1)
    SERVER=$(parse_attr "$CONNECTION" "server")
    IDENTIFIER=$(parse_attr "$CONNECTION" "identifier" | recode html..utf8)
    debug "rtmp-wsondemandfash: server=$SERVER, identifier=$IDENTIFIER"
    download_rtmp "$SERVER" "ondemand" "$IDENTIFIER" > "$OUTPUT" || return 1
  elif match "bbcmedia.fcod.llnwd.net" "$CONNECTIONS"; then
    CONNECTION=$(echo "$CONNECTIONS" | grep 'bbcmedia.fcod.llnwd.net' | head -n1)
    SERVER=$(parse_attr "$CONNECTION" "server")
    IDENTIFIER=$(parse_attr "$CONNECTION" "identifier")
    APP=$(parse_attr "$CONNECTION" "application")
    AUTH=$(parse_attr "$CONNECTION" "authString")
    PLAYPATH=$(echo "$IDENTIFIER?$AUTH" | recode html..utf8)
    debug "rtmp-bbcmedia: server=$SERVER, APP=$app, identifier=$IDENTIFIER, auth=$AUTH"
    download_rtmp "$SERVER" "$APP" "$PLAYPATH" > "$OUTPUT" || return 1
  else
    debug "error: no known connection type to parse"
    return 2
  fi
  
  echo "$OUTPUT"
}

download_episodes() {
  local URL=$1
  if echo "$URL" | grep -q "www.bbc.co.uk/programmes"; then 
    EPISODES=$(download "$URL" | grep 'title="Listen now')
    parse_attr "$0EPISODES" "href" | while read EPISODE_URL; do
      debug "episode URL: $EPISODE_URL"
      download_episode "$EPISODE_URL"
    done
  else
    download_episode "$URL"
  fi
}

# Main

URL=$1
test "$URL" || 
  { debug "Usage: $(basename $0) CONSOLE_URL|EPISODE_URL|PROGRAMME_URL"; exit 1; }
download_episodes "$URL"
