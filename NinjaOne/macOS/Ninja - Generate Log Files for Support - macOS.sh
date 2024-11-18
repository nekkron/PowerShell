#!/usr/bin/env bash

# Description: Exports the Ninja Support Logs to the specified directory for Mac.
#
# Preset Parameter: --destination "/private/tmp"
#   The directory to export the logs to.
#
# Preset Parameter: --help
#   Displays some help text.

# These are all our preset parameter defaults. You can set these = to something if you would prefer the script defaults to a certain parameter value.
_arg_destination="/private/tmp"

# Help text function for when invalid input is encountered
print_help() {
    printf '\n\n%s\n\n' 'Usage: [--destination|-d <arg>] [--createPath|-c] [--help|-h]'
    printf '%s\n' 'Preset Parameter: --destination "/private/tmp/ninjaLogs" --createPath'
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
        --createPath | -c)
            _arg_createPath="true"
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
if [[ -n $createPath ]] && [[ "${createPath}" == "true" ]]; then
    _arg_createPath="true"
fi

# Get the path to the NinjaRMMAgent from the environment variable NINJA_DATA_PATH
_data_path=$(printenv | grep -i NINJA_DATA_PATH | awk -F = '{print $2}')
if [[ -z "${_data_path}" ]]; then
    # If the environment variable NINJA_DATA_PATH is not set, try to find the NinjaRMMAgent in the Applications folder
    _data_path="/Applications/NinjaRMMAgent/programdata"
    if [[ -z "${_data_path}" ]]; then
        echo "[Error] No NinjaRMMAgent found. Please make sure you have the NinjaRMMAgent installed and that it is running."
        exit 1
    fi
fi

# Get the current date
cur_date="$(date +%Y-%m-%d)"

# Trim the trailing slash from the destination path and remove any duplicate slashes from the destination path
dest_path=$(echo "$_arg_destination" | sed 's/\/$//' | sed 's/\/\+/\//g')

if [ -e "${dest_path}" ]; then
    echo "[Info] The destination path (${dest_path}) exists."
else
    echo "[Warn] The destination path (${dest_path}) does not exist."
    if [[ "${_arg_createPath}" == "true" ]]; then
        echo "[Info] Creating the destination path (${dest_path})"
        mkdir -p "${dest_path}"
    else
        echo "[Error] The destination path (${dest_path}) does not exist."
        exit 1
    fi
fi

echo "[Info] Exporting logs to $dest_path/NinjaSupportLogs.zip"

# Collect the logs from the following directories
if zip -r -q "$dest_path/$cur_date-NinjaLogs.zip" "$_data_path/logs" "$_data_path/policy" "$_data_path/jsonoutput" "$_data_path/jsoninput" "$_data_path/patch"; then
    echo "[Info] Logs exported to $dest_path/$cur_date-NinjaLogs.zip"
else
    echo "[Error] Failed to export logs to $dest_path/$cur_date-NinjaLogs.zip"
    exit 1
fi





