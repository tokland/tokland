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
  FEN=$(./pdf2fen.py "$PDF")

  echo "
  <html>
    <head>
      <title>La Vanguardia - Ajedrez $DATE</title> 
      <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
      <script>
        window.addEventListener("load", function() {
          var fen = 'b1R2nk1/5ppp/1p3n2/5N2/1b2p3/1P2BP2/q3BQPP/6K1 w KQkq - 0 1';
          setTimeout(function() {
            var position = document.getElementById('board').contentWindow.p;
            position.SetFEN(fen);
          }, 50);
      </script>      
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
        <input accesskey=\"s\" type=\"text\" size=\"80\" onclick=\"select()\" value=\"$FEN\">
      </p>
      <p>
        <a href=\"mailto:tokland@gmail.com\">Contactar</a>
        <br />
        <iframe id="board" width="410" height="440" src="//download.zaudera.com:81/shredder/online/playshredder/playshredder.php?lang=en" frameborder=0></iframe>
      </p>
    </body>
  </html>" > output/$BASE.html.template
done
