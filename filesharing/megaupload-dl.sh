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
# = Usage
# 
#   $ megaupload-dl http://megaupload.com/?d=710JVG89
#   03.Crazy Man Michael.mp3
#
#   $ cat file_with_links.txt | xargs -n1 megaupload-dl
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
# = Contact
#
# Web: http://code.google.com/p/tokland
# Email: Arnau Sanchez <tokland@gmail.com>.

# Echo a message to stderr
stderr() { echo "$@" >&2; }

# Echo an info message to stderr
info() { stderr "--- $@"; }

# Echo an error message to stderr
error() { stderr "ERROR: $@"; }

# Check if regular expression $1 matches string $2
match() { grep -q "$1" <<< "$2"; }

# Get first line that matches the regular expression $1 and parse a string $2
parse() { local S=$(sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1) && test "$S" && echo "$S"; }

# Parse a form input value from its name $1
parse_form_input() { parse "name=\"$1\"" 'value="\([^"]*\)'; }

# Show image using ASCII characters 
show_ascii_image() {
  aview --version &>/dev/null || 
    { info "Install package aview to see the captcha"; return 0; } 
  convert "$1" -negate -depth 8 pnm:- |
    aview -width 60 -height 20 -kbddriver stdin <(cat) 2>/dev/null <<< "q" |
    sed -e '1d;/\x0C/,/\x0C/d' | grep -v "^[[:space:]]*$"
}

# Convert image to text
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

# Recode string (don't fail if it's not installed)
safe_recode() {
  if recode --version </dev/null &>/dev/null; then   
    recode "$@"
  else
    info "no recode executable found (is package recode installed?)"
    cat 
  fi
}

# Download a Megaupload link with no account
megaupload_download() {
  URL=$1
  
  while true; do 
    info "GET $URL"
    PAGE=$(curl -s $URL) || 
      { error "downloading main page"; return 4; }
    match "the link you have clicked is not available" "$PAGE" && 
      { info "Dead link"; return 2; }
    MSG=$(echo "$PAGE" | parse 'middle.*color:#FF6700;' '<center>\(.*\)<\/center>' 2>/dev/null) &&
      { error "server says: '$MSG'"; return 6; }
    CAPTCHACODE=$(echo "$PAGE" | parse_form_input captchacode) ||
      { error "parsing captchacode field"; return 3; }
    MEGAVAR=$(echo "$PAGE" | parse_form_input megavar) ||
      { error "parsing megavar field"; return 3; }      
    CAPTCHA_URL=$(echo "$PAGE" | parse "gencap.php" 'img src="\([^"]*\)') ||
      { error "parsing captcha image"; return 3; }
    info "GET $CAPTCHA_URL"
    CAPTCHA=$(curl -s "$CAPTCHA_URL" | convert - +matte gif:- | ocr | 
              head -n1 | tr -d -c "[0-9a-zA-Z]") ||
      { error "decoding captcha (imagemagick/tesseract installed?)"; return 5; }
    info "POST $URL (captcha=$CAPTCHA)"
    WAITPAGE=$(curl -s -F "captchacode=$CAPTCHACODE" -F "megavar=$MEGAVAR" \
                       -F "captcha=$CAPTCHA" "$URL") ||
      { error "in captcha form POST"; return 4; }
    WAITTIME=$(echo "$WAITPAGE" | parse "^[[:space:]]*count=" \
                                        "count=\([[:digit:]]\+\);" 2>/dev/null) ||
      { info "Wait time not found (wrong captcha?), retrying"; continue; }
    break
  done

  info "Valid captcha, waiting $WAITTIME seconds before downloading"
  FILEURL=$(echo "$WAITPAGE" | parse 'id="downloadlink"' 'href="\([^"]*\)"') ||
    { error "getting download link"; return 3; }
  FILENAME=$(basename "$FILEURL" | safe_recode html..utf8)
  sleep $WAITTIME
  info "GET $FILEURL"
  curl --globoff -o "$FILENAME" -C - "$FILEURL" ||
    { error "getting file"; return 4; }
  echo "$FILENAME"
}

# Main
if ! match "bash" "$0"; then
  set -e -u -o pipefail
  test $# -eq 1 || {
    stderr "Usage: $(basename $0) MEGAUPLOAD_URL"
    exit 1
  }
  megaupload_download "$1"
fi
