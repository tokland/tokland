Those are some of the projects and scripts I've developed over the years. Unless specified all this software is licensed under the GNU General Public License (GNU-GPL) v3. Feedback is appreciated: tokland AT gmail.com



# Javascript #

## Type-ahead-find extension for Chrome/Chromium ##

Type-ahead-find is an extremely useful accessibility feature (a core functionality in major browsers like Firefox or Safari) which is not implemented in Chrome (nor planed to be). So, until Chromium developers come to their senses, we will have to use an extension.

http://code.google.com/p/chrome-type-ahead/

## Blynx ##

Blynx is a functional statically-typed language that transcompiles to Javascript. State: in development (alpha ~ Jan/2013)

https://github.com/tokland/blynx

# Python #

## LangBots ##

LangBots is a framework to make programmable bots fight in a battlefield. The framework itself is written in Python and Pygame, but participants may implement their bots in the programming language they like.

http://code.google.com/p/langbots/

## PySheng ##

PySheng downloads a book from Google Books and saves the PNG images for each page (and a unique PDF). It can be run either from the command-line or using a simple graphical interface. It should work out-of-the box for Unix systems (GNU/Linux, BSD) and (with minor modifications) for Windows.

http://code.google.com/p/pysheng

## Youtube-upload ##

Upload videos to [Youtube](http://youtube.com) from the command-line (splitting the video if necessary):

http://code.google.com/p/youtube-upload

## Spynner ##

Programmatic web browser module for Python with Javascript/AJAX support based upon the QtWebKit framework.

http://code.google.com/p/spynner/

## Simple subtitles Python library ##

Currently this module only scales (adjusts fps timing) for SRT subtitles. Useful for those subtitles that do not sync with video due to different frames-per-second. For example, to convert a 23.976fps subtitle to a 25fps video:

```
$ python subtitles.py 25/23.976 file.srt
```

http://code.google.com/p/tokland/source/browse/trunk/subtitles


## Sudoku solver ##

Yet another brute-force sudoku solver, but written following Functional Programming paradigm:

http://code.google.com/p/tokland/source/browse/#svn/trunk/sudoku

## Hotkeys for the X-Window ##

Xhotkeys provides a simple and easily configurable hotkey launcher for the X-Window System, binding keys and mouse buttons to configurable commands. It should work on all desktops (Gnome, KDE, ...) available for the GNU/Linux operating system. Configuration files can be modified manually or using a graphical GTK+ configurator.

http://xhotkeys.googlecode.com

## Asterisk Phonepatch ##

The term _phonepatch_ usually refers to the hardware device used to connect a radio transceiver and a phoneline. Asterisk-phonepatch do that task, but it's mainly software, as it uses the Asterisk software PBX.

http://www.nongnu.org/asterisk-phpatch

## RPN calculator ##

A Python command-line interactive [Reverse Polish notation](http://en.wikipedia.org/wiki/Reverse_Polish_notation) calculator:

http://tokland.googlecode.com/svn/trunk/rpn/rpn.py

## Extract audio from a CD ##

Extract/rip audio tracks from a CD (people used to do that, before the P2P era) with song titles obtained from [Gracenote](http://www.gracenote.com) (formerly CDDB).

http://tokland.googlecode.com/svn/trunk/cd2ogg/cd2ogg.py

## Automatic SSH backlinks ##

The SSH protocol is very useful to create secure port-forwarding between computers. If you need permanent SSH links (typically with some forwarded ports), sshlink may be useful to you.

http://www.nongnu.org/sshlink/

## Simple math game solver ##

Given a bunch of numbers, and using the four basic operations (add, subtract, multiply, divide), find -or be as close as possible to- another given number. Spanish readers will recall it from the popular _Cifras y Letras_ TV quiz show.

http://tokland.googlecode.com/svn/trunk/cifras/cifras.py

```
$ python cifras.py 3 7 10 50 100 8 546 
546 = ((((50+7)*8)-10)+100)
```

Also, a Haskell implementation:

http://tokland.googlecode.com/svn/trunk/cifras/cifras.hs

## Pyeuler Project ##

The [Euler Project](http://www.projecteuler.org) proposes some mathematical problems to be solved using any programming language. In this wiki, we see and discuss solutions using Python and functional programming. Python is not a functional-language, but it was interesting anyhow:

http://pyeuler.wikidot.com

http://github.com/tokland/pyeuler

## Uya Wifi router web interface ##

OSPF Router Configurator with a web interface developed with CherryPy.

http://code.google.com/p/uya/

## UTM converter ##

Python module to convert UTM to/from Latitude-Longitude coordinates.

http://tokland.googlecode.com/svn/trunk/utm/utm.py

## Colorize regular expressions in files ##

Simple script to Detect and colorize regular expressions in files or standard input:

http://code.google.com/p/tokland/source/browse/trunk/colorize/colorize.py

## Python FAQ ##

I mantain the official FAQ page for [Python-es](http://listas.aditel.org/listinfo/python-es) mailing list.

http://python-es-faq.wikidot.com/

# Ruby #

## Yaml2csv ##

Transform YAML file into CSV and backwards (useful for I18n translations).

http://github.com/tokland/yaml2csv

# Shell #

## File-sharing downloader/uploader ##

Bash command-line downloader and uploader for some of the most popular file sharing websites. It works on UNIX-like systems and currently supports Megaupload, Rapidshare, 2Shared, 4Shared, ZShare, Badongo and Mediafire:

http://code.google.com/p/plowshare/

## Megaupload downloader (free-download only) ##

Standalone script to download from Megaupload (no account required).

http://code.google.com/p/tokland/wiki/MegauploadDownloader

## Loop over a command ##

This seems to be a hole in the otherwise extremely complete UNIX toolset: a command to loop over commands until they succeed. This is a simple Bash implementation of the tool:

http://code.google.com/p/tokland/source/browse/trunk/tools/loop.sh

Very useful to make sure that calls to network-tools (rsync, wget, ...) really succeed.

## Download from Google Books ##

Downloads a book (that's it, all the images) of a book in Google Books.

http://tokland.googlecode.com/svn/trunk/google-books/download_google_book.sh

## Bootstrap an Arch Linux ##

Bootstrap a base Arch Linux system where you can chroot to.

https://github.com/tokland/arch-bootstrap

## Convert anything to MP3 ##

Well, convert anything-that-mplayer-can-play to mp3.

http://tokland.googlecode.com/svn/trunk/mp3/mplayer2mp3

## Download BBC radio episodes ##

Download radio episodes (they use Adobe Flash) from the BBC website.

http://tokland.googlecode.com/svn/trunk/bbc/download_episode.sh

## English pronunciation ##

Play English words (and cache them) using [The Free Dictionary](http://www.thefreedictionary.com/) webpage.

http://tokland.googlecode.com/svn/trunk/pronounciation/pronounce.sh

## Convert FLAC+CUE or APE+CUE to FLAC ##

Use this simple shell script to convert and split a unique, big APE or FLAC audio file
to many [FLAC](http://en.wikipedia.org/wiki/Free_Lossless_Audio_Codec) files (the CUE file needed).

http://tokland.googlecode.com/svn/trunk/flac/ape2flac

# Websites #

## BicingInfo ##

An email & SMS alarms Rails website for [Bicing Barcelona](http://www.bicing.com/).

The Ruby module used to get Bicing Barcelona occupations is hosted in github:

http://github.com/tokland/bicingbcn

```
$ gem sources -a http://gems.github.com # (you only have to do this once)
$ sudo gem install tokland-bicingbcn
```

# Miscellaneous #

## Archlinux AUR ##

My packages at the Archlinux User Repository:

http://aur.archlinux.org/packages.php?SeB=m&K=tokland

## RAE Spanish dictionary ##

Download and process [DRAE](http://buscon.rae.es/draeI/) contents.

Words list and definitions (HTML, SQL and Dictd files).

(Spanish page) http://code.google.com/p/tokland/wiki/DiccionarioRAE

## My 2-cents in social programming sites ##

http://stackoverflow.com/users/188031

http://snippets.dzone.com/user/tokland

http://gist.github.com/tokland

http://code.activestate.com/recipes/users/4173270/

http://www.commandlinefu.com/commands/by/tokland