#!/bin/sh
# Simple queue downloader wrapper over megaupload-dl.
#
# Depedencies: megaupload-dl, loop, and wrapper.
#  
# Author: Arnau Sanchez <tokland@gmail.com>
# Website: http://code.google.com/p/tokland/wiki/MegauploadDownloader

# add -f to 'loop' to force a never-ending queue downloader.
exec loop -w 5m -c -b 2 worker megaupload-dl "{100..110}" "$@"
