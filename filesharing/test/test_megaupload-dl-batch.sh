#!/bin/bash
set -e
source "$(dirname $0)/lib.sh"

download_batch() {
  ./megaupload-dl-batch.sh "$@"
}

###

test_batch_download() {
  ORIGINAL="#commented lines should be ignored
  http://www.rapidshare.com/?d=1FPK9QPM
  http://www.megaupload.com/?d=1deadlinkM"
  EXPECTED="#commented lines should be ignored
  #link_invalid http://www.rapidshare.com/?d=1FPK9QPM
  # http://www.megaupload.com/?d=1FPK9QPM
  #link_dead http://www.megaupload.com/?d=1deadlinkM"

  TEMP=$(tempfile)
  echo "$ORIGINAL" > $TEMP
  assert_return 0 download_batch $TEMP
  assert_equal "$EXPECTED" "$(cat $TEMP)"
  rm -f $TEMP
}

run_tests "$@"
