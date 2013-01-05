#!/bin/bash
set -e

cd $(dirname $0)
DATE=$(date --date="31 days ago" "+%Y-%m-%d")
FILE=$(bash ajedrez_vanguardia.sh "$DATE")
bash process_pdf.sh "$FILE"
bash process_html.sh
