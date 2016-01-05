Shell Scripts
============

Author: Arno0x0x - [@Arno0x0x](http://twitter.com/Arno0x0x)

This repository aims at publishing some of my Unix, mainly Linux, shell scripts.

portRedirector.sh
----------------
This script offers a menu driven interface to list, setup and delete some local port redirections using the iptables PREROUTING chain. As such it is essentially a nice wrapper to the command line interface.
A smart usage of this script is to call it from [TermGate](https://github.com/Arno0x/TermGate) by adding it as a interactive command.
The nice thing about it is because TermGate, along with Gotty, offers a persistent connection through the use of a websocket interface, this script can even be used to temporarily redirect the web server port to another local port (*say SSH for instance*) while not loosing the connection to the portRedirector script.

letsNcryptCertRenewNginx.sh
----------------
This script automates the renewal of [LetsEncrypt](https://letsencrypt.org/) SSL certificates in an Nginx environment which is not (*yet*) fully supported by LetsEncrypt. In addition, though optionnal, the script generates proper nginx configuration line for new HPKP headers following certificates renewal. It can be executed as a daily cron task. The script first checks the validity of current certificates and if they're about to expire (as a number of days before expiry date) then the whole process of renewing them is launched.
A notification e-mail is sent whatever happens (*success or failure*) along with all information regarding the execution of the script.

The script automates the following process:
  1. Perform various sanity checks
  2. Check current certificates' expiry date. If they are about to expire, as defined in number of days before expiration in the GLOBAL SETTINGS section, then:
    3. Stop Nginx, but only if the config file syntax is correct (*to prevent impossibility of restart*)
    4. Call *letsencrypt-auto* with proper parameters and config file for automatically renewing certificates
    5. Check renewed certificates expiry date
    6. [**Optionnal**] Compute new HPKP headers and generate proper nginx config line
    7. Restart Nginx
    8. Send notification e-mail with all useful information (status and expiry date of new certificates)

**The 'GLOBAL SETTINGS' section at beginning of the script MUST be edited with you own settings.**

![bitcoin](https://dl.dropboxusercontent.com/s/imckco5cg0llfla/bitcoin-icon.png?dl=0) Like these tools ? Tip me with bitcoins !
![address](https://dl.dropboxusercontent.com/s/9bd5p45xmqz72vw/bc_tipping_address.png?dl=0)