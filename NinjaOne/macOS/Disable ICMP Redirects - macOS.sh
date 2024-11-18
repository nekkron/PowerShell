#!/usr/bin/env bash

# Description: Enable or Disable ICMP Redirects on the system.
#
# Release Notes: Initial Release
#
# Usage: [-enable|-disable]
#
# Preset Parameter: --enable
#		Enable ICMP Redirects on the system.
#
# Preset Parameter: --disable
#		Disable ICMP Redirects on the system.
#
# Preset Parameter: --help
#		Displays this help menu.

_arg_enable="off"
_arg_disable="off"

die() {
    local _ret="${2:-1}"
    echo "$1" >&2
    exit "${_ret}"
}

# Function to print the help message
print_help() {
    printf '\n\n%s\n\n' 'Usage: [--enable|-e] [--disable|-d] [--help|-h]'
    printf '%s\n' 'Preset Parameter: --enable'
    printf '\t%s\n' "Enable ICMP Redirects on the system."
    printf '%s\n' 'Preset Parameter: --disable'
    printf '\t%s\n' "Disable ICMP Redirects on the system."
    printf '%s\n' 'Preset Parameter: --help'
    printf '\t%s\n' "Displays this help menu."
}

# read command line arguments
while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --enable | -e)
        _arg_enable="on"
        ;;
    --disable | -d)
        _arg_disable="on"
        ;;
    --help | -h)
        print_help
        exit 0
        ;;
    *)
        die "FATAL ERROR: Got an unexpected argument '$1'" 1
        ;;
    esac
    shift
done

if [[ "${action}" == "Enable" ]]; then
    # Enable ICMP Redirects
    _arg_enable="on"
    _arg_disable="off"
elif [[ "${action}" == "Disable" ]]; then
    # Disable ICMP Redirects
    _arg_enable="off"
    _arg_disable="on"
else
    # Default to enable
    _arg_enable="on"
    _arg_disable="off"
fi

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    die "[Error] This script must be run as root." 1
fi

_redirectsv4=$(sysctl net.inet.ip.redirect | awk '{print $2}')
_redirectsv6=$(sysctl net.inet6.ip6.redirect | awk '{print $2}')

# Check if ICMP Redirects are already enabled or disabled
if ((_redirectsv4 == 1)) && ((_redirectsv6 == 1)) && [[ $_arg_enable == "on" ]]; then
    echo "[Info] ICMP IPv4 Redirects already enabled."
    echo "[Info] ICMP IPv6 Redirects already enabled."
    exit 0
elif ((_redirectsv4 == 0)) && ((_redirectsv6 == 0)) && [[ $_arg_disable == "on" ]]; then
    echo "[Info] ICMP IPv4 Redirects already disabled."
    echo "[Info] ICMP IPv6 Redirects already disabled."
    exit 0
fi

# Enable ICMP Redirects
if [[ $_arg_enable == "on" ]]; then
    if ! sysctl net.inet.ip.redirect=1; then
        echo "[Error] Failed to enable ICMP IPv4 Redirects."
        exit 1
    fi
    echo "[Info] ICMP IPv4 Redirects enabled."
    if ! sysctl net.inet6.ip6.redirect=1; then
        echo "[Error] Failed to enable ICMP IPv6 Redirects."
        exit 1
    fi
    echo "[Info] ICMP IPv6 Redirects enabled."
# Disable ICMP Redirects
elif [[ $_arg_disable == "on" ]]; then
    if ! sysctl net.inet.ip.redirect=0; then
        echo "[Error] Failed to disable ICMP IPv4 Redirects."
        exit 1
    fi
    echo "[Info] ICMP IPv4 Redirects disabled."
    if ! sysctl net.inet6.ip6.redirect=0; then
        echo "[Error] Failed to disable ICMP IPv6 Redirects."
        exit 1
    fi
    echo "[Info] ICMP IPv6 Redirects disabled."
elif [[ "${_arg_enable}" == "off" ]] && [[ "${_arg_disable}" == "off" ]]; then
    echo "[Error] No action was given. Please specify either Enable or Disable."
    exit 1
fi




