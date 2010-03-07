#!/bin/bash
#
# Download a book (the images) from Google Books.
#
# Author: tokland@gmail.com
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
  { read PREFIX; read PAGES; } < <({ 
      echo "d = $JSON"
      echo 'print d["prefix"].decode("raw_unicode_escape")'
      echo 'print " ".join(x["pid"] for x in sorted(d["page"], key=lambda h: h["order"]))'
    } | python)

  debug "Prefix: $PREFIX"
  debug "Total pages: $(echo $PAGES | wc -w)"

  echo "$PAGES" | xargs -n1 | enumerate | tail -n+$STARTPAGE | 
      while read NPAGE PAGEID; do
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
    echo "$NPAGE" "$COOKIES" "$IMAGE_URL" "$OUTPUT"
  done
  rm -f $COOKIES
}

download_images() {
  while read NPAGE COOKIES IMAGE_URL OUTPUT; do
    debug "start image download (page $NPAGE): $IMAGE_URL"
    download -b "$COOKIES" "$IMAGE_URL" > "$OUTPUT" && RETVAL=0 || RETVAL=$?
    case $RETVAL in
    0) echo $OUTPUT;;
    22) debug "image download got a 404";;
    *) debug "error downloading image";;
    esac
  done    
}

download_gbook() {
  # This function division (get/download) was not really necessary, but the 
  # pipe parallelizes the download process.
  get_images_url "$@" | download_images
}

### Main

test $# -ge 1 || {
  debug "Usage: $(basename $0) GOOGLE_BOOK_URL [START_PAGE]"
  exit 1
} 

download_gbook "$@"
