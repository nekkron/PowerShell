#!/bin/bash

# Description: Change the hostname for a linux device (require's hostnamectl/systemd). Host file update expects the hostname to not be fully qualified.
#
# Release Notes: Initial Release
#
# Below are all the (case sensitive) valid parameters for this script.
# Only the new computer name / pretty name is required!
# Preset Parameter: "ReplaceWithNewComputerName"
# Preset Parameter: "ReplaceWithNewComputerName" --update-hostfile
#   --update-hostfile: Will replace the non-fqdn in /etc/hosts with the name given in the script (will not un-fullyqualify it)
# Preset Parameter: "ReplaceWithNewPrettyName" --prettyname-only
#   --prettyname-only: Set's the 'Pretty' name used by some applications.
# Preset Parameter: "ReplaceWithNewComputerName" --restart
#   --restart: Restart's the machine after updating the hostname. This is required for the new name to take immediate effect.

print_help() {
  printf '\n### Below are all the (case sensitive) valid parameters for this script. ###\n'
  printf '### Only the new computer name / pretty name is required! ###\n'
  printf 'Preset Parameter: "ReplaceWithNewComputerName" \n'
  printf 'Preset Parameter: "ReplaceWithNewComputerName" --update-hostfile \n'
  printf '\t%s\n' "--update-hostfile: Will replace the non-fqdn in /etc/hosts with the name given in the script (will not un-fullyqualify it)"
  printf 'Preset Parameter: "ReplaceWithNewPrettyName" --prettyname-only \n'
  printf '\t%s\n' "--prettyname-only: Set's the 'Pretty' name used by some applications."
  printf 'Preset Parameter: "ReplaceWithNewComputerName" --restart \n'
  printf '\t%s\n' "--restart: Restart's the machine after updating the hostname. This is required for the new name to take immediate effect."
}

# Determines whether or not help text is necessary and routes the output to stderr
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

# Commands required for this script
required_cmds="hostnamectl sed sleep echo"
for i in $required_cmds; do
  check=$(type -P "$i" 2>/dev/null)
  if [[ -z $check ]]; then
    _PRINT_HELP=yes die "FATAL ERROR: The command $i was not found and is required!" 1
  fi
done

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_prettyname_only="off"
_arg_update_hostfile="off"
_arg_restart="off"
typical="on"

# Grabbing the parameters and parsing through them.
parse_commandline() {
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --prettyname-only)
      typical="off"
      _arg_prettyname_only="on"
      ;;
    --update-hostfile)
      _arg_update_hostfile="on"
      ;;
    --restart)
      _arg_restart="on"
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

# Initializes parameter processing
parse_commandline "$@"

if [[ -n $setHostnameTo ]]; then
  _arg_name=$setHostnameTo
fi

if [[ -n $forceRestart && $forceRestart == "true" ]]; then
  _arg_restart="on"
fi

if [[ -n $action ]]; then
  if [[ $action == "Set Pretty Name" ]]; then
    _arg_prettyname_only="on"
    typical="off"
  fi

  if [[ $action == "Set Hostname and Update Host File" ]]; then
    _arg_update_hostfile="on"
  fi
fi

# Old hostname to use when updating the hosts file or checking success
old_name=$(hostname)

# Error out on invalid combo
if [[ $typical == "off" && $_arg_update_hostfile == "on" ]]; then
  _PRINT_HELP=yes die 'FATAL ERROR: --update-hostfile and --prettyname-only cannot be used together.' 1
fi

# If the new computer name isn't given error out
if [[ -z $_arg_name ]]; then
  _PRINT_HELP=yes die 'FATAL ERROR: No Computer Name was given! Please enter in the new name in the "Preset Parameter" box in Ninja! For Example "MyNewName".' 1
fi

# If the typical use case is given proceed with changing the hostname
if [[ $typical == "on" ]]; then

  pattern='^[a-zA-Z0-9]([a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?$'
  if [[ $_arg_name =~ [^a-zA-Z0-9-] ]] || [[ ! $_arg_name =~ $pattern ]]; then
    _PRINT_HELP=yes die 'FATAL ERROR: Hostname has invalid characters or spaces. Hostname can only contain A-Z characters, Digits or Hyphens.' 1
  fi

  # Converts the variables to lowercase prior to comparing them
  if [[ "${old_name,,}" == "${_arg_name,,}" ]]; then
    _PRINT_HELP=yes die "FATAL ERROR: The name $old_name is already set. Please enter a new name in the 'Preset Parameter' box in Ninja! For Example 'MyNewName'." 1
  fi

  # Sets the hostname
  hostnamectl set-hostname "$_arg_name"

  # Sleep for a few seconds prior to checking that the change worked
  sleep 7

  current_hostname=$(hostnamectl --static)

  # Checking if the hostname got set correctly
  if ! [[ "${current_hostname,,}" == "${_arg_name,,}" ]]; then
    _PRINT_HELP=no die "FATAL ERROR: Failed to set the hostname from $current_hostname to $_arg_name using hostnamectl is this a systemd system?" 1
  else
    echo "Successfully updated the hostname to '$current_hostname'!"
    printf "\nWARNING: The displayname in Ninja will need to be manually updated however the 'Device Name' section will update itself.\n\n"
  fi

  # If requested to update the hosts file update it
  if [[ $_arg_update_hostfile == "on" ]]; then
    echo "Replacing $old_name in /etc/hosts with $_arg_name (if $old_name is in /etc/hosts at all)"
    sed -i "s/$old_name/$_arg_name/" /etc/hosts
  fi
fi

# If requested to update the pretty name update it
if [[ $_arg_prettyname_only == "on" ]]; then
  current_hostname=$(hostnamectl --pretty)

  if [[ "${current_hostname,,}" == "${_arg_name,,}" ]]; then
    _PRINT_HELP=no die "FATAL ERROR: The pretty name $current_hostname is already set. Please enter a new name in the 'Preset Parameter' box in Ninja! For Example 'MyNewName'." 1
  fi

  hostnamectl set-hostname --pretty "$_arg_name"

  sleep 7

  current_hostname=$(hostnamectl --pretty)
  if ! [[ "${current_hostname,,}" == "${_arg_name,,}" ]]; then
    _PRINT_HELP=no die "FATAL ERROR: Failed to set the pretty name from $current_hostname to $_arg_name using hostnamectl is this a systemd system?" 1
  else
    echo "Successfully updated the pretty name to '$current_hostname'!"
  fi
fi

if [[ $_arg_restart == "on"  ]]; then
  echo "A restart was requested, restarting..."
  shutdown -r
else
  echo "Please restart this computer at your earliest convenience."
fi





