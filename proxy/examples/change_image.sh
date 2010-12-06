#!/bin/bash
SIZE=$(identify - | awk '{print $3}')
convert seal.jpg -resize "!$SIZE" jpg:-
