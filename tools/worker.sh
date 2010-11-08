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
#
#   $ worker process "3 4" file.txt
#
#   $ cat file.txt
#   # file1
#   #1 file2
#   file3
#
# In the example "process file1" was successful, "process file2" was not (it
# returned error code 1), and "process file3" must have returned a retryable error
# (either 3 or 4) because 'file3' is not marked. Running the worker again would 
# only retry 'file3' (commented lines are ignored).
#
set -e

# Echo a message to stderr
stderr() { echo -e "$@" >&2; }

# Echo an info message to stderr
info() { stderr "--- $@"; }
  
# Check if regexp $1 is found in string $2
match() { grep -q "$1" <<< "$2"; }

# Check if regexp word $1 is found in string $2
word_in_list() { grep -qw "$1" <<< "$2"; }

worker() {
  local EXECUTABLE=$1
  local RETRYABLE=$2
  shift 2
  
  local RETVAL=0
  for FILE in "$@"; do 
    while read ARGS; do
      info "run: $EXECUTABLE $ARGS"
      $EXECUTABLE $ARGS && RV=0 || RV=$?
      info "exit status: $RV"    
      if word_in_list $RV "$RETRYABLE"; then
        RETVAL=2
      else
        CODE=$(test $RV -ne 0 && echo $RV || true)
        info "mark file with exit status: $FILE (#$CODE)"
        sed -i "s|$ARGS|#$CODE $ARGS|" "$FILE"      
      fi
    done < <(grep -v "^#" $FILE | grep -v "^[[:space:]]*$")
  done 
  return $RETVAL
}

if ! match "bash" "$0"; then
  set -e -u -o pipefail
  if test $# -eq 0; then
    stderr "Usage: $(basename $0) EXECUTABLE RETRYABLE_CODES FILE_WITH_ARGS1 [FILE ...]\n"
    stderr "  Run executable using lines in files as arguments and mark the exit code"
    exit 1
  fi
  worker "$@"
fi
