#!/bin/bash
set -e

PDF=$1
IMAGE=$2

CROP1="675x850+2600+2200"
CROP2="675x600+2600+3050"
CROP3="500x425+2050+3425"

FMT=png
IMG0=$(mktemp --suffix=".$FMT")
IMG1=$(mktemp --suffix=".$FMT")
IMG2=$(mktemp --suffix=".$FMT")
IMG3=$(mktemp --suffix=".$FMT")

convert -density 300 "$PDF" $IMG0
convert $IMG0 -crop "$CROP1" $IMG1
convert $IMG0 -crop "$CROP2" $IMG2
convert $IMG0 -crop "$CROP3" $IMG3

convert -size "1875x850" xc:white "$IMAGE"
composite -geometry "+0+0" $IMG1  "$IMAGE" "$IMAGE"
composite -geometry "+675+110" $IMG2 "$IMAGE" "$IMAGE"
composite -geometry "+1350+110" $IMG3 "$IMAGE" "$IMAGE"
mogrify -resize '50%' "$IMAGE"

rm -f $IMG0 $IMG1 $IMG2
