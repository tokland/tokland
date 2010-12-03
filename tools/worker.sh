#!/bin/bash
#
# Run a command using as lines from files (one at at time) as arguments
# Also, mark the successful arguments (#) or the non-retryable (#ERROR_CODE)
#
# Let's see an example:
#
#   $ cat file.txt
#   file1
#   file2
#   file3

#   $ worker -r "3 4" file.txt process
#
#   $ cat file.txt
#   # file1
#   #1 file2
#   file3
#
# In the example "process file1" was successful, "process file2" was not (it
# returned error code 1), and "process file3" must have returned a retryable error
# (either 3 or 4) because 'file3' is not marked. Running the worker again would 
# only try 'file3' again (commented lines are ignored).
#
set -e

# Echo a message to stderr
stderr() { echo -e "$@" >&2; }

# Echo an info message to stderr
info() { stderr "--- $@"; }
  
# Check if regexp word $1 is found in string $2
word_in_list() { grep -qw "$1" <<< "$2"; }

worker() {
  local FILE=$1
  local RETRYABLE0=$2
  eval "RETVAL_KEYS=$3"
  shift 3
  
  local RETRYABLE=$(eval echo $RETRYABLE0)  
  local RETVAL=0
  while read ARGS; do
    info "run: $@ $ARGS"
    "$@" $ARGS && RV=0 || RV=$?
    info "exit status: $RV"    
    if word_in_list $RV "$RETRYABLE"; then
      RETVAL=2
    else
      CODE=$(test $RV -ne 0 && echo ${RETVAL_KEYS[$RV]:-$RV} || true)
      info "mark file with exit status: $FILE (#$CODE)"
      sed -i "s|$ARGS|#$CODE $ARGS|" "$FILE"      
    fi
  done < <(grep -v "^#" "$FILE" | grep -v "^[[:space:]]*$")
  return $RETVAL
}

usage() {
  stderr "Usage: $(basename $0) [-r RETRYABLE_CODES] FILE_WITH_ARGS COMMAND [ARGS]\n"
  stderr "  Run executable using lines in files as arguments and mark the exit code"
}

# Main
set -e -u -o pipefail
RETRYABLE_RETVALS=
RETVAL_KEYS=
test $# -eq 0 && set -- "-h"
while getopts "r:s:h" ARG; do
  case "$ARG" in
  r) RETRYABLE_RETVALS=$OPTARG;;
  s) RETVAL_KEYS=$OPTARG;;
  h) usage; exit 0;;    
  *) usage; exit 2;;
  esac
done
shift $(($OPTIND-1))
FILE=$1
shift 1
worker "$FILE" "$RETRYABLE_RETVALS" "$RETVAL_KEYS" "$@"
