#!/bin/bash
set -e

mkdir -p output

for PDF in "$@"; do 
  DATE0=$(bash extract_date.sh "$PDF")
  DATE=$(echo "$DATE0" | awk '{print $1}')
  STRDATE=$(echo "$DATE0" | cut -d" " -f2-)
  BASE="vgd-chess-$DATE"
  IMAGE="output/$BASE.png"

  bash extract_image.sh "$PDF" "$IMAGE"
  FEN=$(python pdf2fen.py "$PDF")

  echo "
  <html>
    <head>
      <title>La Vanguardia - Ajedrez $DATE</title> 
      <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
    </head>
    
    <body>
      <p>
        <a href=\"%PREVIOUS%\"><< Anterior</a>
        |
        <a href=\"%NEXT%\">Siguiente >> </a>
      </p>
      <p>
        <img src=\"$(basename $IMAGE)\" />
      </p>
      <p>
        <a href=\"http://es.wikipedia.org/wiki/Notaci%C3%B3n_de_Forsyth-Edwards\">FEN</a>:
        <input type=\"text\" size=\"80\" onclick=\"select()\" value=\"$FEN\">
      </p>
      <p>
        <a href=\"mailto:tokland@gmail.com\">Contactar</a>
      </p>
    </body>
  </html>" > output/$BASE.html.template
done
