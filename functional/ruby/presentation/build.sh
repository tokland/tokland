#!/bin/sh
set -e

SOURCE=${1:-"functional-ruby.txt"}

python2 rst-directive.py \
    --stylesheet=pygments.css \
    --theme-url=ui/small-black \
    $SOURCE > $(basename $SOURCE ".txt").html
    
xvfb-run ruby topdf.rb
