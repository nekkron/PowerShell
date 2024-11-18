#!/usr/bin/env bash
# Description: Checks whether or not firewall is enabled and whether or not it's blocking inbound connections and optionally in stealth mode.
#  Will exit with status code 1 if any of those are not true. It exits with status code 2 for invalid input!
# Release Notes: Updated Calculated Name
#
# Usage: ./Check-FirewallStatusMac.sh [--inboundblocked] [--stealthmode]
# <> are required
# [] are optional
# Example: ./Check-FirewallStatusMac.sh --inboundblocked --stealthmode
#
# Notes:
#
#

function socketfilterfw() {
    /usr/libexec/ApplicationFirewall/socketfilterfw "$@"
}

function defaults() {
    /usr/bin/defaults "$@"
}

# When run directly without testing, the "__()" function does nothing.
test || __() { :; }

__ begin __
if [ $# -eq 0 ]; then
    if [[ "${inboundBlocked}" == "true" ]]; then
        inboundCheck=$(socketfilterfw --getblockall | grep DISABLED)
        if [[ -n $inboundCheck ]]; then
            echo "Inbound traffic is not being blocked by default!"
            failed="True"
        fi
    fi
    if [[ "${stealthMode}" == "true" ]]; then
        stealthCheck=$(socketfilterfw --getstealthmode | grep disabled)
        if [[ -n $stealthCheck ]]; then
            echo "Stealthmode is NOT enabled!"
            failed="True"
        fi
    fi
else
    for i in "$@"; do
        if [[ $i != **"--inboundblocked"** && $i != **"--stealthmode"** && -n $i ]]; then
            echo "[Error] invalid input! Only supports --inboundblocked and --stealthmode" 1>&2
            echo "Exiting with status code 2" 1>&2
            exit 2
        fi

        if [[ $i == *"--inboundblocked"* ]]; then
            inboundCheck=$(socketfilterfw --getblockall | grep DISABLED)
            if [[ -n $inboundCheck ]]; then
                echo "Inbound traffic is not being blocked by default!"
                failed="True"
            fi
        fi

        if [[ $i == *"--stealthmode"* ]]; then
            stealthCheck=$(socketfilterfw --getstealthmode | grep disabled)
            if [[ -n $stealthCheck ]]; then
                echo "Stealthmode is NOT enabled!"
                failed="True"
            fi
        fi
    done
fi

firewallSocket=$(socketfilterfw --getglobalstate | grep disabled)
firewallALF=$(defaults read /Library/Preferences/com.apple.alf globalstate | grep 0)

if [[ -n $firewallSocket || -n $firewallALF ]]; then
    echo "The firewall is currently disabled."
    failed="True"
fi

if [[ $failed == "True" ]]; then
    echo "One or more checks have failed. Exiting with status code 1."
    exit 1
else
    echo "The firewall is enabled and all other checks have passed."
    exit 0
fi

__ end __




