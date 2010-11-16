#!/bin/bash

stderr() { echo -e "$@" >&2; }

assert_equal() {
  if ! test "$1" == "$2"; then
    stderr "assert_equal failed: expected '$1' but got '$2'"
    return 1
  fi   
}

assert_return() {
  local EXPECTED=$1
  shift
  local RV=0
  "$@" || RV=$?
  if ! test "$EXPECTED" == "$RV"; then
    stderr "assert_return failed: expected $EXPECTED but got $RV"
    return 1
  fi
}

run_tests() {
  ERROR=$(tempfile)
  TESTS=$(if test $# -eq 0; then
    set | grep "^test_" | awk '$2 == "()"' | awk '{print $1}' | xargs
  else
    echo "$@"
  fi)
  local RETVAL=0
  for TEST in $TESTS; do
    echo -n "$TEST: "
    if $TEST 2>$ERROR; then 
      echo "ok"
    else
      RETVAL=1
      echo "failed"
      sed "s/^/  /" < $ERROR >&2
    fi
  done
  rm -f $ERROR
  return $RETVAL 
}
