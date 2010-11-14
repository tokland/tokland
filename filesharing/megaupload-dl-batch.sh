#!/bin/bash
# Simple wrapper over megaupload-dl to build a downloading queue.
#
#   $ megaupload-dl-batch file_with_links.txt
#
# Dependencies: megaupload-dl, loop, and wrapper.
# Author: Arnau Sanchez <tokland@gmail.com>
# Website: http://code.google.com/p/tokland/wiki/MegauploadDownloader

set -e

_MEGAUPLOAD_DL_SOURCE=1 source megaupload-dl
STRING=$(declare -p EXIT_STATUSES | cut -d "'" -f2)
# add -f to 'loop' to force a never-ending queue (handy to work as daemon)
exec loop -w 5m -c -b 2 worker -r "{100..110}" -s "$STRING" "$1" megaupload-dl
