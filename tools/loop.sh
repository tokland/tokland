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

# Write to standard error
stderr() { echo "$@" >&2; }

# Write to standard error unless QUIET is enabled (1)
debug() { test "$QUIET" -ne 1 && stderr "--- $@" || true; }

# Return an infinite sequence (starts at 1). For-loop are boring, let's use pipes. 
infinite_seq() { yes "" | sed -n "="; }

# Succeed if string $2 is inside $1
word_in_list() { grep -qw "$2" <<< "$1"; }

# Run wrapped command ($@) and return 1 if ok, 0 if failed
tobool() { "$@" > /dev/null && echo 1 || echo 0; }

###

# Loop over a command. Return values:
#
#   0: Command run successfully
#   3: Timeout reached
#   4: Max retries reached
loop() {
  local MAXTRIES=$1; local LOOPWAIT=$2; local TIMEOUT=$3; 
  local BREAK_RETVALS=${4:-0}; local NEGATE=${5:-0}
  shift 5
  
  BREAK_RETVALS=$(eval echo $BREAK_RETVALS)
  ITIME=$(date +%s)
  exec 3<&0
   
  while read TRY; do
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
  done < <(test "$MAXTRIES" && seq $MAXTRIES || infinite_seq)
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
