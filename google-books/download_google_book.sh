#!/bin/bash
#
# Download a book (individual PNG images) from Google Books.
#
# Dependencies: bash, curl, python
# Author: tokland@gmail.com
#
# Example: Download a book and join the images into a single PDF (imagemagick required):
# 
#   $ convert $(download_google_book.sh "BOOK_URL") "book.pdf"
#
set -e

### Generic functions

parse() {
  local STRING=$(sed -n "/$1/ s/^.*$2.*$/\1/p" | head -n1) &&
    test "$STRING" && echo "$STRING" || return 1
}

download() { curl -s --fail -A "Chrome/5.0" "$@"; } 

debug() { echo "$@" >&2; }

enumerate() { cat -n; }

extract_href() { parse '<a' 'href="\([^"]*\)"'; }

break_html_lines() { sed 's/\(<\/[^>]*>\)/\1\n/g'; }

### Specific functions

get_images_url() {
  URL=$1
  STARTPAGE=${2:-1}
  COOKIES=$(mktemp)
  
  COVER=$(download -c "$COOKIES" "$URL")
  TITLE=$(echo "$COVER" | break_html_lines | 
          parse '<h1 class=title dir=ltr' '>\(.*\)<\/h1>')
  AUTHOR=$(echo "$COVER" | break_html_lines | 
           parse '<span class="addmd">' '>\(.*\)<\/span>' | cut -d" " -f3-)
  debug "Book: $TITLE ($AUTHOR)"
  test "$AUTHOR" && BASE="$AUTHOR - $TITLE" || BASE="$TITLE"
  PAGE_URL=$(echo "$COVER" | break_html_lines | 
             grep 'div class=html_page_image' | grep -o "<a.*>" | extract_href)
  JSON=$(echo "$COVER" | grep -o '{"page":.*"prefix":"[^"]*"}')
  #
  # I don't use heredocs to write the Python code because I prefer not to break indentation
  #
  # Here we take advantage of JSON being (virtually) valid Python code. 
  # We could use a JS interpreter (Spidermonkey, Rhino, ...) to do this, 
  # but Python is much nicer :-)    
  { read PREFIX; read PAGES; } < <({
      echo "d = $JSON"
      echo 'print d["prefix"].decode("raw_unicode_escape")'
      echo 'pids = [x["pid"] for x in sorted(d["page"], key=lambda h: h["order"])]'
      echo 'print " ".join(pids)'
    } | python)

  debug "Prefix: $PREFIX"
  debug "Total pages: $(echo $PAGES | wc -w)"

  echo "$PAGES" | xargs -n1 | enumerate | tail -n+$STARTPAGE | while read NPAGE PAGEID; do
    debug "Page: $NPAGE" 
    PAGE_URL="$PREFIX&pg=$PAGEID"
    debug "Page URL: $PAGE_URL"
    PAGE=$(download -b "$COOKIES" "$PAGE_URL")
    IMAGE_URL=$(echo "$PAGE" | grep -o "preloadImg.src = '[^']*'" | head -n1 | 
                awk '{print $3}' | tr -d "'") || 
      { debug "image not found"; return 1; }
    OUTPUT="$BASE.page$(printf "%03d" $NPAGE).png"
    debug "Image URL: $IMAGE_URL"
    #echo "$PAGE" > "$OUTPUT.html" # debug
    if test -e "$OUTPUT" -a -s "$OUTPUT"; then
      debug "File exists, skip download: $OUTPUT"
    else
      echo "$NPAGE" "$COOKIES" "$IMAGE_URL" "$OUTPUT"
    fi
  done
  rm -f $COOKIES
}

download_image() {
  local NPAGE=$1; local COOKIES=$2; local IMAGE_URL=$3; local OUTPUT=$4
  debug "start image download (page $NPAGE): $IMAGE_URL"
  download -b "$COOKIES" "$IMAGE_URL" > "$OUTPUT" && RETVAL=0 || RETVAL=$?
  case $RETVAL in
  0) echo $OUTPUT;;
  22) debug "warning: server reported this image is not downloadable (page $NPAGE)";;
  *) debug "error downloading image";;
  esac
}

download_gbook() {
  # There was no real need to split those functions (get/download), but the 
  # shell pipe parallelizes the process at cost 0. I just love UNIX.
  get_images_url "$@" | while read NPAGE COOKIES IMAGE_URL OUTPUT; do
    download_image $NPAGE $COOKIES $IMAGE_URL "$OUTPUT"
  done
}

### Main

test $# -ge 1 || {
  debug "Usage: $(basename $0) GOOGLE_BOOK_URL [START_PAGE]"
  exit 1
} 

download_gbook "$@"
