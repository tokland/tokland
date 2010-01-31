#!/bin/bash
set -e

debug() { echo "$@" >&2; }

assert_match() {
  test "$1" = "$2" || {
    debug "assert_match failed: $1 != $2"
    return 1
  }
}

run_tests() {
  local RETVAL=0
  for FUNC in $*; do 
    debug -n "$FUNC... "  
    $FUNC && debug "ok" || { debug "failed"; RETVAL=1; }
  done 
  return $RETVAL
}

###

download() {
  bash download_episode.sh "$1" 2>/dev/null
}

test_iplayer_episode() {
  URL="http://www.bbc.co.uk/iplayer/episode/p005x3x5/World_Briefing_27_01_2010/"
  assert_match "World Briefing: 27_01_2010.flv" "$(download "$URL")" 
}  

test_iplayer_console() {
  URL="http://www.bbc.co.uk/iplayer/console/b00pg5rj"
  assert_match "The Film Programme: 01_01_2010.flv" "$(download "$URL")" 
}  
  
run_tests "test_iplayer_episode" "test_iplayer_console"
