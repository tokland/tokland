#!/usr/bin/python
"""
Try commonly used pairs user/password to access an ADSL router. The 
password list is created from http://www.phenoelit-us.org/dpl/dpl.html.

- To generate TXT password file (dpl.txt) from last version of HTML source:

wget http://www.phenoelit-us.org/dpl/dpl.html
python dpl.py --generate

- Try user/password list for host 192.168.1.1 (you need dpl.txt):

python dpl.py 192.168.1.1

---

Author: tokland@gmail.com
"""
import re
import sys
import urllib2
import optparse
import BeautifulSoup

def debug(lineinfo):
    """Write a line to standard error"""
    sys.stderr.write("--- " + lineinfo + "\n")
    sys.stderr.flush()
    
def get_soup(data):
    """Return a soup of HTML tags from string data"""
    return BeautifulSoup.BeautifulSoup(data)

def get_info(filename):
    """Yield user/password pairs from dpl htmt list"""
    skip_re = map(re.compile, ["^$", "^n/a$", " ", "^\("])
    debug("reading html source: %s" % filename)
    soup = get_soup(open(filename).read())    
    debug("extracting td tags from HTML soup")
    trtags = soup.findAll("tr")
    get_content = lambda tag: tag.contents and tag.contents[0].strip() or ""
    headers = map(get_content, trtags[0].findAll("td"))
    useridx = headers.index("User ID")
    passwordidx = headers.index("Password")
    seen = set()
    for trtag in trtags[1:]:
        tds = map(get_content, trtag.findAll("td"))
        entry = user, password = (tds[useridx], tds[passwordidx])
        if entry in seen:
            continue
        if any(skre.search(user) or skre.search(password) for skre in skip_re):
            continue
        yield entry
        debug("adding: %s" % repr(entry))
        seen.add(entry)
    debug("done")        

def create_password_file(htmlfile):
    """Create a file of user/password pairs from dpl html list"""
    output = ("%s %s\n" % (u, p) for (u, p) in get_info(htmlfile))
    sys.stdout.writelines(sorted(output))

def try_user(hosturl, username, password):
    """Return True if hosturl can be accessed using a username/password"""  
    password_mgr = urllib2.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, hosturl, username, password)
    handler = urllib2.HTTPBasicAuthHandler(password_mgr)
    opener = urllib2.build_opener(handler)
    debug("trying: %s/%s" % (username, password))
    try:
        opener.open(hosturl).read()
    except urllib2.HTTPError:
        return False
    return True

def connect(host, passfilename):    
    """Try all pairs user/password to access a given host with HTTP
    authentication enabled"""
    if not host.startswith("http://"):
        host = "http://" + host    
    user_passwords = (line.split() for line in open(passfilename))
    for username, password in user_passwords:
        if try_user(host, username, password):
            return username, password
    
def main(args):
    """Main method for dpl"""
    doc = __doc__.split("---")[0].rstrip()
    usage = "usage: dpl.py [options] [host]\n%s" % doc
    parser = optparse.OptionParser(usage)
    parser.add_option('-g', '--generate-password-file', dest='generate',
        action="store_true", default=False, help='Generate password file')
    options, args0 = parser.parse_args(args)
    if options.generate:
        output = ("%s %s\n" % (u, p) for (u, p) in get_info("dpl.html"))
        open("dpl.txt", "w").writelines(sorted(output))
        return 0
    elif len(args0) == 0:
        parser.print_help()
        return 1
    res = connect(args0[0], "dpl.txt")
    if not res:
        return 2
    username, password = res
    print "found: %s/%s" % (username, password)
        
if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
