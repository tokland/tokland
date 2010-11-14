#!/bin/bash
# Download a file from Megaupload (free download, no account required) with 
# automatic captcha recognition.
#
# Author: Arnau Sanchez <tokland@gmail.com>
# Website: http://code.google.com/p/tokland/wiki/MegauploadDownloader

EXIT_STATUSES=(
  [0]=ok
  # Non-retryable
  [1]=link_invalid
  [2]=arguments
  [3]=link_dead
  [4]=link_unknown_problem
  [5]=ocr
  [6]=parse
  [7]=password_required
  [8]=password_wrong
  # Retryable
  [100]=parse_nonfatal
  [101]=network
  [102]=link_temporally_unavailable
)

# Set EXIT_STATUS_$KEY variables (poor man's associative array for Bash)
for SC in ${!EXIT_STATUSES[@]}; do 
  eval "EXIT_STATUS_${EXIT_STATUSES[$SC]}=$SC"
done

# Echo a message to stderr
stderr() { echo -e "$@" >&2; }

# Echo an info message to stderr
info() { stderr "--- $@"; }

# Check if regular expression $1 is found in string $2
match() { grep -q "$1" <<< "$2"; }

# Get first line that matches regular expression $1 and parse string $2
parse() { local S=$(sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1) && test "$S" && echo "$S"; }

# Parse form input value from its name ($1)
parse_form_input() { parse "name=\"$1\"" 'value="\([^"]*\)'; }

# Show image ($1) using ASCII characters 
show_ascii_image() {
  aview --version &>/dev/null || 
    { info "Install package aview to see the captcha"; return 0; } 
  convert "$1" -negate -depth 8 pnm:- |
    aview -width 60 -height 20 -kbddriver stdin <(cat) 2>/dev/null <<< "q" |
    sed -e '1d;/\x0C/,/\x0C/d' | grep -v "^[[:space:]]*$"
}

# Curl wrapper
curlw() { curl --connect-timeout 20 --speed-time 60 --retry 5 "$@"; }

# convert image (stdin) to text (stdout)
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

# Echo numeric error (to stdout) with key $1 (see EXIT_STATUSES) and message $2
error() {
  local KEY=$1; local MSG=${2:-""}
  if test "$MSG" != "#skip_log"; then 
    stderr -n "ERROR [$KEY]"
    test "$MSG" && stderr ": $MSG" || stderr
  fi
  local VAR="EXIT_STATUS_$KEY"
  echo ${!VAR}
}

# Search info message in HTML page $1 (link_temporally_unavailable, ...)
check_link_unknown_problems() {
  local MSG=$(echo "$1" | parse 'middle.*color:#FF6700;' '<center>\(.*\)<' 2>/dev/null) || true
  match "temporarily unavailable" "$MSG" &&
    return $(error link_temporally_unavailable "File is temporarily unavailable")
  test "$MSG" && return $(error link_unknown_problem "server says: '$MSG'")
  return 0
}

# Download a Megaupload link ($1) with optional password ($2) and echo file path (stdout) 
megaupload_download() {
  local URL=$1; local PASSWORD=${2:-""}
  match "^\(http://\)\?\(www\.\)\?megaupload.com/" "$URL" ||
    return $(error link_invalid "'$URL' does not seem a valid megaupload URL")
  
  while true; do
    # Link page
    info "GET $URL"
    PAGE=$(curlw -sS "$URL") || 
      return $(error network "downloading main page")
    match "the link you have clicked is not available" "$PAGE" && 
      return $(error link_dead "Link is dead")
    check_link_unknown_problems "$PAGE" || return $?
    PASSRE='name="filepassword"'
    
    if match "$PASSRE" "$PAGE"; then
      # Password-protected link
      test "$PASSWORD" || return $(error password_required "No password provided")
      info "POST $URL (filepassword=$PASSWORD)"
      WAITPAGE=$(curlw -F "filepassword=$PASSWORD" "$URL") ||
        return $(error network "posting password form")
      match "$PASSRE" "$WAITPAGE" && return $(error password_wrong "Password error")
      check_link_unknown_problems "$WAITPAGE" || return $?
    else 
      # Normal link, we need to resolve the captcha
      CAPTCHACODE=$(echo "$PAGE" | parse_form_input captchacode) ||
        return $(error parse "captchacode field")
      MEGAVAR=$(echo "$PAGE" | parse_form_input megavar) ||
        return $(error parse "megavar field")      
      CAPTCHA_URL=$(echo "$PAGE" | parse "gencap.php" 'img src="\([^"]*\)') ||
        return $(error parse "captcha image URL")
      info "GET $CAPTCHA_URL"
      CAPTCHA_IMG=$(tempfile) 
      curlw -sS -o "$CAPTCHA_IMG" "$CAPTCHA_URL" || 
        { rm -f "$CAPTCHA_IMG"; return $(error network "getting captcha image"); }
      CAPTCHA=$(convert "$CAPTCHA_IMG" +matte gif:- | ocr | head -n1 | 
                tr -d -c "[0-9a-zA-Z]") || 
        { rm -f "$CAPTCHA_IMG"; return $(error ocr "are imagemagick/tesseract installed?"); } 
      rm -f "$CAPTCHA_IMG"
      info "POST $URL (captcha=$CAPTCHA)"
      WAITPAGE=$(curlw -sS -F "captchacode=$CAPTCHACODE" \
                           -F "megavar=$MEGAVAR" \
                           -F "captcha=$CAPTCHA" "$URL") ||
        return $(error network "posting captcha form")
    fi
    
    # Get download link and wait
    WAITTIME=$(echo "$WAITPAGE" | parse "^[[:space:]]*count=" "count=\([[:digit:]]\+\);" 2>/dev/null) ||
      { info "Wait time not found in response (wrong captcha?), retrying"; continue; }
    FILEURL=$(echo "$WAITPAGE" | parse 'id="downloadlink"' 'href="\([^"]*\)"') ||
      return $(error parse "download link not found")
    FILENAME=$(basename "$FILEURL" | { recode html..utf8 || cat; })
    info "Waiting $WAITTIME seconds before starting download"
    sleep $WAITTIME
    
    # Download the file
    info "GET $FILEURL"
    INFO=$(curlw -w "%{http_code} %{size_download}" -g -C - -o "$FILENAME" "$FILEURL") ||
      return $(error network "downloading file")
    read HTTP_CODE SIZE_DOWNLOAD <<< "$INFO"
    
    if ! match "2.." "$HTTP_CODE" -a test $SIZE_DOWNLOAD -gt 0; then
      # This is tricky: if we got an unsuccessful code but something was 
      # downloaded, the output file will now contain a page regarding the error.
      # Since this content would interfere on the next loop, we better get rid of it. 
      rm -f "$FILENAME"
    fi
    
    if match "503" "$HTTP_CODE"; then
      # Megaupload uses HTTP code 503 to signal the download limit exceeded error
      LIMIT_PAGE=$(curlw -sS "http://www.megaupload.com/?c=premium&l=1") || 
        return $(error network)      
      MINUTES=$(echo "$LIMIT_PAGE" | parse "Please wait" "wait \([[:digit:]]\+\) min") || 
        return $(error parse_nonfatal "wait time in limit page")
      info "Download limit exceeded, waiting $MINUTES minutes by server request"
      sleep $((MINUTES*60))
      continue
    elif ! match "2.." "$HTTP_CODE"; then
      return $(error network "unsuccessful HTTP code: $HTTP_CODE")
    fi
    echo "$FILENAME"
    break
  done
}

# Main
if ! match "bash" "$0"; then
  set -e -u -o pipefail
  if test $# -ne 1; then
    stderr "Usage: $(basename $0) MEGAUPLOAD_URL[@PASSWORD]\n"
    stderr "    Download a Megaupload file (path of file is written to stdout)"
    exit $(error arguments "#skip_log")
  fi
  IFS="@" read URL PASSWORD <<< "$1"
  megaupload_download "$URL" "$PASSWORD"
fi
