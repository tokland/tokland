#!/bin/bash
#
# Tests for rapidshare-dl.sh
#
# Web: http://code.google.com/p/megaupload-dl/wiki/RapidShare
# Contact: <tokland@gmail.com>.

set -e

# Build lines of filenames (only basename)
build() {
 echo "$@" | xargs -n1 basename
}

# Check that $1 is equal to $2.
assert_equal() {
  if ! test "$1" = "$2"; then
    echo "assert_equal failed: $1 != $2"
    return 1
  else
    echo "assert_equal ok"
  fi
} 

# Real links (small files) 
URL1="http://www.rapidshare.com/files/86545320/Tux-Trainer_25-01-2008.rar"
URL2="http://www.rapidshare.com/files/104938027/Fresh_RAM_4.5.0_tux.rar"
URL3="http://www.rapidshare.com/files/75209315/TUX.rar"

RS="./rapidshare-dl.sh"

# Single URL download
assert_equal "$(build $URL1)" "$($RS $URL1)"        
    
# File listing download
FILECONTENTS="$URL1
# a comment (followed by a empty line)

$URL2"
assert_equal "$(build $URL1 $URL2)" "$($RS <(echo "$FILECONTENTS"))" 

# Mixed URL and file listing downloading  
FILECONTENTS="$URL2
$URL3"
assert_equal "$(build $URL1 $URL2 $URL3)" "$($RS $URL1 <(echo "$FILECONTENTS"))"
