#!/bin/bash

# Description: Clears the dns cache the number of times you specify (defaults to 3).
#
# Release Notes: Initial Release
#
# Below are all the valid parameters for this script.
# Preset Parameter: "ReplaceWithNumberOfTimesToClearCache"
#
#

# Help text function for when invalid input is encountered
print_help() {
    printf '\n### Below are all the valid parameters for this script. ###\n'
    printf '\nPreset Parameter: "ReplaceWithNumberOfTimesToClearCache" \n'
    printf '\t%s\n' "The number of times you would like to clear the cache."
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
        --*)
            _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
            ;;
        *)
            if [[ -z $_arg_attempts ]]; then
                _arg_attempts=$1
            else
                _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1' but the number of attempts '$_arg_attempts' was already specified" 1
            fi
            ;;
        esac
        shift
    done
}

parse_commandline "$@"

# If the number of times isn't specified we should default to 3
if [[ -n $numberOfTimesToClearCache ]]; then
    _arg_attempts=$numberOfTimesToClearCache
fi

# If attempts was empty set a default
if [[ -z $_arg_attempts ]]; then
    _arg_attempts=3
fi

# Loop through each cache clearing attempt
for ((i = 1; i <= _arg_attempts; i++)); do
    sleep 1
    echo "DNS Cache clearing attempt $i."

    # Flushes the dns cache
    dscacheutil -flushcache
    killall -HUP mDNSResponder

    # Check if dscacheutil was successful
    if [ $? -ne 0 ]; then
        _PRINT_HELP=no die "FATAL ERROR: Failed to flush dns cache!" 1
    fi

    echo "Successfully cleared cache!"
    echo ""
done





