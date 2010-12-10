#!/bin/bash
# Download a file from Megaupload (free download without account) using 
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
  [103]=another_download_active
)

# Set EXIT_STATUS_$KEY variables (poor man's associative array for Bash)
for SC in ${!EXIT_STATUSES[@]}; do 
  eval "EXIT_STATUS_${EXIT_STATUSES[$SC]}=$SC"
done

# Echo a message ($@) to stderr
stderr() { echo -e "$@" >&2; }

# Echo an info message ($@) to stderr
info() { stderr "--- $@"; }

# Check if regular expression $1 is found in string $2 (case insensitive)
match() { grep -qi "$1" <<< "$2"; }

# Strip string
strip() { sed "s/^[[:space:]]*//; s/[[:space:]]*$//"; }

# Get first line that matches regular expression $1 and parse string $2 (case insensitive)
parse() { local S=$(sed -n "/$1/I s/^.*$2.*$/\1/ip" | head -n1) && test "$S" && echo "$S"; }

# Like parse but do not write errors to stderr
parse_quiet() { parse "$@" 2>/dev/null; }

# Parse form input 'value' attribute from its name ($1)
parse_form_input() { parse "name=\"$1\"" 'value="\([^"]*\)'; }

# Curl wrapper (goal: robustness and responsiveness)
curlw() { curl --connect-timeout 20 --speed-time 60 --retry 5 "$@"; }

# Show image ($1) using ASCII  
show_ascii_image() {
  aview --version &>/dev/null || 
    { info "Install package aview to see the captcha"; return 0; } 
  convert "$1" -negate -depth 8 pnm:- |
    aview -width 60 -height 20 -kbddriver stdin <(cat) 2>/dev/null <<< "q" |
    sed -e '1d;/\x0C/,/\x0C/d' | grep -v "^[[:space:]]*$"
}

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
  local KEY=$1; local MSG=${2:-""}; local DEBUGCONTENT=${3:-""}
  if test "$MSG" != "#skip_log"; then 
    stderr -n "ERROR [$KEY]"
    test "$MSG" && stderr ": $MSG" || stderr
  fi
  if test "$DEBUGCONTENT"; then
    local TEMP=$(tempfile)
    echo "$DEBUGCONTENT" > $TEMP
    stderr "debug content saved: $TEMP"
  fi
  local VAR="EXIT_STATUS_$KEY"
  echo ${!VAR}
}

### 

# Search info message in HTML $1 (temporally_unavailable/unknown_problem)
get_main_page() {
  local URL=$1
  
  while true; do 
    info "GET $URL"
    local PAGE=$(curlw -sS "$URL") || return $(error network "downloading page: $URL")
    local ERROR_URL=$(echo "$PAGE" | parse_quiet '<BODY>.*document.loc' "location='\([^']*\)'") || true
    local MSG=$(echo "$PAGE" | parse_quiet '<center>' '<center>\(.*\)<') || true
    
    if test "$ERROR_URL"; then
      local ERROR_PAGE=$(curlw -sS "$ERROR_URL") ||
        return $(error network "downloading error page") 
      local WAIT=$(echo "$ERROR_PAGE" | parse_quiet "check back in" "in \([[:digit:]]\+\) min") ||
        return $(error parse "error page detected, but wait time not found" "$PAGE")
      info "The server told us off for making too much requests, waiting $WAIT minutes"
      sleep $((WAIT*60))
      continue
    elif match "the link you have clicked is not available" "$PAGE"; then
      return $(error link_dead "Link is dead")    
    elif match "temporarily unavailable" "$MSG"; then
      return $(error link_temporally_unavailable "File is temporarily unavailable")
    elif test "$MSG"; then
      return $(error link_unknown_problem "server says: '$MSG'")
    else
      echo "$PAGE"
      break
    fi
  done
}

# Download a Megaupload link ($1) with optional password ($2) and echo file path (stdout) 
megaupload_download() {
  local URL=$1; local PASSWORD=${2:-""}
  match "^\(http://\)\?\(www\.\)\?megaupload.com/" "$URL" ||
    return $(error link_invalid "'$URL' does not seem a valid megaupload URL")
  
  while true; do
    # Get main link page
    PAGE=$(get_main_page "$URL") || return $?
    
    # Show info
    info "Name: $(echo "$PAGE" | parse 'File name:' '>\(.*\)<\/span' | strip)"
    info "Description: $(echo "$PAGE" | parse 'File description:' '>\(.*\)<br' | strip)"
    info "Size: $(echo "$PAGE" | parse 'File size:' '>\(.*\)<br' | strip)"

    # Get wait page
    PASSRE='name="filepassword"'
    WAITPAGE=$(if match "$PASSRE" "$PAGE"; then
      # Password-protected link
      test "$PASSWORD" || return $(error password_required "No password provided")
      info "POST $URL (filepassword=$PASSWORD)"
      WAITPAGE=$(curlw -sS -F "filepassword=$PASSWORD" "$URL") ||
        return $(error network "posting password form")
      match "$PASSRE" "$WAITPAGE" &&
        return $(error password_wrong "Password error")
      echo "$WAITPAGE"
    elif match "^[[:space:]]*count=" "$PAGE"; then
      echo "$PAGE" # Happy-hour, the main page is also the wait page
    else 
      # Normal link with no password, resolve the captcha
      CODE=$(echo "$PAGE" | parse_form_input captchacode) ||
        return $(error parse "captchacode field" "$PAGE")
      MVAR=$(echo "$PAGE" | parse_form_input megavar) ||
        return $(error parse "megavar field" "$PAGE")      
      CAPTCHA_URL=$(echo "$PAGE" | parse "gencap.php" 'img src="\([^"]*\)') ||
        return $(error parse "captcha image URL""$PAGE")
      info "GET $CAPTCHA_URL"
      CAPTCHA_IMG=$(tempfile) 
      curlw -sS -o "$CAPTCHA_IMG" "$CAPTCHA_URL" || 
        { rm -f "$CAPTCHA_IMG"; return $(error network "getting captcha image"); }
      CAPTCHA=$(convert "$CAPTCHA_IMG" +matte gif:- | ocr | head -n1 | 
                tr -d -c "[0-9a-zA-Z]") || 
        { rm -f "$CAPTCHA_IMG"; return $(error ocr "check imagemagick/tesseract"); } 
      rm -f "$CAPTCHA_IMG"
      info "POST $URL (captcha=$CAPTCHA)"
      curlw -sS -F "captchacode=$CODE" -F "megavar=$MVAR" -F "captcha=$CAPTCHA" "$URL" ||
        return $(error network "posting captcha form")
    fi)
    
    # Get download link and wait
    WAITTIME=$(echo "$WAITPAGE" | parse "^[[:space:]]*count=" "count=\([[:digit:]]\+\);") ||
      { info "Wait time not found in response (wrong captcha?), retrying"; continue; }
    FILEURL=$(echo "$WAITPAGE" | parse 'id="downloadlink"' 'href="\([^"]*\)"') ||
      return $(error parse "download link not found" "$WAITPAGE")
    FILENAME=$(basename "$FILEURL" | { recode html.. || cat; }) # make recode optional
    info "Waiting $WAITTIME seconds before starting download"
    sleep $WAITTIME
    
    # Download the file
    info "Output filename: $FILENAME"
    info "GET $FILEURL"
    INFO=$(curlw -w "%{http_code} %{size_download}" -g -C - -o "$FILENAME" "$FILEURL") ||
      return $(error network "downloading file")
    read HTTP_CODE SIZE_DOWNLOAD <<< "$INFO"
    
    if ! match "2.." "$HTTP_CODE" -a test $SIZE_DOWNLOAD -gt 0; then
      # This is tricky: if we got an unsuccessful code (probably a 503), but 
      # something was downloaded, FILENAME will now contain this data (the error page).
      # Since this content would interfere with the next loop, we better get rid of it. 
      rm -f "$FILENAME"
    fi
    
    if match "503" "$HTTP_CODE"; then
      # Megaupload uses HTTP code 503 to signal a download limit exceeded 
      LIMIT_PAGE=$(curlw -sS "http://www.megaupload.com/?c=premium&l=1") || 
        return $(error network "Downloading error page")
      match "finish this download before" "$LIMIT_PAGE" &&
        return $(error another_download_active)      
      MINUTES=$(echo "$LIMIT_PAGE" | parse "Please wait" "wait \([[:digit:]]\+\) min") || 
        return $(error parse_nonfatal "wait time in limit page" "$LIMIT_PAGE")
      info "Download limit exceeded, waiting $MINUTES minutes by server request"
      sleep $((MINUTES*60))
      continue
    elif ! match "2.." "$HTTP_CODE"; then
      # Unsuccessful code different from 503. A transient network problem? who knows.
      return $(error network "unsuccessful (and unexpected) HTTP code: $HTTP_CODE")
    fi
    
    # File successfully downloaded: echo the path to stdout and terminate loop
    echo "$FILENAME"
    break
  done
}

### Main

if test -z "$_MEGAUPLOAD_DL_SOURCE"; then
  set -e -u -o pipefail
  if test $# -ne 1; then
    stderr "Usage: $(basename $0) MEGAUPLOAD_URL[@PASSWORD]\n"
    stderr "    Download a Megaupload file (and write file path to stdout)"
    exit $(error arguments "#skip_log")
  fi
  IFS="@" read URL PASSWORD <<< "$1"
  megaupload_download "$URL" "$PASSWORD"
fi
