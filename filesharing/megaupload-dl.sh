#!/bin/bash

# Download a file from Megaupload.
#
# $ megaupload-dl http://www.megaupload.com/?d=S9BJRU17
# lao_tzu-the_tao_te_ching.pdf
#
# Author: Arnau Sanchez <tokland@gmail.com>
# Documentation: http://code.google.com/p/tokland/wiki/MegauploadDownloader

EXIT_STATUSES=(
  [0]=ok
  # Non-retryable errors
  [1]=arguments
  [2]=link_dead
  [3]=link_unknown_problem
  [4]=parse
  [5]=password_required
  [6]=password_wrong
  # Retryable errors
  [100]=parse_nonfatal
  [101]=network
  [102]=link_temporally_unavailable
  [103]=another_download_active
)

# Set EXIT_STATUS_${KEY} variables (poor man's associative array for Bash)
for SC in ${!EXIT_STATUSES[@]}; do
  eval "EXIT_STATUS_${EXIT_STATUSES[$SC]}=$SC"
done

# Echo a message ($@) to stderr
stderr() { echo -e "$@" >&2; }

# Echo an info message ($@) to stderr
info() { stderr "--- $@"; }

# Check if regular expression $1 is found in string $2 (case insensitive)
match() { grep -qi "$1" <<< "$2"; }

# Strip string from stdin
strip() { sed "s/^[[:space:]]*//; s/[[:space:]]*$//"; }
        
# Get first line in stdin that matches regexp $1 and parse string $2 (case insensitive)
parse() { local S=$(sed -n "/$1/s/^.*$2.*$/\1/p" | head -n1) && test "$S" && echo "$S"; }

# Like parse() but do not write errors to stderr
parse_quiet() { parse "$@" 2>/dev/null; }

# Sleep $1 seconds while showing a real-time MM:SS countdown
sleep_countdown() {
  local SECS
  test -t 2 || { info "$2"; sleep $1; return; }
  stderr -n "--- $2 - "
  for ((SECS=$1; SECS>=0; SECS--)); do
    local STR=$(date -d"0+$SECS seconds" "+%M:%S")
    stderr -n "$STR"
    test $SECS -gt 0 && sleep 1 && printf "%${#STR}s" | tr ' ' '\b' >&2
  done
  stderr
}

# Wrapper over curl (appends global variable GLOBAL_CURL_OPTS)
curlw() { curl --connect-timeout 20 --speed-time 60 --retry 5 $GLOBAL_CURL_OPTS "$@"; }

# Echo error with key $1 (see EXIT_STATUSES_*), message $2 and optional debug ($3)
error() {
  local KEY=$1 MSG=${2:-""} DEBUGCONTENT=${3:-""}
  stderr -n "ERROR [$KEY:$BASH_LINENO]"
  test "$MSG" && stderr ": $MSG" || stderr
  if test "$DEBUGCONTENT"; then
    local TEMP=$(tempfile)
    echo "$DEBUGCONTENT" > $TEMP
    stderr "debug content saved: $TEMP"
  fi
  local VAR="EXIT_STATUS_$KEY"
  echo ${!VAR}
}

# Get the page for a MU URL ($1) (if $2 = 'wait', loop on wait messages)
get_main_page() {
  local URL=$1 OPT=$2

  while true; do
    info "GET $URL"
    PAGE=$(curlw -sS "$URL") || return $(error network "downloading page: $URL")
    ERROR_URL=$(echo "$PAGE" | parse_quiet '<BODY>.*document.loc' "location='\([^']*\)'") || true

    if match 'class="downl_main"' "$PAGE"; then
      info "Filename: $(echo "$PAGE" | parse 'download_file_name' '>\(.*\)<\/div' | strip)"
      info "Description: $(echo "$PAGE" | parse 'File description:' '>\(.*\)' | strip)"
      info "Size: $(echo "$PAGE" | parse 'download_file_size' '>\(.*\)<\/div' | strip)"
      echo "$PAGE"
      break
    elif test "$ERROR_URL"; then
      ERROR_PAGE=$(curlw -sS "$ERROR_URL") ||
        return $(error network "downloading error page")
      WAIT=$(echo "$ERROR_PAGE" | parse_quiet "check back in" "in \([[:digit:]]\+\) min") ||
        return $(error parse_nonfatal "no wait time not found in error page" "$ERROR_PAGE")
      if test "$OPT" = "wait"; then
        sleep_countdown $((WAIT*60)) "The server asked us to wait $WAIT minutes"
        continue
      else
        info "We were redirected to the wait error page but 'nowait' option is enabled"
        break
      fi
    elif match 'class="bott_p_na_lnk"' "$PAGE"; then
      return $(error link_dead "Link is dead")
    elif match 'class="bott_p_access"' "$PAGE"; then
      return $(error link_temporally_unavailable "Access temporarily restricted")
    elif match 'class="bott_p_access2"' "$PAGE"; then
      return $(error link_temporally_unavailable "File is temporarily unavailable")
    else
      return $(error parse "Could not parse main page" "$PAGE")
    fi
  done
}

# Download a MU link ($1) with optional password ($2) and echo file path to stdout
megaupload_download() {
  local URL=$1 PASSWORD=${2:-""}

  while true; do
    PAGE=$(get_main_page "$URL" "wait") || return $?

    # Wait page
    PASSRE='name="filepassword"'
    PAGE2=$(if match "download_regular_usual" "$PAGE"; then
      echo "$PAGE"
    elif match "$PASSRE" "$PAGE"; then
      # Password-protected link
      test "$PASSWORD" || return $(error password_required "No password provided")
      info "POST $URL (filepassword=$PASSWORD)"
      PAGE2=$(curlw -sS -F "filepassword=$PASSWORD" "$URL") ||
        return $(error network "posting password form")
      match "$PASSRE" "$PAGE2" &&
        return $(error password_wrong "Password error")
      echo "$PAGE2"
    else
      return $(error parse "main page" "$PAGE")
    fi) || return $?

    FILEURL=$(echo "$PAGE2" | parse 'class="download_regular_usual"' 'href="\([^"]*\)"') ||
      return $(error parse "download link not found" "$PAGE2")
    FILENAME=$(basename "$FILEURL" | { recode html.. || cat; }) # make recode optional
    info "Output filename: $FILENAME"
    info "GET $FILEURL"
    INFO=$(curlw -w "%{http_code} %{size_download}" -g -C - -o "$FILENAME" "$FILEURL") ||
      return $(error network "downloading file")
    read HTTP_CODE SIZE_DOWNLOAD <<< "$INFO"

    if match "5.." "$HTTP_CODE" -a test $SIZE_DOWNLOAD -gt 0; then
      # This is tricky: if we got an unsuccessful 5xx code (probably a 503), 
      # FILENAME will now contain the error page, so we better delete it.
      info "delete file: $FILENAME"
      rm -f "$FILENAME"
    fi

    if match "503" "$HTTP_CODE"; then
      LIMIT_PAGE=$(curlw -sS "http://www.megaupload.com/?c=premium&l=1") ||
        return $(error network "Downloading error page")
      match "finish this download before" "$LIMIT_PAGE" &&
        return $(error another_download_active)
      MINUTES=$(echo "$LIMIT_PAGE" | parse "Please wait" "wait \([[:digit:]]\+\) min") ||
        return $(error parse_nonfatal "no wait time in limit exceeded page" "$LIMIT_PAGE")
      sleep_countdown $((MINUTES*60)) "Download limit exceeded, waiting $MINUTES minutes"
      continue
    elif match "416" "$HTTP_CODE"; then
      info "HTTP code 416: MU inexplicably returns this when asked for a fully downloaded file"
    elif ! match "2.." "$HTTP_CODE"; then
      return $(error network "unsuccessful (and unexpected) HTTP code: $HTTP_CODE")
    fi

    # File successfully downloaded: echo the path to stdout and break loop
    echo "$FILENAME"
    break
  done
}

usage() {
  stderr "Usage: $(basename $0) [-c] [-p PASSWORD] [-o CURL_OPTIONS] URL[|PASSWORD]\n"
  stderr "  Download a file from megaupload.com"
}

### Main

if test -z "$_MEGAUPLOAD_DL_SOURCE"; then
  set -e -u -o pipefail
  GLOBAL_CURL_OPTS=
  PASSWORD=
  CHECKONLY=
  test $# -eq 0 && set -- "-h"
  while getopts "cp:o:h" ARG; do
    case "$ARG" in
    c) CHECKONLY=1;;
    p) PASSWORD=$OPTARG;;
    o) GLOBAL_CURL_OPTS=$OPTARG;;
    *) usage
       exit $EXIT_STATUS_arguments;;
    esac
  done
  shift $(($OPTIND-1))
  IFS="|" read URL URL_PASSWORD <<< "$1"

  if test "$CHECKONLY"; then
    get_main_page "$URL" "nowait" > /dev/null
    info "Link is alive: $URL"
  else
    megaupload_download "$URL" "${URL_PASSWORD:-$PASSWORD}"
  fi
fi
