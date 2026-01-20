#!/bin/bash
# adbfind - Scan a given device (or localhost) for any open ports in the ADB range, then try connecting if any are found.
# Written by TDGalea - Version 1 (26-01-20) | https://github.com/TDGalea/adbfind

function failedToFind {
	printf "Failed to find ADB. Check that wireless debugging is enabled.\n" >&2
	printf "If it is, and the port is outside the 30000-50000 range, please let me know.\n\n" >&2
	printf "Please note this script is not for PAIRING ADB - you must already be paired with the target device.\n" >&2
	exit 1
}

function success {
	printf "Connected via port $port.\n"
	exit 0
}

# Do we have nmap?
if ! hash nmap >/dev/null 2>&1; then
	printf "Missing dependency: nmap\nPlease install.\n" >&2
	exit 10
fi

# If no IP passed, assume localhost.
[[ -z $1 ]] && printf "No host specified. Assuming localhost.\n" >&2 && target="127.0.0.1" || target="$1"

# Check the target can be pinged.
if ! ping -c1 -w1 $target >/dev/null 2>&1; then
	printf "Cannot ping target.\n" >&2
	exit 2
fi


# Try to find the port.
printf "Scanning for port. This may take a moment.\n"
portList=$(nmap -Pn $target -p30000-50000 | awk "/\/tcp/" | cut -d/ -f1)
[[ "$portList" == "" ]] && failedToFind
# Fire-up the ADB server if it isn't running already.
adb start-server

for port in $portList; do
	printf "Trying port $port"
	timeout 1 adb connect $target:$port >/dev/null 2>&1 \
		&& printf " - Success.\n" && success \
		|| printf " - Failed.\n" && adb disconnect $target:$port >/dev/null 2>&1
done

printf "And you may ask yourself: 'Well, how did we get here?'\n" >&2
exit 255
