#!/bin/bash
# Simple queue downloader wrapper over megaupload-dl.
#
#   $ megaupload-dl-batch file_with_links.txt
#
# Dependencies: megaupload-dl, loop, and wrapper.
#  
# Author: Arnau Sanchez <tokland@gmail.com>
# Website: http://code.google.com/p/tokland/wiki/MegauploadDownloader
#
set -e

_MEGAUPLOAD_DL_SOURCE=1 source megaupload-dl
STRING=$(declare -p EXIT_STATUSES | cut -d "'" -f2)
# adding option -f to 'loop' would force a never-ending queue (handy for servers)
exec loop -w 5m -c -b 2 worker -r "{100..110}" -s "$STRING" megaupload-dl "$@"
