#!/bin/bash
#
# Loop command execution
#
# - Simple example: Run 'myapp arg1 arg2' until it succeeds:
#
# $ loop command arg1 arg2
#
# - Complex example: Run 'command arg1 arg2' until the return value is NOT  
#   1, 2, 3 or 10. In addition, loop over the command at most 5 times and never 
#   for more than 2 minutes.
#
# $ loop -n -b "{1..3} 10" -m 5 -t 2m command arg1 arg2
# 
# You can use Bash intervals syntax {START..END} for statuses, but make sure you quote them. 
#
set -e

QUIET=0

# Write to standard error
stderr() { echo "$@" >&2; }

# Write to standard error unless QUIET is enabled (1)
debug() { test "$QUIET" -ne 1 && stderr "--- $@" || true; }

# Return an infinite sequence (starts at 1). For-loops are boring. 
infinite_seq() { yes "" | sed -n "="; }

# Succeed if regexp $2 is found in $1
word_in_list() { grep -qw "$2" <<< "$1"; }

# Run command ($@) and return 1 if ok, 0 if failed
tobool() { "$@" > /dev/null && echo 1 || echo 0; }

# Loop over a command. Return values:
#
#   0: Command run successfully
#   3: Timeout reached
#   4: Max retries reached
loop() {
  local MAXTRIES=$1; local LOOPWAIT=$2; local TIMEOUT=$3; 
  local BREAK_RETVALS=${4:-0}; local COMPLEMENT=${5:-0}; 
  local FOREVER=$6; local CHECK=$7
  shift 7
  
  local BREAK_RETVALS=$(eval echo $BREAK_RETVALS)
  local ITIME=$(date +%s)
  local RETVAL=
  exec 3<&0
   
  while read TRY; do
    "$@" <&3 && RETVAL=0 || RETVAL=$?
    debug "try=$TRY, retval: $RETVAL (break on: $BREAK_RETVALS, comp: $COMPLEMENT)"
    
    test "$FOREVER" = 1 && continue
    
    if test "$CHECK"; then
      debug "running check command: $CHECK"
      $CHECK < /dev/null && RETVAL=0 || RETVAL=$?
      debug "override retval with the value returned by the check command: $RETVAL"
    fi
    
    INARRAY=$(tobool word_in_list "$BREAK_RETVALS" $RETVAL)
    if test \( $INARRAY -eq 1 -a "$COMPLEMENT" -eq 0 \) -o \
            \( $INARRAY -eq 0 -a "$COMPLEMENT" -eq 1 \); then
      return 0    
    elif test "$TIMEOUT" && test $(($(date +%s) - $ITIME + $LOOPWAIT)) -gt $TIMEOUT; then
      debug "timeout reached: $TIMEOUT"
      return 3
    fi
    sleep $LOOPWAIT
  done < <(test "$MAXTRIES" && seq $MAXTRIES || infinite_seq)
  debug "max retries reached: $MAXTRIES"  
  return 4
}  

usage() {
  stderr -e "Usage: $(basename $0) [OPTIONS] COMMAND [ARGS ...]\n"
  stderr -e "Run command until the command is successful.\n"
  stderr "Options:"
  stderr "  -q:          Be quiet"
  stderr "  -c:          Complement the break statuses (see -b)."
  stderr "  -f:          Force a never-ending loop."
  stderr "  -k COMMAND:  Run command and use its output as status code" 
  stderr "  -b STATUSES: Space-separated list of statuses that break the loop."
  stderr "  -t SECONDS:  Maximum execution time before aborting the loop."
  stderr "  -m MAXTRIES: Maximum tries before aborting the loop."
  stderr "  -w SECONDS:  Time to wait between loop executions."
}

### Main

MAXTRIES=
LOOPWAIT=1
COMPLEMENT=0
FOREVER=0
BREAK_RETVALS=0
TIMEOUT=
CHECK=
test $# -eq 0 && set -- "-h"
while getopts "k:t:m:w:b:cqfh" ARG; do
  case "$ARG" in
  q) QUIET=1;;
  k) CHECK=$OPTARG;;
  m) MAXTRIES=$OPTARG;;
  w) LOOPWAIT=$OPTARG;;
  t) TIMEOUT=$OPTARG;;
  b) BREAK_RETVALS=$OPTARG;;
  c) COMPLEMENT=1;;
  f) FOREVER=1;;
  h) usage; exit 0;;
	*) usage; exit 2;;
	esac
done
shift $(($OPTIND-1))

loop "$MAXTRIES" "$LOOPWAIT" "$TIMEOUT" "$BREAK_RETVALS" "$COMPLEMENT" "$FOREVER" "$CHECK" "$@"
