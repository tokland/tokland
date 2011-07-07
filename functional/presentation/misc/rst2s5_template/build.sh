NAME=index
python2 rst-directive.py \
    --stylesheet=pygments.css \
    --theme-url=ui/small-black \
    ${NAME}.rst > ${NAME}.html
