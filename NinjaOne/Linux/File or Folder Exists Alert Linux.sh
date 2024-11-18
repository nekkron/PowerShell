#!/usr/bin/env bash

# Description: Alert if a specified file or folder is found in a directory or subdirectory you specify.
#
# Release Notes: Initial Release
#
# Below are all the (case sensitive) valid parameters for this script.
# Only the path to search and name of file or folder are required!
#
# Parameter: --path "/opt/NinjaRMM/programdata"
#   Required
#   Base path to search for files or folders.
#
# Parameter: --name "ninjarmm-cli"
#   Required
#   Name of the file or folder to search for.
#   Notes:
#       If the name is not provided, the script will search for the path only.
#       This is case sensitive and accepts wildcards.
#
# Parameter: --type "Files Or Folders"
#   Required
#   Search for files or folders.
#
# Parameter: --type "Files Only"
#   Required
#   Searches for files only.
#
# Parameter: --type "Folders Only"
#   Required
#   Searches for folder only.
#
# Parameter: --timeout 10
#   Optional and defaults to 30 minutes
#   Time in minutes to wait for the search to complete before timing out.
#
# Parameter: --customfield "myCustomField"
#   Optional
#   Custom Field to save the search results to.

die() {
    local _ret="${2:-1}"
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    echo "$1" >&2
    exit "${_ret}"
}

begins_with_short_option() {
    local first_option all_short_options='h'
    first_option="${1:0:1}"
    test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# Initize arguments
_arg_path=
_arg_name=
_arg_type=
_arg_timeout=30
_arg_customfield=

print_help() {
    printf '%s\n' "Check existence of a file or folder"
    printf 'Usage: %s [--path <arg>] [--name <arg>] [--type <"Files Only"|"Folders Only"|"Files Or Folders">] [--timeout <30>] [--customfield <arg>] [-h|--help]\n' "$0"
    printf '\t%s\n' "-h, --help: Prints help"
}

parse_commandline() {
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        --path)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_path="$2"
            shift
            ;;
        --path=*)
            _arg_path="${_key##--path=}"
            ;;
        --name)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_name="$2"
            shift
            ;;
        --name=*)
            _arg_name="${_key##--name=}"
            ;;
        --type)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_type="$2"
            shift
            ;;
        --type=*)
            _arg_type="${_key##--type=}"
            ;;
        --timeout)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_timeout="$2"
            shift
            ;;
        --timeout=*)
            _arg_timeout="${_key##--timeout=}"
            ;;
        --customfield)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_customfield="$2"
            shift
            ;;
        --customfield=*)
            _arg_customfield="${_key##--customfield=}"
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
            _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
            ;;
        esac
        shift
    done
}

parse_commandline "$@"

function SetCustomField() {
    customfieldName=$1
    customfieldValue=$2
    if [ -f "${NINJA_DATA_PATH}/ninjarmm-cli" ]; then
        if [ -x "${NINJA_DATA_PATH}/ninjarmm-cli" ]; then
            if "$NINJA_DATA_PATH"/ninjarmm-cli get "$customfieldName" >/dev/null; then
                # check if the value is greater than 10000 characters
                if [ ${#customfieldValue} -gt 10000 ]; then
                    echo "[Warn] Custom field value is greater than 10000 characters"
                fi
                if ! echo "${customfieldValue::10000}" | "$NINJA_DATA_PATH"/ninjarmm-cli set --stdin "$customfieldName"; then
                    echo "[Warn] Failed to set custom field"
                else
                    echo "[Info] Custom field value set successfully"
                fi
            else
                echo "[Warn] Custom Field ($customfieldName) does not exist or agent does not have permission to access it"
            fi
        else
            echo "[Warn] ninjarmm-cli is not executable"
        fi
    else
        echo "[Warn] ninjarmm-cli does not exist"
    fi
}

parentSearchPath=$_arg_path
leafSearchName=$_arg_name
searchType=$_arg_type
timeout=$_arg_timeout
customField=$_arg_customfield

# Get values from Script Variables
if [[ -n "${pathToSearch}" ]]; then
    parentSearchPath="${pathToSearch}"
fi
if [[ -n "${nameOfFileOrFolder}" ]]; then
    leafSearchName="${nameOfFileOrFolder}"
fi
if [[ -n "${filesOrFolders}" && "${filesOrFolders}" != "null" ]]; then
    searchType="${filesOrFolders}"
fi
if [[ -n "${searchTimeout}" && "${searchTimeout}" != "null" ]]; then
    timeout="${searchTimeout}"
fi
if [[ -n "${customFieldName}" && "${customFieldName}" != "null" ]]; then
    customField="${customFieldName}"
fi

if [[ -z "${parentSearchPath}" ]]; then
    echo "[Error] Path to Search is empty"
    exit 1
fi

# Check if path exists
if [ -e "${parentSearchPath}" ]; then
    echo "[Info] Path ${parentSearchPath} exists"
else
    echo "[Error] Path to Search ${parentSearchPath} does not exist or is an invalid path"
    exit 1
fi

# Check if timeout is a number
if ! [[ "${timeout}" =~ ^[0-9]+$ ]]; then
    echo "[Error] Timeout is not a number"
    exit 1
fi
# Check if timeout is not in the range of 1 to 120
if [[ "${timeout}" -lt 1 || "${timeout}" -gt 120 ]]; then
    echo "[Error] Timeout is not in the range of 1 to 120"
    exit 1
fi

# Search for files or folders
if [[ -n "${leafSearchName}" && "${leafSearchName}" != "null" ]]; then
    if [[ "${searchType}" == *"Files"* && "${searchType}" == *"Only"* ]]; then
        echo "[Info] Searching for files only"
        # Search for files only
        # Use timeout to prevent the find command from running indefinitely
        foundPath=$(timeout "${timeout}m" find "$parentSearchPath" -type f -name "$leafSearchName" 2>/dev/null)
        exitcode=$?
        if [[ $exitcode -eq 0 || $exitcode -eq 124 ]]; then
            if [[ -n $foundPath ]]; then
                echo "[Alert] File Found"
            fi
        fi
    elif [[ "${searchType}" == *"Folders"* && "${searchType}" == *"Only"* ]]; then
        echo "[Info] Searching for folders only"
        # Search for folders only
        # Use timeout to prevent the find command from running indefinitely
        foundPath=$(timeout "${timeout}m" find "$parentSearchPath" -type d -name "$leafSearchName" 2>/dev/null)
        exitcode=$?
        if [[ $exitcode -eq 0 || $exitcode -eq 124 ]]; then
            if [[ -n $foundPath ]]; then
                echo "[Alert] File Found"
            fi
        fi
    elif [[ "${searchType}" == *"Files"* && "${searchType}" == *"Folders"* ]]; then
        echo "[Info] Searching for files or folders"
        # Search for files or folders
        # Use timeout to prevent the find command from running indefinitely
        foundPath=$(timeout "${timeout}m" find "$parentSearchPath" -name "$leafSearchName" 2>/dev/null)
        exitcode=$?
        if [[ $exitcode -eq 0 || $exitcode -eq 124 ]]; then
            if [[ -n $foundPath ]]; then
                echo "[Alert] File Found"
            fi
        fi
    else
        echo "[Error] Invalid search type"
        echo "Valid search types: Files Only, Folders Only, Files Or Folders"
        exit 1
    fi
elif [[ -z "${leafSearchName}" ]]; then
    # Search in path only
    echo "[Info] Searching in path only"
    # Search in path only
    # Use timeout to prevent the find command from running indefinitely
    foundPath=$(timeout "${timeout}m" find "$parentSearchPath")
    exitcode=$?
    if [[ $exitcode -eq 0 || $exitcode -eq 124 ]]; then
        if [[ -n $foundPath ]]; then
            echo "[Alert] File Found"
        fi
    fi
fi

# Check exit code
if [[ -n $foundPath ]]; then
    if [[ -n "${foundPath}" ]]; then
        # Split the string into an array
        IFS=$'\n' read -rd '' -a foundPathArray <<<"${foundPath}"
        # Print each element of the array
        for element in "${foundPathArray[@]}"; do
            echo "[Alert] ${element} exists"
        done
    elif [[ -z "${foundPath}" ]]; then
        echo "[Info] ${foundPath} does not exist"
    fi
elif [[ -z $foundPath ]]; then
    echo "[Warn] Could not find a file or folder"
    exit 1
else
    # If the find command fails to find the file or folder

    # Figure out the grammer for the search type
    if [[ "${searchType}" == *"Only"* ]]; then
        if [[ "${searchType}" == *"Files"* ]]; then
            searchTypeInfo="file"
        elif [[ "${searchType}" == *"Folders"* ]]; then
            searchTypeInfo="folder"
        fi
    elif [[ "${searchType}" == *"Files"* && "${searchType}" == *"Folders"* ]]; then
        searchTypeInfo="file or folder"
    fi
    echo "[Info] Could not find a ${searchTypeInfo} in the path ${parentSearchPath} with the name containing: ${leafSearchName}"
fi

# If command times out
if [[ $exitcode -ge 124 && $exitcode -le 127 || $exitcode -eq 137 ]]; then
    echo "[Alert] Timed out searching for file or folder"
    echo "timeout exit code: $exitcode"
    echo "  124  if COMMAND times out, and --preserve-status is not specified"
    echo "  125  if the timeout command itself fails"
    echo "  126  if COMMAND is found but cannot be invoked"
    echo "  127  if COMMAND cannot be found"
    echo "  137  if COMMAND (or timeout itself) is sent the KILL (9) signal (128+9)"
    echo "find command result: $foundPath"
    exit 1
fi

# Save to custom field
if [[ -n "${customField}" && "${customField}" != "null" ]]; then
    SetCustomField "${customField}" "${foundPath}"
fi





