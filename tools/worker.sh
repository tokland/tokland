#!/bin/bash
set -e

# Echo a message to stderr
stderr() { echo -e "$@" >&2; }

# Echo an info message to stderr
info() { stderr "--- $@"; }
  
# Check if regular expression $1 matches string $2
match() { grep -q "$1" <<< "$2"; }

# Succeed if regexp $1 is found in $2
word_in_list() { grep -qw "$1" <<< "$2"; }

worker() {
  local EXECUTABLE=$1
  local RETRYABLE=$2
  shift 2
  
  RETVAL=0
  for FILE in "$@"; do 
    while read ARG; do
      info "run: $EXECUTABLE $ARG"
      $EXECUTABLE $ARG && RV=0 || RV=$?
      info "exit status: $RV"    
      if word_in_list $RV "$RETRYABLE"; then
        RETVAL=2
      else
        CODE=$(test $RV -ne 0 && echo $RV || true)
        info "mark file: $FILE"
        replace "$ARG" "#$CODE $ARG" -- "$FILE"      
      fi
    done < <(grep -v "^#" $FILE)
  done 
  return $RETVAL
}

if ! match "bash" "$0"; then
  set -e -u -o pipefail
  if test $# -eq 0; then
    stderr "Usage: $(basename $0) EXECUTABLE RETRYABLE_CODES FILE1 [FILE2 ...]\n"
    stderr "  Run executable using lines in files as arguments and mark their exit code"
    exit 1
  fi
  worker "$@"
fi
