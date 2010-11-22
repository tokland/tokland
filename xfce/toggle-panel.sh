#!/bin/sh
#
# Toggle xfce4-panel visibility
#
set -e

INFO=$(xwininfo -name xfce4-panel)
WID=$(echo "$INFO" | grep -m1 "Window id:" | awk -F: '{print $3}' | awk '{print $1}')
STATE=$(echo "$INFO" | grep -m1 "Map State:" | awk -F: '{print $2}' | xargs)

if test "$STATE" = "IsViewable"; then
  xdotool windowminimize "$WID"
else
  xdotool windowmap "$WID"
fi
