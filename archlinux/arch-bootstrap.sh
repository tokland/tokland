#!/bin/bash
#
# arch-bootstrap: Bootstrap a base Arch Linux system.
#
# Depends: bash, coreutils, wget, sed, awk, tar, gzip, chroot, xzutils
# Author: Arnau Sanchez <tokland@gmail.com>
# Report bugs to http://code.google.com/p/tokland/issues
#
# Some examples:
#
# $ bash arch-bootstrap.sh myarch 
# $ bash arch-bootstrap.sh myarch x86_64 
# $ bash arch-bootstrap.sh myarch x86_64 "ftp://ftp.archlinux.org"
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

BASIC_PACKAGES=(acl attr bzip2 expat glibc libarchive libfetch openssl pacman 
                pacman-mirrorlist xz-utils zlib)
EXTRA_PACKAGES=(filesystem coreutils bash grep awk file tar)
DEFAULT_REPO_URL="http://mirrors.kernel.org/archlinux"
DEFAULT_ARCH=i686

configure_pacman() {
  local DEST=$1; local ARCH=$2
  cp "/etc/resolv.conf" "$DEST/etc/resolv.conf"
  echo "Server = $REPO_URL/\$repo/os/$ARCH" >> "$DEST/etc/pacman.d/mirrorlist"
}

minimal_configuration() {
  local DEST=$1
  echo "root:x:0:0:root:/root:/bin/bash" > "$DEST/etc/passwd"
  # root/root
  echo "root:$1$GT9AUpJe$oXANVIjIzcnmOpY07iaGi/:14657::::::" > "$DEST/etc/shadow"
  touch "$DEST/etc/group"
  echo "bootstrap" > "$DEST/etc/hostname"
  test -c "$DEST/dev/null" || mknod "$DEST/dev/null" c 1 3
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

test $# -ge 1 || { 
  stderr "Usage: $(basename "$0") DESTDIR [i686|x86_64] [REPO_URL]"
  exit 2
}
   
DEST=$1
ARCH=${2:-$DEFAULT_ARCH}
REPO_URL=${3:-$DEFAULT_REPO_URL}

PACKDIR="arch-bootstrap"
REPO="${REPO_URL%/}/core/os/$ARCH"
debug "using core repository: $REPO"

debug "create package directory: $PACKDIR"
mkdir -p "$PACKDIR"

LIST_HTML_FILE="$PACKDIR/core_os-index.html"
test -s "$LIST_HTML_FILE" || { 
  debug "fetch packages list: $REPO/"
  # Force trailing '/' needed by FTP servers.
  fetch -O "$LIST_HTML_FILE" "$REPO/" ||
    { debug "Error: cannot fetch packages list: $REPO"; exit 1; }
}

debug "packages HTML index: $LIST_HTML_FILE"
LIST=$(< "$LIST_HTML_FILE" extract_href | awk -F"/" '{print $NF}' | sort -rn)
test "$LIST" || 
  { debug "Error: cannot process list file: $LIST_HTML_FILE"; exit 1; }  

debug "create destination directory: $DEST"
mkdir -p "$DEST"

debug "pacman package and dependencies: ${BASIC_PACKAGES[*]}"
for PACKAGE in ${BASIC_PACKAGES[*]}; do
  FILE=$(echo "$LIST" | grep -m1 "^$PACKAGE-[[:digit:]]")
  test "$FILE" || { debug "Error: cannot find package: $PACKAGE"; exit 1; }
  FILEPATH="$PACKDIR/$FILE"
  test -e "$FILEPATH" && check_compressed_integrity "$FILEPATH" || {
    debug "download package: $REPO/$FILE"
    fetch -O "$FILEPATH" "$REPO/$FILE"
  }
  debug "uncompress package: $FILEPATH"
  uncompress "$FILEPATH" "$DEST"
done

debug "configure DNS and pacman"
configure_pacman "$DEST" "$ARCH"

debug "re-install basic packages and install extra packages: ${EXTRA_PACKAGES[*]}"
chroot "$DEST" /usr/bin/pacman --noconfirm \
  -Syf ${BASIC_PACKAGES[*]} ${EXTRA_PACKAGES[*]}

debug "minimal configuration (DNS, passwd, hostname, mirrorlist, ...)" 
configure_pacman "$DEST" "$ARCH"
minimal_configuration "$DEST"

debug "done! you can now use the system (i.e. chroot \"$DEST\")"
