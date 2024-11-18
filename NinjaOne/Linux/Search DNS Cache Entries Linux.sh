#!/usr/bin/env bash

# Description: Find DNS Cache entries on a Linux system. Supports systemd-resolved and dnsmasq(requires log-facility to be configured).
#
# Servers usually do not have a DNS cache service installed by default.
# systemd-resolved is commonly installed along with most Desktop Environments, such as GNOME and KDE.
#
# Release Notes: Initial Release

# A comma separated list of keywords to search for in the DNS cache. Example: "google,comcast,cloudflare"
keywords_to_search=$1
# A multiline custom field to save the DNS cache entries.
multiline_custom_field=$2

# Check if the multilineCustomField is set
if [[ -n "${multilineCustomField}" && "${multilineCustomField}" != "null" ]]; then
    multiline_custom_field=$multilineCustomField
fi

# Check if the keywordsToSearch is set
if [[ -n "${keywordsToSearch}" && "${keywordsToSearch}" != "null" ]]; then
    keywords_to_search=$keywordsToSearch
fi

# Check if the keywords_to_search is set
if [[ -z "${keywords_to_search}" ]]; then
    echo "[Info] keywords_to_search is not set."
    exit 1
else
    # Split the keywords_to_search into an array
    OLDIFS=$IFS
    IFS=',' read -r -a keywords <<<"${keywords_to_search}"
    IFS=$OLDIFS
    # Trim trailing and leading whitespace from each keyword
    keywords=("${keywords[@]/ /}")

fi

# Check if the multiline_custom_field is set
if [[ -z "${multiline_custom_field}" ]]; then
    echo "[Info] multilineCustomField is not set."
fi

# Check if ninjarmm-cli command exists in the default path
ninjarmm_cli="/opt/NinjaRMMAgent/programdata/ninjarmm-cli"
if [[ -z $ninjarmm_cli ]]; then
    echo "[Error] The ninjarmm-cli command does not exist in the default path. Please ensure the NinjaRMM agent is installed before running this script."
    exit 1
else
    # ninjarmm-cli command exists in the default path
    echo -n
fi

# Check that we are running as root
if [[ $EUID -ne 0 ]]; then
    echo "[Error] This script must be run as root."
    exit 1
fi

# Check for which dns cache service is installed
if [ "$(command -v resolvectl)" ]; then
    # resolvectl is installed
    dns_cache_service="resolvectl"
elif [ "$(command -v dnsmasq)" ]; then
    # dnsmasq is installed
    dns_cache_service="dnsmasq"
else
    # no dns cache service is installed
    echo "[Error] No DNS cache service is installed on this system that this script supports."
    echo ""
    echo "[Info] Supported DNS cache services: systemd-resolved, dnsmasq"
    echo "[Info] systemd-resolved commonly installed along with a Desktop Environment."
    echo "[Info] Servers usually do not have a DNS cache service installed by default."
    echo ""
    echo "[Info] Installing a DNS cache is not recommended on servers."
    exit 1
fi

# Check if the dns_cache_service is resolvectl
if [[ "${dns_cache_service}" == "resolvectl" ]]; then
    systemdVersion=$(systemctl --version | head -1 | awk '{ print $2}')
    if [ "$systemdVersion" -lt 254 ]; then
        echo "[Error] The version of systemd is less than 254. The resolvectl show-cache command is not available. Currently system version is ${systemdVersion}."
        exit 1
    fi
    # Get the DNS cache entries from resolvectl
    # https://github.com/systemd/systemd/pull/28012
    if ! dns_cache=$(resolvectl show-cache 2>/dev/null); then
        # Check if the systemd-resolved service is active
        if [[ $(systemctl is-active systemd-resolved) != "active" ]]; then
            echo "[Warn] The systemd-resolved service is not active."
        # Check /etc/resolv.conf that the nameserver is set to the default IP address 127.0.0.53 for systemd-resolved to work
        elif ! grep -q "^nameserver 127.0.0.53" /etc/resolv.conf; then
            echo "[Warn] The nameserver in /etc/resolv.conf is not set to an IP address 127.0.0.53 ."
            echo "[Info] The nameserver in /etc/resolv.conf should be set to an IP address 127.0.0.53 for systemd-resolved to work."
        else
            echo "[Warn] Failed to get the DNS cache entries. Is systemd-resolved installed, configured, and running?"
        fi
        echo ""
        echo "[Info] Supported DNS cache services: systemd-resolved, dnsmasq"
        echo "[Info] systemd-resolved commonly installed along with a Desktop Environment."
        echo "[Info] Servers usually do not have a DNS cache service installed by default."
        echo ""
        echo "[Info] Installing a DNS cache is not recommended on servers."
        exit 0
    fi

    dns_cache_entries=""
    # Get the DNS cache entries from resolvectl based on the keywords provided
    for keyword in "${keywords[@]}"; do
        # Example DNS cache entry:
        # consto.com IN A 123.123.123.123
        # consto.com IN AAAA 2001:0db8:85a3:0000:0000:8a2e:0370:7334
        dns_cache_entries+="DNS Cache Records Matching: ${keyword}"
        dns_cache_entries+=$'\n' # newline
        dns_cache_entries+=$(echo "$dns_cache" | grep -i -E "${keyword}")
        dns_cache_entries+=$'\n' # newline
    done
    # Print the DNS cache entries
    echo "" # newline
    echo "$dns_cache_entries"
# Check if the dns_cache_service is dnsmasq
elif [[ "${dns_cache_service}" == "dnsmasq" ]]; then
    if [ -f "/etc/dnsmasq.conf" ]; then
        echo "[Info] dnsmasq configuration file exists."
    else
        echo "[Warn] The dnsmasq configuration file does not exist and is likely not installed or configured."
        echo ""
        echo "[Info] Supported DNS cache services: systemd-resolved, dnsmasq"
        echo "[Info] systemd-resolved commonly installed along with a Desktop Environment."
        echo "[Info] Servers usually do not have a DNS cache service installed by default."
        echo ""
        echo "[Info] Installing a DNS cache is not recommended on servers."
        exit 0
    fi
    # Check that log-queries is enabled in the dnsmasq configuration file
    if ! grep -q "log-queries" /etc/dnsmasq.conf; then
        echo "[Warn] The 'log-queries' option is not enabled in the dnsmasq configuration file."
        echo ""
        echo "[Info] Supported DNS cache services: systemd-resolved, dnsmasq"
        echo "[Info] systemd-resolved commonly installed along with a Desktop Environment."
        echo "[Info] Servers usually do not have a DNS cache service installed by default."
        echo ""
        echo "[Info] Installing a DNS cache is not recommended on servers."
        exit 0
    fi
    # Get the log-facility from the dnsmasq configuration file
    log_facility=$(grep -E "^log-facility" /etc/dnsmasq.conf | awk '{print $2}')
    if [[ -z "${log_facility}" ]]; then
        echo "[Warn] The 'log-facility' option is not set in the dnsmasq configuration file."
        echo ""
        echo "[Info] Supported DNS cache services: systemd-resolved, dnsmasq"
        echo "[Info] systemd-resolved commonly installed along with a Desktop Environment."
        echo "[Info] Servers usually do not have a DNS cache service installed by default."
        echo ""
        echo "[Info] Installing a DNS cache is not recommended on servers."
        exit 0
    fi
    # Check that log_facility is a valid file
    if [[ ! -f "${log_facility}" ]]; then
        echo "[Error] The log facility file '${log_facility}' does not exist."
        echo ""
        echo "[Info] Supported DNS cache services: systemd-resolved, dnsmasq"
        echo "[Info] systemd-resolved commonly installed along with a Desktop Environment."
        echo "[Info] Servers usually do not have a DNS cache service installed by default."
        echo ""
        echo "[Info] Installing a DNS cache is not recommended on servers."
        exit 1
    fi
    # Get the DNS cache entries from log_facility
    # Example log_facility file:
    # Jan  1 00:00:00 dnsmasq[12345]: query[A] example.com from
    for keyword in "${keywords[@]}"; do
        # Get the DNS cache entries from the log_facility file
        # The awk command parses the log_facility file and extracts the time, query, and host
        if ! dns_cache_entries=$(grep -i -E "${keyword}" "${log_facility}" | awk 'BEGIN {OFS = ",";}$5 == "query[A]" {time = mktime(sprintf("%04d %02d %02d %s\n",strftime("%Y", systime()),(match("JanFebMarAprMayJunJulAugSepOctNovDec",$1)+2)/3,$2,gensub(":", " ", "g", $3)));query = $6;host = $8;print time, host, query;}'); then
            echo "[Error] Failed to get the DNS cache entries."
            echo "$dns_cache_entries"
            echo ""
            echo "[Info] Supported DNS cache services: systemd-resolved, dnsmasq"
            echo "[Info] systemd-resolved commonly installed along with a Desktop Environment."
            echo "[Info] Servers usually do not have a DNS cache service installed by default."
            echo ""
            echo "[Info] Installing a DNS cache is not recommended on servers."
            exit 1
        fi
    done
    echo "$dns_cache_entries"
fi

# Set the multiline_custom_field
if [[ -n "$multiline_custom_field" ]]; then
    if [[ -x "$ninjarmm_cli" ]]; then
        if hideOutput=$(echo "$dns_cache_entries" | "$ninjarmm_cli" set --stdin "$multiline_custom_field" 2>&1); then
            echo "[Info] Successfully set custom field: $multiline_custom_field"
        else
            echo "[Error] Failed to set custom field: $multiline_custom_field. Custom Field does not exist or does not have write permissions."
            exit 1
        fi
    else
        echo "[Error] NinjaRMM CLI not found or not executable"
        exit 1
    fi
fi





