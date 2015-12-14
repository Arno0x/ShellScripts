#!/bin/bash
# Author : Arno0x0x - https://twitter.com/Arno0x0x
#
# This script allows setting up a port redirection for a specified source IP
# through the use of an interactive menu using iptables and the PREROUTING chain
#
# As a result, any connection from the specified IP on a given destination port gets
# redirected to another port:
# (Source_IP) ---> (Destination Port) --- redirected to --> (Redirected Port)

#-----------------------------------------------------
# Set up constants and default values
NC="\e[0m"
RED="\e[0;31m"
GREEN="\e[0;32m"
BLUE="\e[0;34m"
BOLD="\e[1m"
IPTABLES='/sbin/iptables'
PROTOCOL='tcp'
DESTPORT='443'
TOPORT='22'

#-----------------------------------------------------
# Perform some basic checks beforehands
if [[ ! -x ${IPTABLES} ]]; then
	echo "${IPTABLES} not found OR is not executable"
	exit 1
fi

#-----------------------------------------------------
# This function counts the number of port redirection
function countRedirection {
	local count=$(sudo ${IPTABLES} -n -t nat -L PREROUTING --line-number | tail -n+3 | wc -l)
	echo $count
}

#-----------------------------------------------------
# This function lists the existing port redirection
function listRedirection {
	if [[ $(countRedirection) -eq 0 ]]; then
		echo "------ No redirection defined"
	else
		echo "------ Existing port redirection:"
		sudo ${IPTABLES} -n -t nat -L PREROUTING --line-number | tail -n+3
	fi
}

#-----------------------------------------------------
# This function deletes an existing port redirection
function deleteRedirection {
	if [[ $(countRedirection) -eq 0 ]]; then
		echo "------- No redirection defined"
	else
		echo "------- Existing port redirection(s):"
		sudo ${IPTABLES} -n -t nat -L PREROUTING --line-number | tail -n+3
		echo -ne "${BLUE}[DELETE REDIRECTION]> Enter rule number to delete: ${NC}"
		read ruleNumber
		sudo ${IPTABLES} -t nat -D PREROUTING $ruleNumber
	fi
}

#-----------------------------------------------------
# This function adds a new port redirection
function addRedirection {
	echo "----- Add a new port redirection"

	echo -ne "${BLUE}[ADD REDIRECTION]> Enter source IP: ${NC}"
	read input
	if [[ $input =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
		SOURCEIP=$input
	else
		echo -e "[${RED}ERROR${NC}] Invalid IP address"
		return 1
	fi
	echo -e "[${GREEN}OK${NC}] Source IP set to $SOURCEIP"

	echo -ne "${BLUE}[ADD REDIRECTION]> Enter protocol, tcp/udp (default: $PROTOCOL): ${NC}"
	read input
	if [[ "$input" != "" ]]; then
		if [[ $input =~ ^(tcp|udp)$ ]]; then
			PROTOCOL=$input
		else
			echo -e "[${RED}ERROR${NC}] Invalid protocol"
			return 1
		fi
	fi
	echo -e "[${GREEN}OK${NC}] Protocol set to $PROTOCOL"

	echo -ne "${BLUE}[ADD REDIRECTION]> Enter destination port (default: $DESTPORT): ${NC}"
	read input
	if [[ "$input" != "" ]]; then
		if [[ $input =~ ^[0-9]+$ && $input -lt 65635 ]]; then
			DESTPORT=$input
		else
			echo -e "[${RED}ERROR${NC}] Invalid port number"
			return 1
		fi
	fi
	echo -e "[${GREEN}OK${NC}] Destination port set to $DESTPORT"

	echo -ne "${BLUE}[ADD REDIRECTION]> Enter redirected port (default: $TOPORT): ${NC}"
	read input
	if [[ "$input" != "" ]]; then
		if [[ "$input" =~ ^[0-9]+$ && $input -lt 65635 ]]; then
			TOPORT=$input
		else
			echo -e "[${RED}ERROR${NC}] Invalid port number"
			return 1
		fi
	fi
	echo -e "[${GREEN}OK${NC}] Redirection port set to $TOPORT"

	# Perform the actual redirection
	sudo ${IPTABLES} -t nat -A PREROUTING -s ${SOURCEIP}/32 -p ${PROTOCOL} --dport ${DESTPORT} -j REDIRECT --to-port ${TOPORT}

	[[ $? -eq 0 ]] && echo -e "[${GREEN}OK${NC}] Redirection completed" || echo -e "[${RED}ERROR${NC}] Could not complete redirection"
}

#-----------------------------------------------------
# MAIN
#-----------------------------------------------------
echo -e ${GREEN}${BOLD}
echo "#####################################################"
echo "#                   PORT REDIRECTOR                 #"
echo "#####################################################"
echo -e ${NC}
while :
do
	echo "> Commands available: (l)ist / (a)dd / (d)elete / (q)uit"
	echo -ne "${BLUE}> Enter command: ${NC}"
	read userCommand
	case $userCommand in
		l|L)
			listRedirection
		;;
		a|A)
			addRedirection
		;;

		d|D)
			deleteRedirection
		;;

		q|Q)
			exit
		;;

		*)
			echo -e "[${RED}ERROR${NC}] Unknown command"
		;;
	esac
done
