#!/bin/bash
set -e

indent() { sed -u "s/^/  /"; }

info() {
  echo "date: $(date -R)"
  echo "kernel: $(uname -rmo)"
  echo
  echo "imagemagick: $(convert --version | head -n1 | awk '{print $3}')"
  echo "tesseract: $(tesseract -v 2>&1 | awk '{print $2}')"
  echo "curl: $(curl --version | head -n1 | awk '{print $2}')"
  echo "recode: $(recode --version | head -n1 | awk '{print $3}')"
  echo "aview: $(aview --version | head -n1 | awk '{print $5}')"
}

all() {
  echo "system:"
  info | indent
  echo
  echo "megaupload-dl:"
  test/test_megaupload-dl.sh | indent
  echo
  echo "megaupload-dl-batch:"
  test/test_megaupload-dl-batch.sh | indent
}

# Main

PAGE="wiki/MegauploadDownloader.wiki"
TESTS_OUTPUT="TESTSLOG"
svn up "$PAGE" || exit 1
{
  sed -n '1,/^= Status/p' < "$PAGE"
  echo "{{{"
  all | tee /dev/tty || true
  echo "}}}"
} > "$PAGE"
svn ci -m "[megaupload-dl] automatic status update" "$PAGE"
