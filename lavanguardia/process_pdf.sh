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
        window.addEventListener('load', function() {
          var fen = '$FEN';
          setTimeout(function() {
            var frame = document.getElementById('board').contentWindow;
            frame.setLevel(2);
            var white_to_play = fen.split(" ")[1] == 'w';
            frame.newGame(!white_to_play);
            frame.p.SetFEN(fen);
          }, 50);
        });
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
        <iframe id="board" width="410" height="440" src="/shredder/online/playshredder/playshredder.php?lang=en" frameborder=0></iframe>
      </p>
    </body>
  </html>" > output/$BASE.html.template
done
