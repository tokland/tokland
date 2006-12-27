#!/bin/bash
if [ -z "$1" ]; then exit 1; fi
TEXTFILE=$1
VERSION=$(cat $TEXTFILE.version)
DATE=$(date +%D)
asciidoc --attribute=revision=$VERSION --attribute=date=$DATE $TEXTFILE
exit 0
