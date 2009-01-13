#!/bin/bash
#
# Unit tests for rapidshare-dl.sh
#
# Web: http://code.google.com/p/megaupload-dl/wiki/RapidShare
# Contact: <tokland@gmail.com>.
#
set -e

tmpfile() {
    TEMP=$(tempfile)
    echo -e "$1" > $TEMP
    echo $TEMP
}

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
  assert_return 0 match "^a" "abc" || return 1
  assert_return 0 match "^[[:digit:]]\+z" "12zy" || return 1
  assert_return 1 match "^[[:digit:]]\+z" "x12zy" || return 1
}

test_parse() {
  INPUT="test1
test2 a = 12 test3
test4"
  OUTPUT=$(echo "$INPUT" | parse "^test2" "a = \([[:digit:]]\+\)")
  assert_equal "12" $OUTPUT || return 1
  OUTPUT=$(echo "bye c = 3" | parse "^bye" "d = \([[:digit:]]\+\)")
  assert_equal "" $OUTPUT || return 1
}
 
test_process_item()  {
  URL1="www.rapidshare.com/files/75209315/TUX.rar"
  URL2="www.rapidshare.com/files/75209315/anotherTUX.rar"
  # Mixed URL and file listing downloading  
  FILECONTENTS="$URL1\n$URL2"
  EXPECTED=$(echo -e "$URL1\n$URL2")
  RET=$(process_item $(tmpfile "$FILECONTENTS"))
  assert_equal "$EXPECTED" "$RET" || return 1
}

TESTMODE=1
source rapidshare-dl.sh

run test_debug
run test_parse
run test_match
run test_process_item
