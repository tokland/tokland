#!/bin/bash
#
# megaupload-dl: Download a file from Megaupload (free download, no account 
# required) with automatic captcha recognition. 
#
# Documentation: http://code.google.com/p/tokland/wiki/MegauploadDownloader
# Author: (2010) Arnau Sanchez <tokland@gmail.com>

EXIT_STATUSES=(
  [0]=ok 
  [1]=arguments 
  [2]=deadlink 
  [3]=link_problem 
  [4]=ocr
  [5]=parse 
  [6]=network
  [7]=unknown_link
  [255]=runtime
)

# Echo a message to stderr
stderr() { echo -e "$@" >&2; }

# Echo an info message to stderr
info() { stderr "--- $@"; }

# Check if regular expression $1 matches string $2
match() { grep -q "$1" <<< "$2"; }

# Get first line that matches regular expression $1 and parse string $2
parse() { local S=$(sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1) && test "$S" && echo "$S"; }

# Parse form input value from its name ($1)
parse_form_input() { parse "name=\"$1\"" 'value="\([^"]*\)'; }

# Show image using ASCII characters 
show_ascii_image() {
  aview --version &>/dev/null || 
    { info "Install package aview to see the captcha"; return 0; } 
  convert "$1" -negate -depth 8 pnm:- |
    aview -width 60 -height 20 -kbddriver stdin <(cat) 2>/dev/null <<< "q" |
    sed -e '1d;/\x0C/,/\x0C/d' | grep -v "^[[:space:]]*$"
}

# OCR: convert image to text
ocr() {
  local TIFF=$(tempfile --suffix=".tif")
  local TEXT=$(tempfile --suffix=".txt")
  convert - tif:- > $TIFF
  show_ascii_image $TIFF | while read LINE; do
    info "$LINE"
  done
  tesseract $TIFF ${TEXT/%.txt}
  cat $TEXT
  rm -f $TIFF $TEXT
}

# Print an error with key $1 (see EXIT_STATUSES) and message $2. 
# Return numeric status code
error() {
  local KEY=$1; local MSG=$2 
  for ((SC=0; SC<${#EXIT_STATUSES[@]}; SC++)); do
    if test "${EXIT_STATUSES[$SC]}" = "$KEY"; then
      stderr "ERROR [$KEY]: $MSG"
      echo $SC
      return
    fi 
  done
  stderr "ERROR [runtime]: unknown error key: $KEY ($MSG)"
  echo 255
}

# Download a Megaupload link ($1) and return download file path 
megaupload_download() {
  URL=$1
  
  match "^\(http://\)\?\(www\.\)\?megaupload.com/" "$URL" ||
    return $(error unknown_link "this does not seem a megaupload link: $URL")
  
  while true; do 
    info "GET $URL"
    PAGE=$(curl -s $URL) || 
      return $(error network "downloading main page")
    match "the link you have clicked is not available" "$PAGE" && 
      return $(error deadlink "Link is dead")
    MSG=$(echo "$PAGE" | parse 'middle.*color:#FF6700;' '<center>\(.*\)<' 2>/dev/null) &&
      return $(error link_problem "server says: '$MSG'")
    CAPTCHACODE=$(echo "$PAGE" | parse_form_input captchacode) ||
      return $(error parse "captchacode field")
    MEGAVAR=$(echo "$PAGE" | parse_form_input megavar) ||
      return $(error parse "megavar field")      
    CAPTCHA_URL=$(echo "$PAGE" | parse "gencap.php" 'img src="\([^"]*\)') ||
      return $(error parse "captcha image")
    info "GET $CAPTCHA_URL"
    CAPTCHA=$(curl -s "$CAPTCHA_URL" | convert - +matte gif:- | ocr | 
              head -n1 | tr -d -c "[0-9a-zA-Z]") ||
      return $(error ocr "decoding captcha (are imagemagick/tesseract installed?)")
    info "POST $URL (captcha=$CAPTCHA)"
    WAITPAGE=$(curl -s -F "captchacode=$CAPTCHACODE" -F "megavar=$MEGAVAR" \
                       -F "captcha=$CAPTCHA" "$URL") ||
      return $(error network "posting captcha form")
    WAITTIME=$(echo "$WAITPAGE" | parse "^[[:space:]]*count=" \
                                        "count=\([[:digit:]]\+\);" 2>/dev/null) ||
      { info "Wait time not found in response (wrong captcha?), retrying"; continue; }
    break
  done

  FILEURL=$(echo "$WAITPAGE" | parse 'id="downloadlink"' 'href="\([^"]*\)"') ||
    return $(error parse "download link not found")
  FILENAME=$(basename "$FILEURL" | { recode html..utf8 || cat; })
  info "Valid captcha, waiting $WAITTIME seconds before starting download"
  sleep $WAITTIME
  info "GET $FILEURL (=> $FILENAME)"
  curl --globoff -o "$FILENAME" -C - "$FILEURL" ||
    return $(error network "getting file")
  echo "$FILENAME"
}

# Main
if ! match "bash" "$0"; then
  set -e -u -o pipefail
  if test $# -ne 1; then
    stderr "Usage: $(basename $0) MEGAUPLOAD_URL\n"
    stderr "  Download a Megaupload file (path is written to stdout)"
    exit 1
  fi
  megaupload_download "$1"
fi
