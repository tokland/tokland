#!/bin/bash
set -e

debug() { echo "$@" >&2; }
repeat_string() { printf -v f "%$1s" ; printf "%s\n" "${f// /$2}"; }

debug_state() { debug -n -e "\r$1$(repeat_string ${#1} '\b')"; }


BINARY=0
test "$1" = "--binary" -o "$1" = "-b" && BINARY=1

NCHARS=0
NLINES=0
SPEED_LINES=
SPEED_CHARS=

NCOLS=${COLUMNS:-80}
ITIME=$(date +%s)
LAST_SPEED_TIME=0

while read LINE; do
  NCHARS=$(($NCHARS + ${#LINE}))
  ELAPSED=$(($(date +%s) - $ITIME))
  NLINES=$(($NLINES + 1))
  if test $ELAPSED -ne $LAST_SPEED_TIME; then
    SPEED_LINES=$(($NLINES / $ELAPSED))
    SPEED_CHARS=$(($NCHARS / $ELAPSED))
    LAST_SPEED_TIME=$ELAPSED
  fi
  debug_state "$NCHARS (${SPEED_CHARS:--} chars/sec) - $NLINES (${SPEED_LINES:--} lines/sec)"  
  echo $LINE
done

debug
