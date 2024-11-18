#!/usr/bin/env bash

# Description: Alert when the specified Text is found in a text file.
#
# Release Notes: Initial Release
#
# Text to trigger on: [Alert]
#
# Below are all the valid parameters for this script.
# Preset Parameter: --file "/opt/MyLogFile.log" --text batman
#   Alerts when the text "batman" is found in the file /opt/MyLogFile.log
#    This is Case Sensitive
#     Example where it will alert: "I am batman!"
#     Example where it will alert: "Iambatman!"
#     Example where it will not alert: "IamBatman!"
#     Example where it will not alert: "I am Batman!"
#
# Preset Parameter: --file "/opt/MyLogFile.log" --text Batman --caseInsensitive true
#   Alerts when the text "Batman" is found in the file /opt/MyLogFile.log, but is case insensitive
#    This is Case Insensitive
#     Example where it will alert: "I am batman!"
#     Example where it will alert: "Iambatman!"
#
# Preset Parameter: --file "/opt/MyLogFile.log" --text Batman --wholeWord true
#   Alerts when the text "Batman" is found in the file /opt/MyLogFile.log, but only if it is a word in a sentence.
#    This is Case Sensitive
#     Example where it will alert: "I am Batman!"
#     Example where it will not alert: "IamBatman!"
#

# Determines whether or not help text is necessary and routes the output to stderr
die() {
    local _ret="${2:-1}"
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    echo "$1" >&2
    exit "${_ret}"
}

# Function that evaluates whether a value passed to it begins by a character
# that is a short option of an argument the script knows about.
# This is required in order to support getopts-like short options grouping.
begins_with_short_option() {
    local first_option all_short_options='ftiwh'
    first_option="${1:0:1}"
    test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_file=
_arg_text=
_arg_caseInsensitive="false"
_arg_wholeWord="false"

# Help text function for when invalid input is encountered
print_help() {
    printf '%s\n' "Alert when the specified Text is found in a text file."
    printf 'Usage: %s [-f|--file [path to file]] [-t|--text [text to search]] [-i|--caseInsensitive <true|false>] [-w|--wholeWord <true|false>] [-h|--help]\n' "$0"
    printf '\t%s\n' "-f, --file: path to a log file"
    printf '\t%s\n' "-t, --text: text to alert when found"
    printf '\t%s\n' "-i, --caseInsensitive: search text with case insensitivity (default: false)"
    printf '\t%s\n' "-w, --wholeWord: search for text as a whole word (default: false)"
    printf '\t%s\n' "-h, --help: Prints help"
}

# Grabbing the parameters and parsing through them.
parse_commandLine() {
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        -f | --file)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_file="$2"
            shift
            ;;
        --file=*)
            _arg_file="${_key##--file=}"
            ;;
        -f*)
            _arg_file="${_key##-f}"
            ;;
        -t | --text)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_text="$2"
            shift
            ;;
        --text=*)
            _arg_text="${_key##--text=}"
            ;;
        -t*)
            _arg_text="${_key##-t}"
            ;;
        -i | --caseInsensitive)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_caseInsensitive="$2"
            shift
            ;;
        --caseInsensitive=*)
            _arg_caseInsensitive="${_key##--caseInsensitive=}"
            ;;
        -i*)
            _arg_caseInsensitive="${_key##-i}"
            ;;
        -w | --wholeWord)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_wholeWord="$2"
            shift
            ;;
        --wholeWord=*)
            _arg_wholeWord="${_key##--wholeWord=}"
            ;;
        -w*)
            _arg_wholeWord="${_key##-w}"
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

parse_commandLine "$@"

text=$_arg_text
file=$_arg_file
caseInsensitive=$_arg_caseInsensitive
wholeWord=$_arg_wholeWord

# Check if Script Variables where used and overwrite command line parameters
if [[ -n "${textToMatch}" ]]; then
    text=$textToMatch
fi
if [[ -n "${textFile}" ]]; then
    file=$textFile
fi
if [[ -n "${matchWholeWord}" ]]; then
    wholeWord=$matchWholeWord
fi
if [[ -n "${insensitiveToCase}" ]]; then
    caseInsensitive=$insensitiveToCase
fi

# Check if text is not an empty string
if [[ -z "${text}" ]]; then
    echo "[Error] Text not specified"
    exit 2
fi

# Check if text is not an empty string
if [[ -z "${file}" ]]; then
    echo "[Error] File not specified"
    exit 2
fi

# Does file exit and is readable
if [ -f "${file}" ]; then
    echo "[Info] File \"${file}\" exists"
    if [ -r "${file}" ]; then
        echo "[Info] File \"${file}\" is readable"
    else
        echo "[Error] File \"${file}\" is not readable"
        exit 2
    fi
else
    echo "[Error] File \"${file}\" does not exists"
    exit 2
fi

# Detect
count=0
if [[ "${wholeWord}" == "true" ]]; then
    if [[ "${caseInsensitive}" == "true" ]]; then
        count=$(grep -c -i -n -w "$text" "$file")
    else
        count=$(grep -c -n -w "$text" "$file")
    fi
else
    if [[ "${caseInsensitive}" == "true" ]]; then
        count=$(grep -c -i -n -e "$text" "$file")
    else
        count=$(grep -c -n -e "$text" "$file")
    fi
fi

# Alert
if ((count > 0)); then
    echo "[Alert] Found text in file"
    exit 1
else
    echo "[Info] Not found text in file"
    exit 0
fi




