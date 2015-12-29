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
This script automates the renewal of [LetsEncrypt](https://letsencrypt.org/) SSL certificates in an Nginx environment which is not (*yet*) fully supported by LetsEncrypt. In addition, though optionnal, the script generates proper nginx configuration line for new HPKP headers following certificates renewal. This script can be called from a cron task. A notification e-mail is sent whatever happens (*success or failure*) along with all information regarding the execution of the script. The script automates the following process:
  1. Perform various sanity checks
  2. Stop Nginx, only if the config file syntax is correct (*to prevent impossibility of restart*)
  3. Call *letsencrypt-auto* with proper parameters for automatically renew certificates
  4. Check renewed certificates
  5. [**Optionnal**] Compute new HPKP headers and generate proper nginx config line
  6. Restart Nginx
  7. Send notification e-mail

The 'GLOBAL SETTINGS' section at beginning of the script MUST be edited with you own settings.

![bitcoin](https://dl.dropboxusercontent.com/s/imckco5cg0llfla/bitcoin-icon.png?dl=0) Like these tools ? Tip me with bitcoins !
![address](https://dl.dropboxusercontent.com/s/9bd5p45xmqz72vw/bc_tipping_address.png?dl=0)