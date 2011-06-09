#!/bin/bash
#
# Download a file from Megaupload.
#
# $ megaupload-dl http://www.megaupload.com/?d=XJHN1S11
# hello.pdf
#
# Author: Arnau Sanchez <tokland@gmail.com>
# Website: http://code.google.com/p/tokland/wiki/MegauploadDownloader

EXIT_STATUSES=(
  [0]=ok
  # Non-retryable errors
  [1]=link_invalid
  [2]=arguments
  [3]=link_dead
  [4]=link_unknown_problem
  [5]=parse
  [6]=password_required
  [7]=password_wrong
  # Retryable errors
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

# Wrapper over curl
curlw() { curl --connect-timeout 20 --speed-time 60 --retry 5 "$@"; }

# Echo error with key $1 (see EXIT_STATUSES_*), message $2 and optional debug output ($3)
error() {
  local KEY=$1; local MSG=${2:-""}; local DEBUGCONTENT=${3:-""}
  stderr -n "ERROR [$KEY]"
  test "$MSG" && stderr ": $MSG" || stderr
  if test "$DEBUGCONTENT"; then
    local TEMP=$(tempfile)
    echo "$DEBUGCONTENT" > $TEMP
    stderr "debug content saved: $TEMP"
  fi
  local VAR="EXIT_STATUS_$KEY"
  echo ${!VAR}
}

### Application-specific functions

# Get the page for a URL ($1) or return error (set $2 = 'wait' to loop on wait messages)
get_main_page() {
  local URL=$1; local OPT=$2
  
  while true; do 
    info "GET $URL"
    PAGE=$(curlw -sS "$URL") || return $(error network "downloading page: $URL")
    ERROR_URL=$(echo "$PAGE" | parse_quiet '<BODY>.*document.loc' "location='\([^']*\)'") || true
    MSG=$(echo "$PAGE" | parse_quiet '<center>' '<center>\(.*\)<') || true
    
    if test "$ERROR_URL" -a "$OPT" = "wait"; then
      ERROR_PAGE=$(curlw -sS "$ERROR_URL") ||
        return $(error network "downloading error page") 
      WAIT=$(echo "$ERROR_PAGE" | parse_quiet "check back in" "in \([[:digit:]]\+\) min") ||
        return $(error parse "error page detected, but wait time not found" "$ERROR_PAGE")
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
      # refactorize? something like: file_info "$PAGE" "Name" "File name" "span"
      info "Name: $(echo "$PAGE" | parse 'File name:' '>\(.*\)<\/span' | strip)"
      info "Description: $(echo "$PAGE" | parse 'File description:' '>\(.*\)<br' | strip)"
      info "Size: $(echo "$PAGE" | parse 'File size:' '>\(.*\)<br' | strip)"    
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
    PAGE=$(get_main_page "$URL" "wait") || return $?
    
    # Wait page
    PASSRE='name="filepassword"'
    WAITPAGE=$(if match "^[[:space:]]*count=" "$PAGE"; then
      # MU dropped the captcha, so the main page is also the wait page
      echo "$PAGE" 
    elif match "$PASSRE" "$PAGE"; then
      # Password-protected link
      test "$PASSWORD" || return $(error password_required "No password provided")
      info "POST $URL (filepassword=$PASSWORD)"
      WAITPAGE=$(curlw -sS -F "filepassword=$PASSWORD" "$URL") ||
        return $(error network "posting password form")
      match "$PASSRE" "$WAITPAGE" &&
        return $(error password_wrong "Password error")
      echo "$WAITPAGE"
    else 
      return $(error parse "main page" "$PAGE")
    fi) || return $?
    
    # Get download link and wait
    WAITTIME=$(echo "$WAITPAGE" | parse "^[[:space:]]*count=" "count=\([[:digit:]]\+\);") ||
      { info "Wait time not found in response (wrong captcha?), retrying"; continue; }
    FILEURL=$(echo "$WAITPAGE" | parse 'id="downloadlink"' 'href="\([^"]*\)"') ||
      return $(error parse "download link not found" "$WAITPAGE")
    FILENAME=$(basename "$FILEURL" | { recode html.. || cat; }) # make recode optional
    info "Waiting $WAITTIME seconds before download starts"
    sleep $WAITTIME
    
    # Download the file
    info "Output filename: $FILENAME"
    info "GET $FILEURL"
    INFO=$(curlw -w "%{http_code} %{size_download}" -g -C - -o "$FILENAME" "$FILEURL") ||
      return $(error network "downloading file")
    read HTTP_CODE SIZE_DOWNLOAD <<< "$INFO"
    
    if ! match "2.." "$HTTP_CODE" -a test $SIZE_DOWNLOAD -gt 0; then
      # This is tricky: if we got an unsuccessful code (probably a 503), but 
      # FILENAME contains data (the error page), we need to delete it so it
      # does not interfere with the real file later. 
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
    
    # File successfully downloaded: echo the path to stdout and break loop
    echo "$FILENAME"
    break
  done
}

usage() {
  stderr "Usage: $(basename $0) [-p PASSWORD] [-c] URL[@PASSWORD]\n"
  stderr "  Download a file from megaupload.com"
}

### Main

if test -z "$_MEGAUPLOAD_DL_SOURCE"; then
  set -e -u -o pipefail
  PASSWORD=
  CHECKONLY=
  test $# -eq 0 && set -- "-h"
  while getopts "cp:h" ARG; do
    case "$ARG" in
    c) CHECKONLY=1;;
    p) PASSWORD=$OPTARG;;
    *) usage
       exit $EXIT_STATUS_arguments;;
    esac
  done
  shift $(($OPTIND-1))
  IFS="@" read URL URL_PASSWORD <<< "$1"
  
  if test "$CHECKONLY"; then
    get_main_page "$URL" "nowait" > /dev/null
    info "Link is alive: $URL"
  else
    megaupload_download "$URL" "${URL_PASSWORD:-$PASSWORD}"
  fi
fi
