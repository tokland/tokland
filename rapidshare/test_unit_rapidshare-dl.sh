#!/bin/bash
#
# Unit tests for rapidshare-dl.sh
#
# Web: http://code.google.com/p/megaupload-dl/wiki/RapidShare
# Contact: <tokland@gmail.com>.
#
set -e

# Check that $1 is equal to $2.
assert_equal() {
  if ! test "$1" = "$2"; then
    echo "assert_equal failed: $1 != $2"
    return 1
  fi
}

assert_return() {
  EXPECTED_RETVAL=$1
  shift
  "$@"
  RETVAL=$?
  if ! test $RETVAL -eq $EXPECTED_RETVAL; then
      echo "assert_return failed: $EXPECTED_RETVAL != $RETVAL"
      return 1
  fi
}

# Run a test
# $1: Function to run
run() {
  NAME=$1
  echo -n "$NAME... "
  if $NAME; then
    echo " ok"
  else
    echo " failed!"
  fi
}

### Tests
 
test_debug() {
  STDOUT=$(debug "test" 2>/dev/null) 
  assert_equal "" "$STDOUT" || return 1 
  STDERR=$(debug "test" 2>&1) 
  assert_equal "test" "$STDERR" || return 1
}        

test_match() {
  INPUT="test1
test2 a = 12 test3
test4"
  OUTPUT=$(echo "$INPUT" | match "^test2" "a = \([[:digit:]]\+\)")
  assert_equal "12" $OUTPUT || return 1
  OUTPUT=$(echo "bye c = 3" | match "^bye" "d = \([[:digit:]]\+\)")
  assert_equal "" $OUTPUT || return 1
}

test_is_rapidshare_url() {
  assert_return 0 "is_rapidshare_url" \
    "http://www.rapidshare.com/files/75209315/TUX.rar" || return 1
  return 0
  assert_return 0 "is_rapidshare_url" \
    "www.rapidshare.com/files/75209315/TUX.rar" || return 1
  assert_return 0 "is_rapidshare_url" "http://is_a_link" || return 1
  assert_return 1 "is_rapidshare_url" "seems_a_file.txt" || return 1
}  

test_process_item()  {
  URL1="www.rapidshare.com/files/75209315/TUX.rar"
  URL2="www.rapidshare.com/files/75209315/anotherTUX.rar"
  # Mixed URL and file listing downloading  
  FILECONTENTS="$URL1
$URL2"
  EXPECTED=$(echo -e "$URL1\n$URL2")
  assert_equal "$EXPECTED" "$(process_item <(echo "$FILECONTENTS"))" || return 1
}

source rapidshare-dl.sh --test

run test_debug
run test_match
run test_is_rapidshare_url
run test_process_item
