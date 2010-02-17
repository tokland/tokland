#!/bin/bash
#
# arch-bootstrap: Bootstrap a base Arch Linux system.
#
# Depends: wget, sed, awk, tar, gzip, chroot
# Author: Arnau Sanchez <tokland@gmail.com>
# Report bugs to http://code.google.com/p/tokland/issues
#
# Some examples:
#
# $ bash arch-bootstrap.sh myarch x86_64
# $ bash arch-bootstrap.sh myarch x86_64 "ftp://ftp.archlinux.org"
# $ bash arch-bootstrap.sh myarch x86_64 "" "file_containing_core_os_index.html"
# 
# Packages list needed by pacman can be obtained this way:
# 
# $ for PACKAGE in $(ldd /usr/bin/pacman | grep "=> /" | awk '{print $3}'); do 
#     pacman -Qo $PACKAGE 
#   done | awk '{print $5}' | sort -u | xargs
#
set -e

### Generic functions

# Output to standard error
stderr() { echo "$@" >&2; }

# Output debug message to standard error
debug() { stderr "--- $@"; }

# Extract href attribute from HTML link
extract_href() { sed -n '/<a / s/^.*<a [^>]*href="\([^\"]*\)".*$/\1/p'; }

# Simple wrapper around wget
fetch() { wget -c --passive-ftp --quiet "$@"; }

### Main

BASIC_PACKAGES=(acl attr bzip2 glibc libarchive libfetch openssl pacman 
                pacman-mirrorlist xz-utils zlib)
EXTRA_PACKAGES=(coreutils bash filesystem)
DEFAULT_REPO_URL="http://mirrors.kernel.org/archlinux"

test $# -ge 2 || { 
  stderr "Usage: $(basename "$0") DESTDIR i686|x86_64 [REPO_URL] [CORE_OS_HTMLFILE]"
  exit 2
}
   
DEST=$1
ARCH=$2
REPO_URL=${3:-$DEFAULT_REPO_URL}
LIST_HTML_FILE=$4

REPO="${REPO_URL%/}/core/os/$ARCH"
debug "core repository: $REPO"

# Get filename list for packages
if test "$LIST_HTML_FILE"; then
  debug "packages HTML index: $LIST_HTML_FILE"
  LIST_HTML=$(< "$LIST_HTML_FILE") ||
    { debug "Error: packages list file not found: $LIST_HTML_FILE"; exit 1; }
else
  debug "fetch packages list: $REPO/"
  # Force trailing '/' needed by FTP servers.
  LIST_HTML=$(fetch -O - "$REPO/") ||
    { debug "Error: cannot fetch packages list: $REPO"; exit 1; }
fi 
LIST=$(echo "$LIST_HTML" | extract_href | awk -F"/" '{print $NF}' | sort -r -n) 

debug "create destination directory: $DEST"
mkdir -p "$DEST"

debug "pacman package and dependencies: ${BASIC_PACKAGES[*]}"
for PACKAGE in ${BASIC_PACKAGES[*]}; do
  FILE=$(echo "$LIST" | grep -m1 "^$PACKAGE-[[:digit:]]")
  test "$FILE" || { debug "Error: cannot find package: $PACKAGE"; exit 1; }
  test -f "$FILE" && gunzip -q -t "$FILE" || {
    debug "download: $REPO/$FILE"
    fetch "$REPO/$FILE"
  }
  debug "uncompress package: $FILE"
  tar xzf "$FILE" -C "$DEST"
done

debug "minimal configuration (DNS, passwd, hostname, mirrorlist, ...)" 
cp "/etc/resolv.conf" "$DEST/etc/resolv.conf"
# root/root
echo "root:$1$GT9AUpJe$oXANVIjIzcnmOpY07iaGi/:14657::::::" > "$DEST/etc/shadow"
touch "$DEST/etc/group"
echo "bootstrap" > "$DEST/etc/hostname"
echo "Server = $REPO_URL/\$repo/os/$ARCH" >> "$DEST/etc/pacman.d/mirrorlist"

debug "clean re-install of basic packages: ${BASICK_PACKAGES[*]}"
chroot "$DEST" /usr/bin/pacman --noconfirm -Syf ${BASIC_PACKAGES[*]}

debug "install extra packages: ${EXTRA_PACKAGES[*]}"
chroot "$DEST" /usr/bin/pacman --noconfirm -Syf ${EXTRA_PACKAGES[*]}
mknod "$DEST/dev/null c 1 3"

debug "done! you should now be able to use the system (i.e. chroot \"$DEST\")"
