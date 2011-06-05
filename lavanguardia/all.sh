#!/bin/bash
set -e

cd $(dirname $0)	
FILE=$(bash ajedrez_vanguardia.sh)
bash process_pdf.sh "$FILE"
bash process_html.sh
