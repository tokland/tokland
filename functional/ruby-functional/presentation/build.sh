NAME=functional-ruby
python2 rst-directive.py \
    --stylesheet=pygments.css \
    --theme-url=ui/small-black \
    ${NAME}.txt > ${NAME}.html
