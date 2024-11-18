#!/usr/bin/env bash

# Description: Set the idle session timeout for the terminal and optionally reboot to apply the change.
#
# Release Notes: Initial Release
#
# Usage: [--timeout <seconds>] [--help]
# <> are required
# [] are optional
#
# Example: Set the idle session timeout to 1800 seconds(30 minutes)
#   --timeout 1800
#

# Parameters
_arg_timeout=
_arg_reboot=

# Help text function for when invalid input is encountered
print_help() {
    printf '\n\n%s\n\n' 'Usage: [--timeout <Arg>] [--reboot] [--help]'
    printf '%s\n' 'Preset Parameter: --timeout "ReplaceMeWithYourDesiredTimeout"'
    printf '\t%s\n' "The idle session timeout to set for the terminal. This is in seconds."
}

# Determines whether or not help text is necessary and routes the output to stderr
die() {
    local _ret="${2:-1}"
    echo "$1" >&2
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    exit "${_ret}"
}

# Grabbing the parameters and parsing through them.
parse_commandline() {
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        --timeout | -t)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_timeout="$2"
            shift
            ;;
        --timeout=*)
            _arg_timeout="${_key##--timeout=}"
            ;;
        --reboot)
            _arg_reboot="on"
            ;;
        --help | -h)
            _PRINT_HELP=yes die 0
            ;;
        *)
            _PRINT_HELP=yes die "[Error] Got an unexpected argument '$1'" 1
            ;;
        esac
        shift
    done
}

# Creates a backup of a file if it exists
# Defaults to keeping 3 backups and removes the oldest backup if there are more than 3 backups
# Parameters: <File> [Number of Backups to Keep]
# Example:
#  backup_file "/tmp/test.txt" 3
#  [Info] Backing up /tmp/test.txt to /tmp/test.txt_2023-04-17_23-13-58.backup
#  [Info] Removing /tmp/test.txt_2023-04-10_20-10-50.backup
backup_file() {
    local _file_source=$1
    local -i _keep_backups="$((3 + 1))"
    if [[ -n "${2}" ]]; then
        _keep_backups="$(("${2}" + 1))"
    fi
    local _file_backup
    local _file_source_dir
    local _file_source_file
    local _backup_files
    _file_backup="${_file_source}_$(date +%Y-%m-%d_%H-%M-%S).backup"
    if [[ -f "${_file_source}" ]]; then
        echo "[Info] Backing up $_file_source to $_file_backup"
        cp "${_file_source}" "${_file_backup}"
    fi

    # Remove the oldest backup file if there are more than 3 backups

    # Get the list of backup files
    echo "[Info] Finding backup files..."
    _file_source_dir=$(dirname "${_file_source}")
    _file_source_file=$(basename "${_file_source}")
    _backup_files=$(find "$_file_source_dir" -name "${_file_source_file}_*.backup" -printf '%T+ %p\n' 2>/dev/null | sort -r | tail -n "+${_keep_backups}" | cut -d' ' -f2-)
    # Loop through each backup file and remove it
    for backup_file in $_backup_files; do
        echo "[Info] Removing $backup_file"
        rm -f "$backup_file"
    done
}

parse_commandline "$@"

# If script form variables are used replace command line parameters
if [[ -n $setTimeoutInSeconds ]]; then
    _arg_timeout="$setTimeoutInSeconds"
fi

# If reboot is set to true, set the reboot variable to on
if [[ -n $reboot ]] && [[ "$reboot" == "true" ]]; then
    _arg_reboot="on"
fi

# Check if the timeout is a number
if ! [[ "$_arg_timeout" =~ ^[0-9]+$ ]]; then
    die "[Error] Timeout must be a number." 1
fi

# Check if the timeout is greater than 0
if [[ "$_arg_timeout" -lt 0 ]]; then
    die "[Error] Timeout must be 0 or greater." 1
fi

# Set a value in a file or append it to the end of the file if it doesn't exist
# Parameters: <Name> <Search String> <Value> <File>
# Example:
#  set_value_in_file "Name To Be Printed" "Hello=" "World" "/tmp/test.txt"
#  Sets the value "Hello=World" in /tmp/test.txt
#  If the value "Hello=" does exist, the line will be replaced with "Hello=World"
#  If the value "Hello=" does not exist, it will be appended to the end of the file
set_value_in_file() {
    local _name=$1
    local _search=$2
    local _value=$3
    local _file=$4
    if [ -f "${_file}" ]; then
        # Check if _search is set
        if grep -q "^${_search}" "${_file}"; then
            # Replace the existing _search value with the new value
            echo "[Info] Setting ${_name} to ${_value} seconds"
            if ! sed -i "s/^${_search}.*/${_search}${_value}/" "${_file}"; then
                die "[Error] Failed to set the ${_name} to ${_value} seconds" 1
            fi
            echo "[Info] Set ${_name} to ${_value} seconds"
        else
            # Add the new value to the end of the file
            echo "[Info] Setting ${_name} to ${_value} seconds"
            if ! echo "${_search}${_value}" >>"${_file}"; then
                die "[Error] Failed to set the ${_name} to ${_value} seconds" 1
            fi
            echo "[Info] Set ${_name} to ${_value} seconds"
        fi
    fi
}

# Backup /etc/profile
backup_file "/etc/profile"

# Set TMOUT in /etc/profile to the timeout value
set_value_in_file "timeout" "export TMOUT=" "${_arg_timeout}" "/etc/profile"

# Reboot if requested
if [[ $_arg_reboot == "on" ]]; then
    # Reboot if requested
    echo "[Info] Rebooting computer."
    if [ "$(command -v systemctl)" ]; then
        echo "[Info] Using systemctl to reboot. Reboot will start in 1 minute."
        sleep 60
        systemctl reboot
    elif [ "$(command -v reboot)" ]; then
        echo "[Info] Using reboot to reboot. Reboot will start in 1 minute."
        sleep 60
        reboot
    else
        echo "[Info] Using the shutdown command to reboot. Reboot will start in 1 minute."
        shutdown -r +1 "Rebooting to apply system wide profile change(s)."
    fi
fi




