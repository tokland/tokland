#!/bin/bash
SIZE=$(identify - | awk '{print $3}')
convert examples/linux-penguin.jpg -resize "!$SIZE" jpg:-
