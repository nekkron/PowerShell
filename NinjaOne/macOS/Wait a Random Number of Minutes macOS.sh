#!/bin/bash

# Description: Wait a random amount of time, default max time is 120 Minutes (2 hours).
#
# Release Notes: Initial Release
#
# Below are all the valid parameters for this script.
# Preset Parameter: "ReplaceWithMaxWaitTimeInMinutes"
#
#

# Help text function for when invalid input is encountered
print_help() {
  printf '\n### Below are all the valid parameters for this script. ###\n'
  printf '\nPreset Parameter: "ReplaceWithMaxWaitTimeInMinutes" \n'
  printf '\t%s\n' "The Maximum amount of time you want the script to wait in minutes."
}

# Determines whether or not help text is nessessary and routes the output to stderr
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

_arg_maxTime=

# Grabbing the parameters and parsing through them.
parse_commandline() {
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --help | -h)
      _PRINT_HELP=yes die 0
      ;;
    --*)
      _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
      ;;
    *)
      if [[ -z $_arg_maxTime ]]; then
        _arg_maxTime=$1
      else
        _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1' but the max time '$_arg_maxTime' was already specified!" 1
      fi
      ;;
    esac
    shift
  done
}

parse_commandline "$@"

# If the number of times isn't specified we should default to 3
if [[ -n $maxTimeInMinutes ]]; then
  _arg_maxTime=$maxTimeInMinutes
fi

# If attempts was empty set a default
if [[ -z $_arg_maxTime ]]; then
  _arg_maxTime=120
fi

pattern='^[0-9]+$'
if [[ ! $_arg_maxTime =~ $pattern ]]; then
  _PRINT_HELP=yes die "FATAL ERROR: Max time '$_arg_maxTime' is not a number!" 1
fi

if [[ $_arg_maxTime -lt 1 || $_arg_maxTime -ge 180 ]]; then
  _PRINT_HELP=no die "FATAL ERROR: Max time '$_arg_maxTime' must be greater than 1 or less than 180" 1
fi

maxTimeInSeconds=$((_arg_maxTime * 60))
waitTime=$((1 + RANDOM % maxTimeInSeconds))

if [[ $((waitTime / 60)) == 0 ]]; then
  echo "Sleeping for $waitTime Seconds"
else
  echo "Sleeping for $((waitTime / 60)) Minutes".
fi

sleep $waitTime

echo "Finished Sleeping"





