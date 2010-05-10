#!/bin/bash
#
# Get RTSP links for Gattopardo on RAI Radio
set -e

URL="http://www.radio.rai.it/radio3/terzo_anello/alta_voce/archivio_2004/eventi/2004_02_03_gattopardo/##"
curl "$RAM_URL" | grep -o "http://.*ram'" | tr -d "'" | while read URL; do
  curl "$RAM_URL"
  echo # so we have one link per line
done
