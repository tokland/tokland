#!/bin/bash
set -e
source "$(dirname $0)/lib.sh"

md5() { md5sum "$1" | awk '{print $1}'; }

download() {
  while true; do
    local RV=0
    ./megaupload-dl.sh "$@" || RV=$?
    grep -wq "10." <<< $RV || return $RV
    sleep 10m
  done
}

###

MU_URL1="http://www.megaupload.com/?d=1FPK9QPM"
MU_URL1_FILENAME=xkcd1.jpg
MU_URL1_MD5="ba8ad157b1d5c233580b7ea6be53f1fd"

MU_URL2="http://www.megaupload.com/?d=FDPAE94B"
MU_URL2_PASSWORD=tokland
MU_URL2_FILENAME=xkcd2.jpg
MU_URL2_MD5="bcf9aec4d5e9a92ad22cd42d52f11fcc"

test_0wrong_link() {
  assert_return 1 download "http://rapidshare.com/?d=1234"
}

test_dead_link() {
  assert_return 3 download "http://megaupload.com/?d=12deadlink34"
}

test_download() {
  rm -f $MU_URL1_FILENAME
  assert_equal "$MU_URL1_FILENAME" $(download "$MU_URL1")
  assert_equal "$MU_URL1_MD5" $(md5 $MU_URL1_FILENAME)
  rm -f $MU_URL1_FILENAME
}

test_download_with_resume() {
  head -c1K ${MU_URL1_FILENAME}.orig > $MU_URL1_FILENAME
  assert_equal "$MU_URL1_FILENAME" $(download "$MU_URL1")
  assert_equal "$MU_URL1_MD5" $(md5 $MU_URL1_FILENAME)
  rm -f $MU_URL1_FILENAME
}

test_link_with_password() {
  rm -f $MU_URL2_FILENAME
  assert_equal "$MU_URL2_FILENAME" $(download "$MU_URL2@$MU_URL2_PASSWORD")
  assert_equal "$MU_URL2_MD5" $(md5 $MU_URL2_FILENAME)
  rm -f $MU_URL2_FILENAME
}

test_link_with_password_but_no_password_provided() {
  assert_return 6 download "$MU_URL2"
}

test_link_with_password_but_wrong_password() {
  assert_return 7 download "${MU_URL2}@wrongpassword"
}

run_tests "$@"
