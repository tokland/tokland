#!/bin/sh
#
# Toggle xfce4-panel visibility
#
set -e

#PANEL_HEIGHT=$(xwininfo -name xfce4-panel | awk '$1 == "Height:" { print $2 }')
 
INFO=$(xwininfo -name xfce4-panel)
WID=$(echo "$INFO" | grep -m1 "Window id:" | awk -F: '{print $3}' | awk '{print $1}')
STATE=$(echo "$INFO" | grep -m1 "Map State:" | awk -F: '{print $2}' | xargs)

if test "$STATE" = "IsViewable"; then
  xdotool windowminimize "$WID"
  
  # Specific for panel of height 38 and screen height 920 and deltas hacks (WM decoration?)
  wmctrl -p -G -l | awk '{ if ($5+$7 == 882) print $1,$4,$5,$6,$7}' | while read WID X Y W H; do
    # /usr/include/ImageMagick/magick/geometry.h. 8: SouthGeometry
    # Y+18 comes probably from 38 (panel) - 10 (win top pad) + 10 (win bottom pad) = 18       
    wmctrl -i -r "$WID" -e "8,-1,$((Y+18)),-1,-1"
  done
  
else
  xdotool windowmap "$WID"
fi
