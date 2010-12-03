#!/bin/bash
#
# Convert a Chromium cookies file (sqlite3) to the old Netscape text format
#
# $ chromium-cookies-to-netscape.sh [PROFILE] > my_cookies_in_old_netscape_format.txt
#
# Then you can do:
# 
#   $ wget --load-cookies=cookies.txt ... 
#
set -e

# Replace a column field for each line in stdin
replace_column_value() {
  awk "BEGIN{OFS=FS=\"$1\"} {\$$2 = ((\$$2==\"$3\")?\"$4\":\"$5\"); print}"
}

# Convert a Chrome cookie to Netscape text format
sqlite2txt() {   
  FILE=$1
  TEMP=$(tempfile) # If Chrome is open the database file will be locked
  cp "$FILE" "$TEMP"
  echo "# Netscape HTTP Cookie File"
  echo ".mode tabs
    SELECT host_key, (host_key GLOB '.*'), path, 'FALSE', expires_utc, name, value
    FROM cookies;
  " | sqlite3 "$TEMP" | replace_column_value "\t" 2 "1" "TRUE" "FALSE" | \
      recode iso8859-1..utf-8 | tr -d '[áéíóúàèìòùñ]'
  rm -f "$TEMP"
}

# Main
PROFILE=$1
PROFILE_DIR=$(if test "$PROFILE"; then 
  # this is my personal configuration, change it if necessary
  echo "$HOME/.config/chromium-profiles/$PROFILE"
else
  echo "$HOME/.config/chromium"
fi)
sqlite2txt "$PROFILE_DIR/Default/Cookies"
