#!/bin/bash
#
# Loop execution until a return value condition is matched
#
# - Example 1: Run 'myapp arg1 arg2' until it succeeds:
#
# $ loop myapp arg1 arg2
#
# - Example 2: Run 'myapp arg1 arg2' until return value is one of 1, 2, 3 or 10. 
#   Tries to run the command at most 5 times and never loop more than 2 minutes.
#
# $ loop -b "{1..3} 10" -m 5 -t 2m myapp arg1 arg2
# 
# Note that you can use bash {START..END} notation for return values.
#
set -e

debug() { test "$QUIET" -ne 1 && echo "--- $@" >&2; }

infinite_seq() { yes "" | sed -n "="; }

word_in_list() { grep -qw "$2" <<< "$1"; }

loop() {
  local MAXTRIES=$1; local LOOPWAIT=$2; local TIMEOUT=$3; 
  local BREAK_RETVALS=${4:-0}; local NEGATE=${5:-0}
  shift 5
  
  BREAK_RETVALS=$(eval echo $BREAK_RETVALS)
  ITIME=$(date +%s)
  { test "$MAXTRIES" && seq $MAXTRIES || infinite_seq; } | while read TRY; do
    "$@" && RETVAL=0 || RETVAL=$?
    word_in_list "$BREAK_RETVALS" $RETVAL && INARRAY=1 || INARRAY=0 
    debug "try=$TRY, retval: $RETVAL (break retvals: $BREAK_RETVALS, negate: $NEGATE)"
    test \( $INARRAY -eq 1 -a "$NEGATE" -eq 0 \) -o \
         \( $INARRAY -eq 0 -a "$NEGATE" -eq 1 \) && return 0
    test "$TIMEOUT" && expr $(date +%s) - $ITIME + $LOOPWAIT \> $TIMEOUT >/dev/null && {
      debug "timeout reached: $TIMEOUT"
      return 2
    } 
	  sleep $LOOPWAIT
  done
  return 1
}  

MAXTRIES=
LOOPWAIT=1 
QUIET=0
NEGATE=0
TIMEOUT=
BREAK_RETVALS=
while getopts "t:m:w:b:nqh" ARG; do
  case "$ARG" in
  q) QUIET=1;;
	m) MAXTRIES=$OPTARG;;
	w) LOOPWAIT=$OPTARG;;
	t) TIMEOUT=$OPTARG;;
	b) BREAK_RETVALS=$OPTARG;;
	n) NEGATE=1;;
	h) debug "Usage: $(basename $0) [-q] [-n] [-b BREAK_RETVALS] [-m MAXTRIES] \ 
	        [-w LOOPWAIT] [-t TIMEOUT] COMMAND [ARGS]"
		 exit 1;;
	esac
done
shift $(($OPTIND-1))

loop "$MAXTRIES" "$LOOPWAIT" "$TIMEOUT" "$BREAK_RETVALS" "$NEGATE" "$@"
