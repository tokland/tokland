#!/bin/bash
#
# Loop execution until a return value condition is matched
#
# - Simple example: Run 'myapp arg1 arg2' until it succeeds:
#
# $ loop myapp arg1 arg2
#
# - Complete example: Run 'myapp arg1 arg2' until the return value is NOT one 
#   of 1, 2, 3 or 10. Loop over the command at most 5 times and never for 
#   more than 2 minutes.
#
# $ loop -n -b "{1..3} 10" -m 5 -t 2m myapp arg1 arg2
# 
# See how you can use bash intervals notation ({START..END}) for return 
# values (this will be expanded in the script, so quote them)

set -e

# Global variables

QUIET=0

# Generic functions

stderr() { echo "$@" >&2; }

debug() { test "$QUIET" -ne 1 && stderr "--- $@"; }

infinite_seq() { yes "" | sed -n "="; }

word_in_list() { grep -qw "$2" <<< "$1"; }

tobool() { "$@" > /dev/null && echo 1 || echo 0; }

###

loop() {
  local MAXTRIES=$1; local LOOPWAIT=$2; local TIMEOUT=$3; 
  local BREAK_RETVALS=${4:-0}; local NEGATE=${5:-0}
  shift 5
  
  BREAK_RETVALS=$(eval echo $BREAK_RETVALS)
  ITIME=$(date +%s)
  exec 3<&0
   
  { test "$MAXTRIES" && seq $MAXTRIES || infinite_seq; } | while read TRY; do
    "$@" <&3 && RETVAL=0 || RETVAL=$?
    INARRAY=$(tobool word_in_list "$BREAK_RETVALS" $RETVAL)
    debug "try=$TRY, retval: $RETVAL (break retvals: $BREAK_RETVALS, negate: $NEGATE)"
    test \( $INARRAY -eq 1 -a "$NEGATE" -eq 0 \) -o \
         \( $INARRAY -eq 0 -a "$NEGATE" -eq 1 \) && return 0
    test "$TIMEOUT" && expr $(date +%s) - $ITIME + $LOOPWAIT \> $TIMEOUT >/dev/null && {
      debug "timeout reached: $TIMEOUT"
      return 3
    } 
	  sleep $LOOPWAIT
  done
  
  debug "max retries reached: $MAXTRIES"  
  return 4
}  

usage() {
  stderr "Usage: $(basename $0) [-q] [-n] [-b BREAK_RETVALS (default: 0)] [-m MAXTRIES]  
           [-w LOOPWAIT] [-t TIMEOUT] COMMAND [ARGS]"
}

### Main

MAXTRIES=
LOOPWAIT=1 
NEGATE=0
TIMEOUT=
BREAK_RETVALS=
test $# -eq 0 && set -- "-h"
while getopts "t:m:w:b:nqh" ARG; do
  case "$ARG" in
  q) QUIET=1;;
  m) MAXTRIES=$OPTARG;;
  w) LOOPWAIT=$OPTARG;;
  t) TIMEOUT=$OPTARG;;
  b) BREAK_RETVALS=$OPTARG;;
  n) NEGATE=1;;
  h) usage; exit 2;;
	*) usage; exit 2;;
	esac
done
shift $(($OPTIND-1))

loop "$MAXTRIES" "$LOOPWAIT" "$TIMEOUT" "$BREAK_RETVALS" "$NEGATE" "$@"
