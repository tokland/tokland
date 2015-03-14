# Introduction #

This document explains how to log into a UNIX-linux system (Debian is used as example) to run X11 applications remotely.

# Server #

You need the basic X11 infrastructure and _xauth_ installed:

```
$ sudo apt-get install x11-common x11-apps xauth
```

X11 forwarding must be enabled (restard the ssh daemon if required):

```
# /etc/ssh/sshd_config
X11Forwarding yes
...

$ sudo /etc/init.d/ssh restart
```

# Client #

```
$ ssh -X user@host
...

$ echo $DISPLAY
localhost:10.0

$ xcalc
```

If you enable the X11 forwarding in the configuration file you can omit _-X_:

```
# /etc/ssh/ssh_config
ForwardX11 yes
```