#!/usr/bin/env bash

# Description: Exports the Ninja Support Logs to the specified directory for Linux.
#
# Preset Parameter: --destination "/tmp"
#   The directory to export the logs to.
#
# Preset Parameter: --help
#   Displays some help text.

# These are all our preset parameter defaults. You can set these = to something if you would prefer the script defaults to a certain parameter value.
_arg_destination="/tmp"

# Help text function for when invalid input is encountered
print_help() {
    printf '\n\n%s\n\n' 'Usage: [--destination|-d <arg>] [--help|-h]'
    printf '%s\n' 'Preset Parameter: --destination "/tmp"'
    printf '\t%s\n' "Replace the text encased in quotes with the directory to export the logs to."
    printf '\n%s\n' 'Preset Parameter: --help'
    printf '\t%s\n' "Displays this help menu."
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
        --destination | -d)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_destination=$2
            shift
            ;;
        --destination=*)
            _arg_destination="${_key##--destination=}"
            ;;
        --help | -h)
            _PRINT_HELP=yes die 0
            ;;
        *)
            _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
            ;;
        esac
        shift
    done
}

parse_commandline "$@"

# If script form is used override commandline arguments
if [[ -n $destination ]] && [[ "${destination}" != "null" ]]; then
    _arg_destination="$destination"
fi

# Get the path to the NinjaRMMAgent from the environment variable NINJA_DATA_PATH
_data_path=$(printenv | grep -i NINJA_DATA_PATH | awk -F = '{print $2}')
if [[ -z "${_data_path}" ]]; then
    # If the environment variable NINJA_DATA_PATH is not set, try to find the NinjaRMMAgent in the Applications folder
    _data_path="/opt/NinjaRMMAgent/programdata"
    if [[ -z "${_data_path}" ]]; then
        echo "[Error] No NinjaRMMAgent found. Please make sure you have the NinjaRMMAgent installed and that it is running."
        exit 1
    fi
fi

# Get the current date
cur_date="$(date +%Y-%m-%d)"

# Trim the trailing slash from the destination path
dest_path=$(echo "$_arg_destination" | sed 's/\/$//')

# Collect the logs from the following directories
if [ "$(command -v zip)" ]; then
    echo "[Info] Exporting logs to $dest_path/NinjaSupportLogs.zip"
    if zip -r -q "$dest_path/$cur_date-NinjaLogs.zip" "$_data_path/logs" "$_data_path/policy" "$_data_path/jsonoutput" "$_data_path/jsoninput" "$_data_path/patch"; then
        echo "[Info] Logs exported to $dest_path/$cur_date-NinjaLogs.zip"
    else
        echo "[Error] Failed to export logs to $dest_path/$cur_date-NinjaLogs.zip"
        exit 1
    fi
elif [ "$(command -v tar)" ]; then
    echo "[Warn] zip command not found. Using tar instead."
    echo "[Info] Exporting logs to $dest_path/NinjaSupportLogs.tar.gz"
    if tar -czf "$dest_path/$cur_date-NinjaLogs.tar.gz" "$_data_path/logs" "$_data_path/policy" "$_data_path/jsonoutput" "$_data_path/jsoninput" "$_data_path/patch"; then
        echo "[Info] Logs exported to $dest_path/$cur_date-NinjaLogs.tar.gz"
    else
        echo "[Error] Failed to export logs to $dest_path/$cur_date-NinjaLogs.tar.gz"
        exit 1
    fi
else
    echo "[Error] zip or tar not found. Please install zip or tar."
    exit 1
fi





