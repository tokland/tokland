#!/bin/sh
# Toggle xfce4-panel visibility
set -e

INFO=$(xwininfo -name xfce4-panel)
STATE=$(echo "$INFO" | grep "Map State:" | head -n1 | awk -F: '{print $2}' | xargs)
WID=$(echo "$INFO" | grep "Window id:" | head -n1 | awk -F: '{print $3}' | awk '{print $1}')
if test "$STATE" = "IsViewable"; then
  xdotool windowminimize "$WID"
else
  xdotool windowmap "$WID"
fi
