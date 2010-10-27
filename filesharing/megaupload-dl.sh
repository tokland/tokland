#!/bin/bash
#
# Download a file from Megaupload (free download, no account required) with 
# automatic captcha recognition. 
#
# Dependencies: bash, curl, recode, imagemagick, tesseract-ocr (optional: aview)
# License: GNU GPL v3.0: http://www.gnu.org/licenses/gpl-3.0-standalone.html
#
# = Install
#
#   $ cp megaupload-dl.sh /usr/local/bin/megaupload-dl
#   $ chmod +x /usr/local/bin/megaupload-dl
#
# = Usage examples
# 
#   $ megaupload-dl http://megaupload.com/?d=710JVG89
#   03.Crazy Man Michael.mp3
#
#   $ xargs -n1 megaupload-dl < file_with_links.txt
#   [...]
#
# = Exit status
#    
# 0 - Download successful
# 1 - Arguments error
# 2 - Dead link
# 3 - Parsing error
# 4 - Network problems
# 5 - Generic error
# 6 - Some problem with the link (not available, blocked, ...)
# 
# = Feedback
#
# Author: Arnau Sanchez <tokland@gmail.com>.
# Report bugs: http://code.google.com/p/tokland/issues/list

EXIT_STATUSES=(
  [0]=ok 
  [1]=arguments 
  [2]=deadlink 
  [3]=parsing 
  [4]=network 
  [5]=generic 
  [6]=link_problem
)

# Echo a message to stderr
stderr() { echo "$@" >&2; }

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

# Recode string (safe execution, it won't fail if recode is not installed)
safe_recode() {
  if recode --version </dev/null &>/dev/null; then   
    recode "$@"
  else
    info "no recode executable found (is package recode installed?)"
    cat 
  fi
}

# Echo an error message to stderr
error() {
  ERROR_KEY=$1
  ERROR_MSG=$2 
  for ((I=0; I<${#EXIT_STATUSES[@]}; I++)); do
    if test "${EXIT_STATUSES[$I]}" = "$ERROR_KEY"; then
      stderr "ERROR [$ERROR_KEY]: $ERROR_MSG"
      echo $I
      return
    fi 
  done
  stderr "unknown error key: $ERROR_KEY"
  return 255
}

# Download a Megaupload link $1 
megaupload_download() {
  URL=$1
  
  while true; do 
    info "GET $URL"
    PAGE=$(curl -s $URL) || 
      return $(error network "downloading main page")
    match "the link you have clicked is not available" "$PAGE" && 
      return $(error deadlink "Link is dead")
    MSG=$(echo "$PAGE" | parse 'middle.*color:#FF6700;' '<center>\(.*\)<\/center>' 2>/dev/null) &&
      return $(error link_problem "server says: '$MSG'")
    CAPTCHACODE=$(echo "$PAGE" | parse_form_input captchacode) ||
      return $(error parsing "captchacode field")
    MEGAVAR=$(echo "$PAGE" | parse_form_input megavar) ||
      return $(error parsing "megavar field")      
    CAPTCHA_URL=$(echo "$PAGE" | parse "gencap.php" 'img src="\([^"]*\)') ||
      return $(error parsing "captcha image")
    info "GET $CAPTCHA_URL"
    CAPTCHA=$(curl -s "$CAPTCHA_URL" | convert - +matte gif:- | ocr | 
              head -n1 | tr -d -c "[0-9a-zA-Z]") ||
      return $(error generic "decoding captcha (imagemagick/tesseract installed?)")
    info "POST $URL (captcha=$CAPTCHA)"
    WAITPAGE=$(curl -s -F "captchacode=$CAPTCHACODE" -F "megavar=$MEGAVAR" \
                       -F "captcha=$CAPTCHA" "$URL") ||
      return $(error network "posting captcha form")
    WAITTIME=$(echo "$WAITPAGE" | parse "^[[:space:]]*count=" \
                                        "count=\([[:digit:]]\+\);" 2>/dev/null) ||
      { info "Wait time not found in response (wrong captcha?), retrying"; continue; }
    break
  done

  info "Valid captcha, waiting $WAITTIME seconds before starting download"
  FILEURL=$(echo "$WAITPAGE" | parse 'id="downloadlink"' 'href="\([^"]*\)"') ||
    return $(error parsing "download link not found")
  FILENAME=$(basename "$FILEURL" | safe_recode html..utf8)
  sleep $WAITTIME
  info "GET $FILEURL"
  curl --globoff -o "$FILENAME" -C - "$FILEURL" ||
    return $(error network "getting file")
  echo "$FILENAME"
}

# Main
if ! match "bash" "$0"; then
  set -e -u -o pipefail
  if test $# -ne 1; then
    stderr "Usage: $(basename $0) MEGAUPLOAD_URL"
    exit 1
  fi
  FILENAME=$(megaupload_download "$1") && echo $FILENAME
fi
