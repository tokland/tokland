#!/bin/bash
set -e

tomp3() {
  local INPUT=$1; local OUTPUT=$2; local LAMEOPTS=$3  
  mplayer -vc null -vo null -ao "pcm:file=$OUTPUT.wav" "$INPUT" < /dev/null
  twolame $LAMEOPTS "$OUTPUT.wav" "$OUTPUT"
}

test $# -gt 0 || exit 2

LINKSFILE=$1
while read URL; do
  tomp3 "$URL" "$(basename "$URL")".mp3 "-V2"
done < $LINKSFILE
