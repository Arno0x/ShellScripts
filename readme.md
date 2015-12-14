Shell Scripts
============

Author: Arno0x0x - [@Arno0x0x](http://twitter.com/Arno0x0x)

This repository aims at publishing some of my Unix, mainly Linux, shell scripts.

portRedirector.sh
----------------
This script offers a menu driven interface to list, setup and delete some local port redirections using the iptables PREROUTING chain. As such it is essentially a nice wrapper to the command line interface.
A smart usage of this script is to call it from [TermGate](https://github.com/Arno0x/TermGate) by adding it as a interactive command.
The nice thing about it is because TermGate, along with Gotty, offers a persistent connection through the use of a websocket interface, this script can even be used to temporarily redirect the web server port to another local port (say SSH for instance) while not loosing the connection to the portRedirector script.