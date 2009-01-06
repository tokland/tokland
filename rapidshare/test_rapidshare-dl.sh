#!/bin/bash
#
# Tests for rapidshare-dl.sh
#
# Web: http://code.google.com/p/megaupload-dl/wiki/RapidShare
# Contact: <tokland@gmail.com>.

set -e

# Check that $1 is equal to $2.
assert_equal() {
  if ! test "$1" = "$2"; then
    echo "assert_equal failed: $1 != $2"
    return 1
  fi
}

# Run a test
# $1..N: Function to run
run() {
  echo -n "$NAME... "
  "$@" && echo " ok" || echo " failed!"
}

### Tests
 
URL1="http://www.rapidshare.com/files/86545320/Tux-Trainer_25-01-2008.rar"
URL2="http://www.rapidshare.com/files/104938027/Fresh_RAM_4.5.0_tux.rar"
URL3="http://www.rapidshare.com/files/75209315/TUX.rar"
RS="./rapidshare-dl.sh"

# Build lines of filenames (only basename)
build() {
 echo "$@" | xargs -n1 basename
}

# Single URL download
test_single_url() {
  assert_equal "$(build $URL1)" "$($RS $URL1)"
}        

test_file_listing() {    
  # File listing download
  FILECONTENTS="$URL1
# a comment (followed by a empty line)

$URL2"
  assert_equal "$(build $URL1 $URL2)" "$($RS <(echo "$FILECONTENTS"))"
}

test_url_and_file_listing() {
  # Mixed URL and file listing downloading  
  FILECONTENTS="$URL2
$URL3"
  assert_equal "$(build $URL1 $URL2 $URL3)" "$($RS $URL1 <(echo "$FILECONTENTS"))"
}

run "test_single_url"
run "test_file_listing"
run "test_url_and_file_listing"
