#!/usr/bin/env bash

# Description: Adds a rule to the ufw firewall.
#
# Release Notes: Initial Release
#
# Usage: [--interface <arg>] [--protocol <arg>] [--port <arg>] [--action <arg>] [--from <arg>] [--help|-h]
#
# Preset Parameter: --rule "ReplaceMeWithRuleName"
#   The name of the rule you would like to add to the firewall.

# Static variables
_space=" " # Space character

die() {
    local _ret="${2:-1}"
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    echo "$1" >&2
    exit "${_ret}"
}

echo_error() {
    echo "$@" 1>&2
}

begins_with_short_option() {
    local first_option all_short_options='iltafh'
    first_option="${1:0:1}"
    test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# Functions "validation::*" are for validating IP addresses
# Source: https://github.com/labbots/bash-utility/blob/master/src/validation.sh
# License: MIT - https://github.com/labbots/bash-utility/blob/master/LICENSE
validation::ipv4() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2
    declare ip="${1}"
    declare IFS=.
    # shellcheck disable=SC2206
    declare -a a=($ip)
    [[ "${ip}" =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 1
    # Test values of quads
    declare quad
    for quad in {0..3}; do
        [[ "${a[$quad]}" -gt 255 ]] && return 1
    done
    return 0
}

validation::ipv6() {
    [[ $# = 0 ]] && printf "%s: Missing arguments\n" "${FUNCNAME[0]}" && return 2

    declare ip="${1}"
    declare re="^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|\
([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|\
([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|\
([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|\
:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|\
::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|\
(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|\
(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$"

    [[ "${ip}" =~ $re ]] && return 0 || return 1
}

are_addresses_valid() {
    # Convert the addresses to an array
    IFS=',' read -r -a addresses <<<"$1"

    for address in "${addresses[@]}"; do
        if validation::ipv4 "$address"; then
            # IPv4 address is valid
            continue
        elif validation::ipv6 "$address"; then
            # IPv6 address is valid
            continue
        else
            # Address is not valid
            echo_error "[Error] Invalid IP address: '$address'."
            return 1
        fi
    done
    # All addresses are valid
    return 0
}

is_port_in_range() {
    local port="${1}"
    # Check if the port range is valid 1-65535
    if ! [[ "${port}" -ge 1 ]] && [[ "${port}" -le 65535 ]]; then
        # Port range is not valid
        echo_error "[Error] Invalid port range: '${port}'."
        return 1
    fi
    return 0
}

are_ports_valid() {
    # Convert the ports to an array
    local port_regex='^[0-9]+$'
    local port_range_regex='^[0-9]+:[0-9]+$'
    IFS=',' read -r -a _ports <<<"$1"

    for port in "${_ports[@]}"; do
        if [[ "${port}" =~ $port_regex ]]; then
            # Port is a single port
            if ! is_port_in_range "${port}"; then
                # Port is not valid
                return 1
            fi
        elif [[ "${port}" =~ $port_range_regex ]]; then
            # Port range format
            # Check if the left and right sides of the range are valid single ports
            local IFS=':'
            read -r left right <<<"${port}"
            if ! is_port_in_range "${left}"; then
                # Port range is not valid
                return 1
            fi
            if ! is_port_in_range "${right}"; then
                # Port range is not valid
                return 1
            fi
        elif ! is_port_in_range "${port}"; then
            # Range of a single port
            # Port is not valid
            return 1
        fi
    done
    # All ports are valid
    return 0
}

is_root() {
    if [[ $EUID -ne 0 ]]; then
        die "[Error] This script must be run as root." 1
    fi
}

build_ufw_params() {
    local _param_action=$1 # Can be allow,deny,reject
    if ! are_ports_valid "$2"; then
        echo_error "[Error] Invalid port found in: '$2'."
        return 1
    fi
    local _param_port=$2 # Can be and empty string or an array
    declare OIFS=$IFS
    declare IFS=','
    read -r -a _param_port <<<"${_param_port}"
    local _param_protocol=$3  # Can only be tcp, udp, both, or any. Both requires double the rules
    local _param_interface=$4 # Can be and empty string or an array
    if ! are_addresses_valid "$5"; then
        echo_error "[Error] Invalid Address found in: '$5'."
        return 1
    fi
    local _param_from=$5 # Can be and empty string or an array
    read -r -a _local_param_from <<<"${_param_from}"
    IFS=$OIFS
    local _param_comment=$6 # Can only be a string

    if [[ -n "${_param_interface}" ]]; then
        _param_interface="in on ${_param_interface}"
    else
        _param_interface=""
    fi

    declare _rules=""
    if [[ -n "${_param_port[*]}" ]]; then
        if [[ "${_param_protocol}" == "Both" ]]; then
            # Add TCP and UDP rules
            # For each port in _param_port
            for _port in "${_param_port[@]}"; do
                if ((_port > 65535)) || ((_port < 1)); then
                    die "[Error] Invalid port range: '${_port}'. Ports must be between 1 and 65535." 1
                fi

                # Check if the from field is empty
                if [[ -z "${_param_from}" ]]; then
                    # Add TCP and UDP rules for any
                    _rules+="${_param_action} ${_param_interface} proto tcp from any port ${_port} ${_param_comment};"
                    _rules+="${_param_action} ${_param_interface} proto udp from any port ${_port} ${_param_comment};"
                else
                    # Add TCP and UDP rules for each IP address
                    # Check if the from field is empty
                    if [[ -z "${_local_param_from[*]}" ]]; then
                        # Add TCP and UDP rules for any
                        _rules+="${_param_action} ${_param_interface} proto tcp from any port ${_port} ${_param_comment};"
                        _rules+="${_param_action} ${_param_interface} proto udp from any port ${_port} ${_param_comment};"
                    else
                        # For each from in _local_param_from
                        for _ip_address in "${_local_param_from[@]}"; do
                            if [[ "${_ip_address}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                                # IPv4 addresses
                                _rules+="${_param_action} ${_param_interface} proto tcp from ${_ip_address} port ${_port} ${_param_comment};"
                                _rules+="${_param_action} ${_param_interface} proto udp from ${_ip_address} port ${_port} ${_param_comment};"
                            elif [[ "${_ip_address}" =~ ^[0-9a-fA-F:]+$ ]]; then
                                # IPv6 addresses
                                _rules+="${_param_action} ${_param_interface} proto tcp from ${_ip_address} port ${_port} ${_param_comment};"
                                _rules+="${_param_action} ${_param_interface} proto udp from ${_ip_address} port ${_port} ${_param_comment};"
                            fi
                        done
                    fi
                fi
            done
        elif [[ "${_param_protocol}" == "TCP" ]]; then
            # Add TCP rule
            # For each port in _param_port
            for _port in "${_param_port[@]}"; do
                if ((_port > 65535)) || ((_port < 1)); then
                    die "[Error] Invalid port range: '${_port}'. Ports must be between 1 and 65535." 1
                fi

                # Check if the from field is empty
                if [[ -z "${_param_from}" ]]; then
                    # Add TCP and UDP rules for any
                    _rules+="${_param_action} ${_param_interface} proto tcp from any port ${_port} ${_param_comment};"
                else
                    # Check if the from field is empty
                    if [[ -z "${_local_param_from[*]}" ]]; then
                        # Add TCP and UDP rules for any
                        _rules+="${_param_action} ${_param_interface} proto tcp from any port ${_port} ${_param_comment};"
                    else
                        # For each from in _local_param_from
                        for _ip_address in "${_local_param_from[@]}"; do
                            if [[ "${_ip_address}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                                # IPv4 addresses
                                _rules+="${_param_action} ${_param_interface} proto tcp from ${_ip_address} port ${_port} ${_param_comment};"
                            elif [[ "${_ip_address}" =~ ^[0-9a-fA-F:]+$ ]]; then
                                # IPv6 addresses
                                _rules+="${_param_action} ${_param_interface} proto tcp from ${_ip_address} port ${_port} ${_param_comment};"
                            fi
                        done
                    fi
                fi
            done
        elif [[ "${_param_protocol}" == "UDP" ]]; then
            # Add UDP rule
            # For each port in _param_port
            for _port in "${_local_param_from[@]}"; do
                if ((_port > 65535)) || ((_port < 1)); then
                    die "[Error] Invalid port range: '${_port}'. Ports must be between 1 and 65535." 1
                fi

                # Check if the from field is empty
                if [[ -z "${_local_param_from[*]}" ]]; then
                    # Add TCP and UDP rules for any
                    _rules+="${_param_action} ${_param_interface} proto udp from any port ${_port} ${_param_comment};"
                else
                    # For each from in _local_param_from
                    for _ip_address in "${_local_param_from[@]}"; do
                        if [[ "${_ip_address}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                            # IPv4 addresses
                            _rules+="${_param_action} ${_param_interface} proto udp from ${_ip_address} port ${_port} ${_param_comment};"
                        elif [[ "${_ip_address}" =~ ^[0-9a-fA-F:]+$ ]]; then
                            # IPv6 addresses
                            _rules+="${_param_action} ${_param_interface} proto udp from ${_ip_address} port ${_port} ${_param_comment};"
                        fi
                    done
                fi
            done
        elif [[ "${_param_protocol}" == "Any" ]]; then
            # Add any rules
            # For each port in _param_port
            for _port in "${_param_port[@]}"; do
                if ((_port > 65535)) || ((_port < 1)); then
                    die "[Error] Invalid port range: '${_port}'. Ports must be between 1 and 65535." 1
                fi
                # For each from in _local_param_from
                local -a _ip_addresses=()
                if [[ -z "${_local_param_from[*]}" ]]; then
                    local _from=" from any"
                else
                    local _from=" from ${_param_from}"
                    for _ip_address in "${_local_param_from[@]}"; do
                        if [[ "${_ip_address}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                            # IPv4 addresses
                            _rules+="${_param_action} ${_param_interface} proto any from ${_ip_address} port ${_port} ${_param_comment};"
                        elif [[ "${_ip_address}" =~ ^[0-9a-fA-F:]+$ ]]; then
                            # IPv6 addresses
                            _rules+="${_param_action} ${_param_interface} proto any from ${_ip_address} port ${_port} ${_param_comment};"
                        fi
                    done
                fi
            done
        fi
    fi

    echo "${_rules}"
}

ufw_apply_rules() {
    local _param_action=$1
    local _param_port=$2
    local _param_protocol=$3
    local _param_interface=$4
    local _param_from=$5
    local _param_comment=$6
    local _local_rules
    if ! _local_rules=$(build_ufw_params "${_param_action}" "${_param_port}" "${_param_protocol}" "${_param_interface}" "${_param_from}" "${_param_comment}"); then
        die "[Error] Failed to build UFW rules." 1
    fi
    declare OIFS=$IFS
    declare IFS=';'
    read -r -a _rules <<<"${_local_rules}"
    IFS=$OIFS
    _has_error=false
    # Dry run the rules
    for _rule in "${_rules[@]}"; do
        if [[ -n "${_rule}" ]]; then
            ufw_dryrun_command="ufw --dry-run ${_rule}"
            echo "[Info] Running: ${ufw_dryrun_command}"
            if ! eval "${ufw_dryrun_command}" >/dev/null; then
                echo_error "[Error] Dry run failed with: ${ufw_dryrun_command}"
                _has_error=true
            fi
        fi
    done
    if [[ "${_has_error}" == true ]]; then
        echo_error "[Error] One or more rules could not be applied."
        return 1
    fi
    # Apply the rules
    for _rule in "${_rules[@]}"; do
        if [[ -n "${_rule}" ]]; then
            ufw_command="ufw ${_rule}"
            echo "[Info] Running: ${ufw_command}"
            if eval "${ufw_command}"; then
                echo "[Info] Rule added successfully with: ${ufw_command}."
            else
                echo "[Info] ${ufw_command}"
                echo_error "[Error] Failed to add rule."
            fi
        fi
    done
}

# Set the default values
_arg_interface=
_arg_protocol=
_arg_port=
_arg_action=
_arg_from=

print_help() {
    printf '%s\n' "The general script's help msg"
    printf 'Usage: %s [-i|--interface <arg>] [-l|--protocol <arg>] [-t|--port <arg>] [-a|--action <arg>] [-f|--from <arg>] [-h|--help]\n' "$0"
    printf '\t%s\n' "-i, --interface: Interface (no default)"
    printf '\t%s\n' "-l, --protocol: TCP, UDP, or Both (no default)"
    printf '\t%s\n' "-t, --port: list of ports or ranges of ports, e.g. 800, 443, 500-505 (no default)"
    printf '\t%s\n' "-a, --action: Allow, Deny, Reject (no default)"
    printf '\t%s\n' "-f, --from: IP address (no default)"
    printf '\t%s\n' "-h, --help: Prints help"
}

parse_commandline() {
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        -i | --interface)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_interface="$2"
            shift
            ;;
        --interface=*)
            _arg_interface="${_key##--interface=}"
            ;;
        -i*)
            _arg_interface="${_key##-i}"
            ;;
        -l | --protocol)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_protocol="$2"
            shift
            ;;
        --protocol=*)
            _arg_protocol="${_key##--protocol=}"
            ;;
        -l*)
            _arg_protocol="${_key##-l}"
            ;;
        -t | --port)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_port="$2"
            shift
            ;;
        --port=*)
            _arg_port="${_key##--port=}"
            ;;
        -t*)
            _arg_port="${_key##-t}"
            ;;
        -a | --action)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_action="$2"
            shift
            ;;
        --action=*)
            _arg_action="${_key##--action=}"
            ;;
        -a*)
            _arg_action="${_key##-a}"
            ;;
        -f | --from)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_from="$2"
            shift
            ;;
        --from=*)
            _arg_from="${_key##--from=}"
            ;;
        -f*)
            _arg_from="${_key##-f}"
            ;;
        -h | --help)
            print_help
            exit 0
            ;;
        -h*)
            print_help
            exit 0
            ;;
        *)
            _PRINT_HELP=yes die "[Error] Got an unexpected argument '$1'" 1
            ;;
        esac
        shift
    done
}

parse_commandline "$@"

# Check if ufw is installed
if ! command -v ufw &>/dev/null; then
    die "[Error] UFW is not installed!" 1
fi

# Check if we are running as root
is_root

# Check if ufw is enabled
if ! ufw status | grep -q "Status: active"; then
    die "[Error] UFW is not enabled!" 1
fi

# Get our script variables
if [[ -n "${interface}" ]] && [[ "${_arg_interface}" != "null" ]]; then
    _arg_interface="${interface}"
fi

if [[ -n "${from}" ]] && [[ "${_arg_from}" != "null" ]]; then
    _arg_from="${from}"
fi

if [[ -n "${protocol}" ]]; then
    _arg_protocol="${protocol}"
fi

if [[ -n "${port}" ]]; then
    _arg_port="${port}"
fi

if [[ -n "${action}" ]]; then
    _arg_action="${action}"
fi

# Get list of interfaces
interfaces=$(ip link show | awk -F '\:\ ' '{print $2}' 2>/dev/null | sed 's/ //g' | sort -u | tr '\n' ',' | sed 's/^,//' | sed 's/,$//')

# Check if the interface is valid
if [[ "${interfaces}" == *"${_arg_interface}",* ]]; then
    if [[ -z "${_arg_interface}" ]] || [[ "${_arg_interface}" == "null" ]]; then
        echo "[Info] Interface is empty, applying to all interfaces."
    else
        echo "[Info] Interface '${_arg_interface}' is a valid interface."
    fi
else
    die "[Error] Invalid interface '${_arg_interface}'." 1
fi

# Validate the type of protocol
if [[ "${_arg_protocol}" == "TCP" ]] || [[ "${_arg_protocol}" == "UDP" ]] || [[ "${_arg_protocol}" == "Any" ]] || [[ "${_arg_protocol}" == "Both" ]]; then
    echo ""
else
    die "[Error] Invalid protocol '${_arg_protocol}'." 1
fi

# Validate the action
if [[ "${_arg_action}" == "Allow" ]] || [[ "${_arg_action}" == "Deny" ]] || [[ "${_arg_action}" == "Reject" ]]; then
    echo "[Info] Action '${_arg_action}' is valid."
    if [[ "${_arg_action}" == "Allow" ]]; then
        _arg_action="allow"
    elif [[ "${_arg_action}" == "Deny" ]]; then
        _arg_action="deny"
    elif [[ "${_arg_action}" == "Reject" ]]; then
        _arg_action="reject"
    fi
else
    die "[Error] Invalid action '${_arg_action}'." 1
fi

# Create parts of the rule

# Port
if [[ -z "${_arg_port}" ]]; then
    die "[Error] Port is required." 1
fi

# Action
if [[ -z "${_arg_action}" ]]; then
    die "[Error] Action is required." 1
fi

# Comment
_comment="comment 'Created on $(date --utc) from NinjaRRM by script: Firewall - Configure UFW Exceptions - Linux'"

# Get the number of rules
declare -i _rule_count
_rule_count=$(ufw status numbered | tail -n 2 | head -n 1 | sed -e 's/\[//g' -e 's/\]//g' | awk '{ if ($1 ~ /^[0-9]+$/) print $1; else print "0"; }')

# Print the status of the firewall
echo "[Info] Current UFW status before adding rules:"
ufw status verbose

# Print the number of rules
echo "[Info] Number of rule before adding rules: ${_rule_count}"

# Apply the rules
if ufw_apply_rules "${_arg_action}" "${_arg_port}" "${_arg_protocol}" "${_arg_interface}" "${_arg_from}" "${_comment}"; then
    # Print the status of the firewall
    echo "[Info] Current UFW status after adding rules:"
    ufw status verbose
    # Print the number of rules
    _rule_count=$(ufw status numbered | tail -n 2 | head -n 1 | sed -e 's/\[//g' -e 's/\]//g' | awk '{ if ($1 ~ /^[0-9]+$/) print $1; else print "0"; }')
    echo "[Info] Number of rule after adding rules: ${_rule_count}"
else
    die "[Error] Failed to apply rules." 1
fi




