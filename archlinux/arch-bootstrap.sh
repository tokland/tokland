#!/bin/bash

# arch-bootstrap: Bootstrap a base Arch Linux system.
#
# Depends: coreutils, wget, sed, awk, tar, gzip, chroot, xz
# Bug tracker: http://code.google.com/p/tokland/issues
# Author: Arnau Sanchez <tokland@gmail.com>
#
# Install:
#
#   $ sudo install -m 755 arch-bootstrap.sh /usr/local/bin/arch-bootstrap
#
# Some examples:
#
#   $ sudo arch-bootstrap myarch 
#   $ sudo arch-bootstrap myarch x86_64 
#   $ sudo arch-bootstrap myarch x86_64 "ftp://ftp.archlinux.org"
#
# And then chroot to the destination directory (root/root):
#
#   $ sudo chroot myarch

set -e

# Output to standard error
stderr() { echo "$@" >&2; }

# Output debug message to standard error
debug() { stderr "--- $@"; }

# Extract href attribute from HTML link
extract_href() { sed -n '/<a / s/^.*<a [^>]*href="\([^\"]*\)".*$/\1/p'; }

# Simple wrapper around wget
fetch() { wget -c --passive-ftp --quiet "$@"; }

### Main

# Packages needed by pacman (BASIC_PACKAGES) are obtained this way:
# 
#   $ for PACKAGE in $(ldd /usr/bin/pacman | grep "=> /" | awk '{print $3}'); do 
#       pacman -Qo $PACKAGE 
#     done | awk '{print $5}' | sort -u | xargs
BASIC_PACKAGES=(acl attr bzip2 expat glibc libarchive libfetch openssl pacman 
                pacman-mirrorlist xz zlib curl gpgme libssh2 libassuan libgpg-error)
EXTRA_PACKAGES=(coreutils bash grep awk file tar initscripts)
DEFAULT_REPO_URL="http://mirrors.kernel.org/archlinux"
DEFAULT_ARCH=i686

configure_pacman() {
  local DEST=$1; local ARCH=$2
  cp "/etc/resolv.conf" "$DEST/etc/resolv.conf"
  echo "Server = $REPO_URL/\$repo/os/$ARCH" >> "$DEST/etc/pacman.d/mirrorlist"
}

minimal_configuration() {
  local DEST=$1
  mkdir -p "$DEST/dev"
  echo "root:x:0:0:root:/root:/bin/bash" > "$DEST/etc/passwd"
  # create root user (password: root)
  echo "root:$1$GT9AUpJe$oXANVIjIzcnmOpY07iaGi/:14657::::::" > "$DEST/etc/shadow"
  touch "$DEST/etc/group"
  echo "bootstrap" > "$DEST/etc/hostname"
  test -e "$DEST/etc/mtab" || echo "rootfs / rootfs rw 0 0" > "$DEST/etc/mtab"
  test -e "$DEST/dev/null" || mknod "$DEST/dev/null" c 1 3
  sed -i "s/^[[:space:]]*\(CheckSpace\)/# \1/" "$DEST/etc/pacman.conf"
}

check_compressed_integrity() {
  local FILEPATH=$1
  case "$FILEPATH" in
  *.gz) gunzip -t "$FILEPATH";;
  *.xz) xz -t "$FILEPATH";;
  *) debug "Error: unknown package format: $FILEPATH"
     return 1;;
  esac
}

uncompress() {
  local FILEPATH=$1; local DEST=$2
  case "$FILEPATH" in
  *.gz) tar xzf "$FILEPATH" -C "$DEST";;
  *.xz) xz -dc "$FILEPATH" | tar x -C "$DEST";;
  *) debug "Error: unknown package format: $FILEPATH"
     return 1;;
  esac
}  

### Main

if test $# -lt 1; then
  stderr "Usage: $(basename "$0") DESTINATION_DIRECTORY [i686|x86_64] [REPO_URL]"
  exit 2
fi
   
DEST=$1
ARCH=${2:-$DEFAULT_ARCH}
REPO_URL=${3:-$DEFAULT_REPO_URL}

PACKDIR="arch-bootstrap"
REPO="${REPO_URL%/}/core/os/$ARCH"
debug "using core repository: $REPO"

debug "create package directory: $PACKDIR"
mkdir -p "$PACKDIR"

LIST_HTML_FILE="$PACKDIR/core_os_$ARCH-index.html"
if ! test -s "$LIST_HTML_FILE"; then 
  debug "fetch packages list: $REPO/"
  # Force trailing '/' needed by FTP servers.
  fetch -O "$LIST_HTML_FILE" "$REPO/" ||
    { debug "Error: cannot fetch packages list: $REPO"; exit 1; }
fi

debug "packages HTML index: $LIST_HTML_FILE"
LIST=$(< "$LIST_HTML_FILE" extract_href | awk -F"/" '{print $NF}' | sort -rn)
test "$LIST" || 
  { debug "Error processing list file: $LIST_HTML_FILE"; exit 1; }  

debug "create destination directory: $DEST"
mkdir -p "$DEST"

debug "pacman package and dependencies: ${BASIC_PACKAGES[*]}"
for PACKAGE in ${BASIC_PACKAGES[*]}; do
  FILE=$(echo "$LIST" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$") ||
    { debug "Error: cannot find package: $PACKAGE"; exit 1; }
  FILEPATH="$PACKDIR/$FILE"
  if ! test -e "$FILEPATH" || ! check_compressed_integrity "$FILEPATH"; then
    debug "download package: $REPO/$FILE"
    fetch -O "$FILEPATH" "$REPO/$FILE"
  fi
  debug "uncompress package: $FILEPATH"
  uncompress "$FILEPATH" "$DEST"
done

debug "configure DNS and pacman"
configure_pacman "$DEST" "$ARCH"

debug "re-install basic packages and install extra packages: ${EXTRA_PACKAGES[*]}"
minimal_configuration "$DEST"
LC_ALL=C chroot "$DEST" /usr/bin/pacman --noconfirm --arch $ARCH \
  -Syf ${BASIC_PACKAGES[*]} ${EXTRA_PACKAGES[*]}

debug "minimal configuration (DNS, passwd, hostname, mirrorlist, ...)" 
configure_pacman "$DEST" "$ARCH"

echo "Done! you can now use the system: chroot \"$DEST\""
echo
echo "Note: some apps may require system directories /dev, /proc or /sys. Hint:"
echo "  mount --bind /dev \"$DEST/dev\""
