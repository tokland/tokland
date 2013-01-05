#!/bin/bash
set -e

#MONTHS=(enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre)

MONTHS=(gener febrer marÇ abril maig juny juliol agost setembre octubre novembre desembre)
PDF=$1
STRDATE=$(pdftohtml -xml -stdout "$PDF" | grep '<text top="1"' | tail -n1 | \
          grep -o ">.*<" | tr -d '<>' | cut -d"," -f2- | xargs | tr '[A-Z]' '[a-z]' | cut -d"-" -f1)
read DAY MONTH YEAR <<< "$STRDATE"  
NMONTH=$(echo ${MONTHS[*]} | xargs -n1 | cat -n | awk "\$2 == \"$MONTH\"" | \
         awk '{print $1}' | xargs)

DAY2=$(echo $DAY | cut -d"-" -f1)
printf "%d-%02d-%02d %s\n" $YEAR $NMONTH $DAY2 "$STRDATE"
