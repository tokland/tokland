#!/bin/bash
# Usage: pronounce [us|uk] word
#
# Play English words (and cache them) using The Free Dictionary webpage. 
# 
# Depends: mplayer
set -e
CACHE="/var/local/words"
LANGUAGE=en

# Get mp3 local path for the word pronuntiation (use a permanent cache) 
#
# $1: Country (US|UK)
# $2: Word to play
get_word_mp3_path() {
    COUNTRY0=$1; WORD0=$2
    COUNTRY1=$(echo ${COUNTRY0:-US} | tr '[a-z]' '[A-Z]')
    MP3PATH="$CACHE/${WORD0}_${COUNTRY1}.mp3"
    if ! test -e $MP3PATH; then 
        wget -U "Mozilla" -O - "http://www.thefreedictionary.com/$WORD0" | \
            grep -o "$LANGUAGE/$COUNTRY1/[^']*" | head -n1 | \
            xargs -ti wget -O $MP3PATH http://img.tfd.com/pron/mp3/{}.mp3
    fi            
    echo $MP3PATH
}        

# Main
[ $# -ge 2 ] || { echo "usage: $(basename $0) US|UK word [word...]"; exit 1; }
COUNTRY=$1
shift
for WORD in "$@"; do 
    echo $(get_word_mp3_path $COUNTRY $WORD)  
done | xargs mplayer
