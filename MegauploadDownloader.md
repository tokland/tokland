_As you know Megaupload was shut down on January 2012, but I leave the script anyway for those interested in Bash programming._

# Introduction #

`megaupload-dl` downloads files from Megaupload (free download, no account required). It is a shell script (Bash), so you will need a UNIX-like operating system (GNU/Linux, BSD, OSX, Cygwin, ...).

This script is free-software licensed under the [GNU/GPL3](http://www.gnu.org/licenses/gpl-3.0-standalone.html).

# Dependencies #

You will need _bash_ (>= 3), _curl_, and _recode_ (optional). On a Debian-based distro this should suffice:

```
$ sudo apt-get install curl recode
```

# Download & Install #

[megaupload-dl.sh](http://tokland.googlecode.com/svn/trunk/filesharing/megaupload-dl.sh) ([details](http://code.google.com/p/tokland/source/browse/trunk/filesharing/megaupload-dl.sh))

```
$ wget http://tokland.googlecode.com/svn/trunk/filesharing/megaupload-dl.sh
$ sudo install megaupload-dl.sh /usr/local/bin/megaupload-dl
```

# Usage examples #

**Download a single file:**

```
$ megaupload-dl http://www.megaupload.com/?d=S9BJRU17
lao_tzu-the_tao_te_ching.pdf
```

**Download a password-protected file:**

```
$ megaupload-dl -p tokland http://www.megaupload.com/?d=FDPAE94B
xkcd2.jpg
```

**Download a file using extra curl options:**

```
$ megaupload-dl -o "--limit-rate 50K" http://www.megaupload.com/?d=S9BJRU17
lao_tzu-the_tao_te_ching.pdf
```

**Check if a link is alive:**

```
$ megaupload-dl -c http://www.megaupload.com/?d=S9BJRU17
```

**Download a list of files:**

```
$ xargs -d"\n" -n1 megaupload-dl < file_with_one_link_per_line.txt
```

# Build a safe queue downloader #

Download and install these three scripts: [worker](http://tokland.googlecode.com/svn/trunk/tools/worker.sh), [loop](http://tokland.googlecode.com/svn/trunk/tools/loop.sh) and [megaupload-dl-batch](http://tokland.googlecode.com/svn/trunk/filesharing/megaupload-dl-batch.sh).

```
$ megaupload-dl-batch file_with_links.txt
```

How it works: `worker` comments out links in `file_with_links.txt` with _#_ (if successful) or _#error_ (if unsuccessful), while `loop` executes `worker` until it succeeds. This way all links in `file_with_links.txt` will be eventually downloaded or marked with a non-retryable error.

# Motivation #

This script is about programming: how to write a minimal shell script downloader with modular, compact and clean code. If you feel the script does not fulfill this goal in any aspect, feel free to contact me.

If you only want to automatically download from file-sharing sites you should check [plowshare](http://code.google.com/p/plowshare/), it supports  lots of sites and it's highly configurable.

# Feedback #

  * Email: Arnau Sanchez <tokland AT gmail.com>
  * Report bugs/suggestions: http://code.google.com/p/tokland/issues/list