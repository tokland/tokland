#!/bin/bash
set -e -o pipefail

indent() { sed -u "s/^/  /"; }

info() {
  echo "date: $(date -R)"
  echo "kernel: $(uname -rmo)"
  echo
  echo "imagemagick: $(convert --version | head -n1 | awk '{print $3}')"
  TESSERACT=$(tesseract -v 2>&1 | head -n1 | awk '{print $2}')
  echo "tesseract: $(test "$TESSERACT" = imagename && echo "2.03" || echo $TESSERACT)"
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
svn revert "$PAGE" || exit 1
TESTS=$(tempfile)

if ! all | tee $TESTS; then
  rm -f "$TESTS"
  exit 2
fi

CONTENT=$({ 
  sed -n '1,/^= Status/p' < "$PAGE"
  echo "{{{"
  cat $TESTS 
  echo "}}}"
})
rm -f $TESTS
echo "$CONTENT" > "$PAGE"
echo svn ci -m "[megaupload-dl] automatic status update" "$PAGE"
