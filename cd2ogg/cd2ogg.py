#!/usr/bin/python
# 2007 Arnau Sanchez
from itertools import izip, count
import os, sys, errno
import CDDB, DiscID
import subprocess
import locale
    
def starmap(fun, it):
    return [fun(*args) for args in it]
       
def enumerate_from(it, start=0):
    return izip(count(start), it)
    
def debug(s):
    sys.stderr.write("--- %s\n" % s)
    sys.stderr.flush()
           
def get_cd_info():
    def check_status(status, success_values): 
        cddb_status_msg = {
          200: "Success",
          211: "Multiple inexact matches were found",
          210: "Multiple exact matches were found",
          202: "No match found",
          403: "Error: database entry is corrupt",
          409: "Error: no handshake. (client-side error?)"
        }
        debug("CDDB status: %d (%s)"%(status, cddb_status_msg[status]))
        if status not in success_values:
            s = ", ".join(success_values)
            debug("CDDB status error: %d (success: %s)" % (status, s))
            return False
        return True
    cdrom = DiscID.open()
    disc_id = DiscID.disc_id(cdrom)
    debug("CDDB: Tracks in CD: %d"%disc_id[1])
    qstatus, qinfo = CDDB.query(disc_id)
    if not check_status(qstatus, (200, 210)):
        tracks = ["track%02d"%n for n in xrange(1, disc_id[1]+1)]
        return "Unknown - Unknown", tracks    
    if isinstance(qinfo, list):
        qinfo = qinfo[0]
    debug("CDDB: CD-ID: %s" % qinfo["disc_id"])
    status, info = CDDB.read(qinfo['category'], qinfo['disc_id'])
    check_status(status, (200, 210))
    year = info.get("DYEAR")
    disc_title = year and "%s (%s)"%(qinfo["title"], year) or qinfo["title"]
    debug("CDDB: Disc title: %s"%disc_title)
    recode = lambda s: s.decode("iso8859-1").encode("utf-8")
    get = lambda num: recode(info['TTITLE%d'%num]).title()
    title = recode(disc_title).title()
    tracks = map(get, range(disc_id[1]))
    return title, tracks
    
def change_directory(directory):
    os.chdir(directory)
    
def create_directory(directory):
    debug("Creating directory: %s"%directory)
    try:
        os.mkdir(directory)
    except OSError, (errno0, msg):
        if errno0 != errno.EEXIST:
            raise
        debug("Directory exists: %s"%directory)
            
def extract_and_encode(ntrack, ogg_file, ogg_quality):
    debug("Extracting and encoding track: %s" % ogg_file)
    print ogg_file
    fd = open(ogg_file, "w")
    try: 
        extract_command = "icedax -q -D /dev/cdrom -t %d -"%ntrack
        encode_command = "oggenc -q%d -"%ogg_quality
        adj = lambda s: s.split()
        p1 = subprocess.Popen(adj(extract_command), stdout=subprocess.PIPE)
        p2 = subprocess.Popen(adj(encode_command), stdin=p1.stdout, stdout=fd)
        retcodes = p1.wait(), p2.wait()
        fd.close()
        return retcodes
    except (OSError, IOError):
        os.unlink(ogg_file)
        raise
    
def process_track(ntrack, track_name, overwrite=False):
    ogg_file = "%s.ogg" % track_name
    if overwrite or not os.path.isfile(ogg_file):
        extract_and_encode(ntrack, ogg_file, ogg_quality=5)
    else: debug("File already exists: %s"%ogg_file)
        
def main(args):
    locale.setlocale(locale.LC_ALL, "")
    title0, tracks0 = get_cd_info()
    adjust = lambda s: s.replace("/", "-")
    title = adjust(title0)
    tracks = map(adjust, tracks0)
    get_track_name = lambda num, name: "%02d.%s"%(num, name)
    track_names = starmap(get_track_name, enumerate_from(tracks, 1))
    create_directory(title)
    change_directory(title)
    starmap(process_track, enumerate_from(track_names, 1))
    return 0
    
if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))