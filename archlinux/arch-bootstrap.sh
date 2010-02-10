#!/bin/bash
#
# arch-bootstrap: Bootstrap a base Arch Linux system.
# 
# Depends: wget, tar, gzip, chroot
# Author: Arnau Sanchez <tokland@gmail.com>
#
# Packages needed by pacman can be obtained that way:
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
extract_href() { sed -n "s/^.*<a [^>]*href=\"\([^\"]*\)\".*$/\1/p"; }

# Simple wrapper around wget
fetch() { wget -c --passive-ftp --quiet "$@"; }

### Main

BASIC_PACKAGES=(acl attr bzip2 glibc libarchive libfetch openssl pacman 
                pacman-mirrorlist xz-utils zlib)
EXTRA_PACKAGES=(coreutils bash)

test $# -ge 2 || { 
  stderr "Usage: $(basename "$0") DESTDIR i686|x86_64 [REPO_URL] [CORE_OS_HTMLFILE]"
  exit 2
}
   
DEST=$1
ARCH=$2
REPO_URL=${3:-"http://mirrors.kernel.org/archlinux"}
LIST_HTML=$4

REPO="${REPO_URL%/}/core/os/$ARCH"
debug "using core repository: $REPO"

if test "$LIST_HTML"; then
  debug "using packages HTML index: $LIST_HTML"
  LIST=$(extract_href < "$LIST_HTML")
else
  debug "fetching packages list: $REPO"
  # Force trailing '/' needed for FTPs server. Also, get only package relative paths
  LIST=$(fetch -O - "$REPO/" | extract_href | awk -F"/" '{print $NF}') ||
    { debug "cannot fetch packages list: $REPO"; exit 1; }
fi 

debug "creating destination directory: $DEST"
mkdir -p "$DEST"

debug "fetching pacman and dependencies: ${BASIC_PACKAGES[*]}"
for PACKAGE in ${BASIC_PACKAGES[*]}; do
  FILE=$(echo "$LIST" | grep "^$PACKAGE-[[:digit:]]" | sort -n | tail -n1)
  test "$FILE" || { debug "cannot find package: $PACKAGE"; exit 1; }
  test -f "$FILE" && gunzip -t "$FILE" || {
    debug "downloading: $REPO/$FILE"
    fetch "$REPO/$FILE"
  }
  debug "uncompressing package: $FILE"
  tar xzf "$FILE" -C "$DEST"
done

debug "doing minimal system configuration (DNS, passwd, hostname, mirrorlist)" 
cp "/etc/resolv.conf" "$DEST/etc/resolv.conf"
echo "root:x:0:0:root:/root:/bin/bash" > "$DEST/etc/passwd"
echo "bootstrap" > "$DEST/etc/hostname"
echo "Server = $REPO_URL/\$repo/os/$ARCH" >> "$DEST/etc/pacman.d/mirrorlist"

debug "installing extra packages: ${EXTRA_PACKAGES[*]}"
chroot "$DEST" /usr/bin/pacman --noconfirm -Syf ${EXTRA_PACKAGES[*]}

debug "done - you should now be able to use the system (i.e. chroot \"$DEST\")"
