#!/bin/bash

# Description: Restarts the TeamViewer Service. Be sure TeamViewer is set to "Start TeamViewer with System" or that the "TeamViewer Host" app is installed.
#
# Preset Parameter: --attempts 'Replace with the number of attempts you would like to make'
#   The number of attempts you would like to make to bring the TeamViewer service back online.
#
# Preset Parameter: --wait 'Replace with the amount of time in seconds you would like to wait in between attempts'
#   The number of seconds you would like to wait in between attempts
#
# Release Notes: Initial Release
#
_attempts=3
_waitTimeInSecs=15

# Help text function for when invalid input is encountered
print_help() {
  printf '\n### Below are all the valid parameters for this script. ###\n'
  printf '\nPreset Parameter: --attempts "ReplaceMeWithNumberOfAttempts" \n'
  printf '\t%s\n' "The Number of restart attempts you would like to make."
  printf '\nPreset Parameter: --wait "ReplaceMeWithTheAmountOfSecondsToWaitBetweenAttempts" \n'
  printf '\t%s\n' "The amount of seconds you would like to wait in between attempts."
}

# Determines whether or not help text is nessessary and routes the output to stderr
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
    --help | -h)
      _PRINT_HELP=yes die 0
      ;;
    --attempts | -a)
      _attempts=$2
      shift
      ;;
    --attempts=*)
      _attempts="${_key##--attempts=}"
      ;;
    --wait | -w)
      _waitTimeInSecs=$2
      shift
      ;;
    --wait=*)
      _waitTimeInSecs="${_key##--wait=}"
      ;;
    --*)
      _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
      ;;
    *)
      _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
      ;;
    esac
    shift
  done
}

parse_commandline "$@"

if [[ -n $attempts ]]; then
  _attempts=$attempts
fi

if [[ -n $waitTimeInSeconds ]]; then
  _waitTimeInSecs=$waitTimeInSeconds
fi

TeamViewerProcess=$(pgrep -lf TeamViewer)
TeamViewerService=$(launchctl list | grep com.teamviewer.service)
TeamViewerPath=$(find /Applications/*TeamViewer*/Contents/Helpers/Restarter)
# Would rather do nothing if I was unable to restart it using the helper service
if [ -s "$TeamViewerPath" ]; then
  echo "TeamViewer found! Proceeding with restart..."
  Attempt=0
  while [[ $Attempt -lt $_attempts ]]; do
    if [ -n "$TeamViewerProcess" ]; then
      echo "TeamViewer is currently running! Killing process..."
      pkill TeamViewer
    fi
    echo "Restarting TeamViewer using restarter in case the process kill didn't work..."
    for Restarter in $TeamViewerPath; do
      $Restarter
    done
    TeamViewerProcess=$(pgrep -lf TeamViewer)
    TeamViewerService=$(launchctl list | grep com.teamviewer.service)
    if [ -z "$TeamViewerService" ]; then
      echo "TeamViewer Service is not running!"
      launchctl load /Library/LaunchDaemons/com.teamviewer.teamviewer_service.plist
    fi
    # Sleeping before checking for success
    sleep "$_waitTimeInSecs"
    Attempt=$(($Attempt + 1))
    echo "Attempt $Attempt complete"
    TeamViewerService=$(launchctl list | grep com.teamviewer.service)
    if [ -n "$TeamViewerProcess" ] && [ -n "$TeamViewerService" ]; then
      echo "TeamViewer Service and Process appears to be ready for connections"
      exit 0
    else
      echo "Restart failed"
    fi
  done
  exit 1
else
  echo "TeamViewer not found!"
  exit 1
fi





