#!/bin/bash

# Description: Change's both the mac's computername (friendly name seen in Finder) and local hostname (what you would see in the network). Please note the hostname will update upon the next dhcp renewal.
#
# Release Notes: Initial Release
#
# Below are all the valid parameters for this script only the new computer name is required!
# Preset Parameter: "ReplaceWithNewComputerName" --localhostname-only --computername-only
# --localhostname-only: Sets only the LocalHostName (The one you see when scanning the network)
# --computername-only: Sets only the user-friendly ComputerName (The one you see in finder)

# Help text function for when invalid input is encountered
print_help() {
  printf '\n### Below are all the (case sensitive) valid parameters for this script only the new computer name is required! ###\n'
  printf '\nPreset Parameter: "ReplaceWithNewComputerName" --localhostname-only --computername-only \n'
  printf '\t%s\n' "--localhostname-only: Sets only the LocalHostName (The one you see when scanning the network)"
  printf '\t%s\n' "--computername-only: Sets only the user-friendly ComputerName (The one you see in finder)"
}

# Determines whether or not help text is nessessary and routes the output to stderr
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_localhostname_only="off"
_arg_computername_only="off"
_typical="on"

# Grabbing the parameters and parsing through them.
parse_commandline() {
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --localhostname-only)
      _arg_localhostname_only="on"
      _typical="off"
      ;;
    --computername-only)
      _arg_computername_only="on"
      _typical="off"
      ;;
    --*)
      _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
      ;;
    *)
      if [[ -z $_arg_name ]]; then
        _arg_name=$1
      else
        _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1' but the new computername '$_arg_name' was already specified" 1
      fi
      ;;
    esac
    shift
  done
}

# Dtermines if the hostname is valid.
validate_localhostname() {
  pattern=" |'"
  if [[ $1 =~ $pattern ]]; then
    _PRINT_HELP=yes die "FATAL ERROR: Local Hostnames DO NOT support spaces or most special characters - is okay!" 1
  fi

  if [[ ${#1} -gt 253 ]]; then
    _PRINT_HELP=yes die "FATAL ERROR: Local Hostnames cannot be more than 253 characters long!" 1
  fi

  if [[ ${#1} -gt 15 ]]; then
    printf "\nWARNING: Hostname is longer than 15 characters!"
    printf "\tWhile technically osx will let you set a hostname of basically any length you may experience issues if the name is absurdly long."
  fi
}

# Initializes parameter processing
parse_commandline "$@"

if [[ -n $newName ]]; then
  _arg_name=$newName
fi

if [[ -n $action ]]; then
  if [[ $action == "Change Local Host Name Only" ]]; then
    _arg_localhostname_only="on"
    _typical="off"
  fi
  if [[ $action == "Change Computer Name Only" ]]; then
    _arg_computername_only="on"
    _typical="off"
  fi
fi

# If they didn't give me a new name I should error out
if [[ -z $_arg_name ]]; then
  _PRINT_HELP=yes die 'FATAL ERROR: No Computer Name was given! Please enter in the new name in the "Preset Parameter" box in Ninja! For Example "MyNewName".' 1
fi

# If they didn't specify which of the 2 names to change we'll change both
if [[ $_typical == "on" ]]; then
  validate_localhostname "$_arg_name"
  echo "Changing both LocalHostName and ComputerName to $_arg_name..."

  # This actually changes the name
  scutil --set LocalHostName "$_arg_name"
  # Sleeps for a few seconds as scutil sometimes takes a second or two for the new name to appear
  sleep 7
  # Tests that the change was successful
  new_localhostname=$(scutil --get LocalHostName)
  if [[ $new_localhostname != "$_arg_name" ]]; then
    _PRINT_HELP=no die "FATAL ERROR: failed to set local hostname to $_arg_name." 1
  else
    echo "Success!"
  fi

  # Changes the friendly name
  scutil --set ComputerName "$_arg_name"
  # Sleeps for a few seconds as we're gonna test immediately afterwards
  sleep 7
  # Test that we were successful
  new_computername=$(scutil --get ComputerName)
  if [[ $new_localhostname != "$_arg_name" ]]; then
    _PRINT_HELP=no die "FATAL ERROR: failed to set Computer Name to $_arg_name." 1
  else
    echo "Success!"
  fi

fi

# This is the same as above just localhostname only
if [[ $_arg_localhostname_only == "on" ]]; then
  validate_localhostname "$_arg_name"
  echo "Changing LocalHostName to $_arg_name..."
  scutil --set LocalHostName "$_arg_name"
  sleep 7
  new_localhostname=$(scutil --get LocalHostName)
  if [[ $new_localhostname != "$_arg_name" ]]; then
    _PRINT_HELP=no die "FATAL ERROR: failed to set local hostname to $_arg_name." 1
  else
    echo "Success!"
  fi
fi

# Same as above just friendly name only
if [[ $_arg_computername_only == "on" ]]; then
  echo "Changing ComputerName to $_arg_name..."
  scutil --set ComputerName "$_arg_name"
  sleep 7
  new_computername=$(scutil --get ComputerName)
  if [[ $new_computername != "$_arg_name" ]]; then
    _PRINT_HELP=no die "FATAL ERROR: failed to set Computer Name to $_arg_name." 1
  else
    echo "Success"
  fi
fi

# Flushes the dns cache so that the mac is prepared to start handing out its new name
dscacheutil -flushcache

# Warns the user that it will take some time for the new name to show up
printf "\nWARNING: The devicename in Ninja will likely display the old name until the next dhcp renewal."
printf "\n\tOSX determines its devicename\hostname from the dhcp or dns server."
printf "\n\tTypically these services will update their records upon receiving a new DHCP request from the device."




