#!/bin/bash
# Author: Arno0x0x - https://twitter.com/arno0x0x
# Description: This scripts automates the renewal of SSL certificates obtained from LetsEncrypt
# in a nginx web server environment.
# LetsEncrypt does NOT (yet) support nginx as a production server, allowing the domain validation
# without stopping the production server.
# This script can be called from a cron job and automates the following process:
# 1. Stop the nginx server (only if its config file's syntax is correct)
# 2. Renew the certificates from LetsEncrypt in a 'certonly' mode, using the LetsEncrypt embed web server for domain validation
# 3. [OPTIONNAL] Compute the HPKP nginx headers for the renewed certificates
# 4. Restart nginx
#
# This script must be run with elevated privileges (sudo or equivalent)

#-----------------------------------------------------
# GLOBAL SETTINGS
#-----------------------------------------------------
domainName="yourdomain.example.com"

# Path to openssl binary
openssl="/usr/bin/openssl"

#----------------------------------------
# -- Nginx settings
# Path to nginx binary
nginx="/usr/sbin/nginx"
# Commands to start & stop nginx. Unix flavor dependent.
nginxStart="service nginx start"
nginxStop="service nginx stop"

#----------------------------------------
# -- LetsEncrypt settings
# Path to letsencrypt-auto utility
letsEncryptAuto="/path/to/letsencrypt/letsencrypt-auto"

# Path to the certificate file that should/will be renewed
declare -a certPath=("/etc/letsencrypt/live/${domainName}/cert.pem" "/etc/letsencrypt/live/${domainName}/fullchain.pem")

#----------------------------------------
# -- [OPTIONNAL] HPKP settings
# Set to false if you don't need HPKP headers
hpkp="true"
hpkpMaxAge="10"
# Array containing paths to all certificates to include in HPKP header
declare -a hpkpCertPath=("/etc/letsencrypt/live/${domainName}/cert.pem" "/etc/letsencrypt/live/${domainName}/chain.pem")
# Path to the file holding the nginx HPKP headers
# This file must be included in the nginx config file
nginxHPKPConfig="/etc/nginx/ssl/${domainName}.hpkp"

#----------------------------------------
# E-mail settings
# Notification e-mail
destEmail="myemailadresse@mydomain.com"
fromEmail="sslRenewal@mydomain.com"

#-----------------------------------------------------
# EMAIL NOTIFICATION FUNCTION
#-----------------------------------------------------
sendNotificationEmail() {
	if [[ "$error" != "" ]]; then
		subject="ERROR during SSL certificates renewal for domain ${domainName}"
		echo -e "${message}${error}" | mail -r ${fromEmail} -s "${subject}" ${destEmail}
		#echo -e "${message}${error}"
		exit 1
	else
		subject="SUCCESS renewing SSL certificates for domain ${domainName}"
		echo -e "${message}${error}" | mail -r ${fromEmail} -s "${subject}" ${destEmail}
		#echo -e "${message}${error}"
	fi
}

#-----------------------------------------------------
# PERFORM VARIOUS CHECKS
#-----------------------------------------------------
message="$0 starting...\n"
[[ -x ${openssl} ]] \
	&& message=$message"[OK] [${openssl}] found and executable.\n" \
	|| error="[ERROR] [${openssl}] not found or not executable.\n" 

[[ -x ${letsEncryptAuto} ]] \
	&& message=$message"[OK] [${letsEncryptAuto}] found and executable.\n" \
	|| error=$error"[ERROR] [${letsEncryptAuto}] not found or not executable.\n"

[[ -x ${nginx} ]] \
	&& message=$message"[OK] [${nginx}] found and executable.\n" \
	|| error=$error"[ERROR] [${nginx}] not found or not executable.\n"

# Check nginx configuration file
${nginx} -t -q
[[ $? -eq 0 ]] \
	&& message=$message"[OK] nginx config file syntax is correct.\n" \
	|| error=$error"[ERROR] nginx config file syntax not correct. Nginx would not restart if it's being stopped now.\n"

# At this stage, check for any errors
if [[ $error != "" ]]; then
	sendNotificationEmail
fi

#-----------------------------------------------------
# GOOD TO GO
#-----------------------------------------------------

#----------------------------
# Stop nginx web server
${nginxStop} 2>&1 > /dev/null

if [[ $? -eq 0 ]]; then
	# Check nginx has been effectively stopped
	ps -e | grep nginx > /dev/null
	if [[ $? -eq 0 ]]; then
		error=$error"[ERROR] nginx web server is still running despite command [${nginxStop}] was executed.\n"
		sendNotificationEmail
	else
		message=$message"[OK] nginx web server successfully stopped.\n"
	fi
else
	error=$error"[ERROR] nginx web server could not be stopped with command [${nginxStop}].\n"
	sendNotificationEmail
fi

#------------------------------------------------
# Launch LetsEncrypt utility to renew certificates
${letsEncryptAuto} certonly --standalone --renew-by-default -d ${domainName} 2>&1 > /dev/null

if [[ $? -ne 0 ]]; then
	error=$error"[ERROR] [${letsEncryptAuto}] did not complete properly. Run it manually to debug.\n"
	sendNotificationEmail
fi
message=$message"[OK] [${letsEncryptAuto}] successfully executed.\n"

#-------------------------------------------
# Check new certificates have been generated
for cert in "${certPath[@]}"; do
	# Get the certificate start date and convert it to YearMonthDay format
	certStartDate=$(${openssl} x509 -noout -in $cert -dates | awk -F'=' '/^notBefore/ {print $2}')
	certEndDate=$(${openssl} x509 -noout -in $cert -dates | awk -F'=' '/^notAfter/ {print $2}')
	from=$(date -d"${certStartDate}" +%Y%m%d)

	# Get the current date in YearMonthDay format
	now=$(date +%Y%m%d)

	# If the certificates start date is now, then the certificate has been properly renewed
	if [[ "$from" == "$now" ]]; then
		message=$message"[OK] [${cert}] has properly been renewed and is valid from [${certStartDate}] until [${certEndDate}].\n"
	else
		error=$error"[ERROR] [${cert}] has not been newed.\n"
		sendNotificationEmail
	fi
done

#-------------------------------------------
# [OPTIONNAL] Update nginx HPKP headers
if [[ "$hpkp" == "true" ]]; then
	header=""
	# Compute each certificate's SHA256 hash
	for cert in "${hpkpCertPath[@]}"; do
		certHash=$(${openssl} x509 -in ${cert} -pubkey -noout | openssl rsa -pubin -outform der 2> /dev/null | openssl dgst -sha256 -binary | base64)
		header=$header"pin-sha256=\"${certHash}\"; "
	done

	# Certificates AES256 fingerprint have now been computed, create the HPKP headers
	echo "add_header Public-Key-Pins '${header}max-age=${hpkpMaxAge};';" > ${nginxHPKPConfig}
fi

#-------------------------------------------
# Restart nginx web server
${nginxStart} 2>&1 > /dev/null

if [[ $? -eq 0 ]]; then
	# Check nginx has been effectively started
	ps -e | grep nginx > /dev/null
	if [[ $? -eq 0 ]]; then
		message=$message"[OK] nginx web server successfully started.\n"
	else
		error=$error"[ERROR] nginx web did not properly started despite command [${nginxStart}] was executed.\n"
		sendNotificationEmail
	fi
else
	error=$error"[ERROR] nginx web server could not be started with command [${nginxStart}].\n"
	sendNotificationEmail
fi

#-------------------------------------------
# ALL DONE - Send the notification e-mail
sendNotificationEmail
