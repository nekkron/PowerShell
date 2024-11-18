#!/usr/bin/env bash

# Description: Enables a user account by changing its shell to /bin/bash and unlocking the account.
#
# Release Notes: Initial Release
#
# Below are all the valid parameters for this script.
#
# Preset Parameter: "ReplaceMeWithUsernameToEnable"
#   Username of the user you would like to enable.
#

# Help text function for when invalid input is encountered
print_help() {
  printf '\n### Below are all the valid parameters for this script. ###\n'
  printf '\nPreset Parameter: "ReplaceMeWithUsernameToEnable" \n'
  printf '\t%s\n' "Username of the user you would like to enable."
}

# Determines whether or not help text is nessessary and routes the output to stderr
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

_arg_userToEnable=

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
      if [[ -z $_arg_userToEnable ]]; then
        _arg_userToEnable=$1
      else
        _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1' but user '$_arg_userToEnable' was already specified!" 1
      fi
      ;;
    esac
    shift
  done
}

# Parse the command-line arguments passed to the script.
parse_commandline "$@"

if [[ -n $usernameToEnable ]]; then
  _arg_userToEnable="$usernameToEnable"
fi

# Check if the username to disable is empty and display an error if it is.
if [[ -z $_arg_userToEnable ]]; then
  _PRINT_HELP=yes die "[Error] The username of the user you would like to disable is required!'" 1
fi

# Validate the username to ensure it only contains lowercase letters, digits, hyphens, and underscores.
if [[ ! $_arg_userToEnable =~ ^[a-z0-9_-]+$ ]]; then
  _PRINT_HELP=no die "[Error] Invalid characters detected in '$_arg_userToEnable' usernames can only have a-z, 0-9 or -, _ characters!" 1
fi

# Search for the user in the /etc/passwd file.
passwdEntry=$(grep -w "$_arg_userToEnable" /etc/passwd)
if [[ -z $passwdEntry ]]; then
  _PRINT_HELP=no die "[Error] User '$_arg_userToEnable' does not exist." 1
fi

# Check to see if account is expired
accountExpiration=$(chage -l "$_arg_userToEnable" | grep "Account expires" | grep -v 'never' | cut -d ":" -f2 | xargs)
if [[ -n $accountExpiration ]]; then
  accountExpirationSeconds=$(date -d "$accountExpiration" +"%s")
  
  currentTime=$(date +"%s")
  # Warn if account is expired
  if [[ $accountExpirationSeconds -le $currentTime ]]; then
    echo "WARNING: The account for '$_arg_userToEnable' is currently expired as of '$accountExpiration'. You may need to set a new expiration date."
  fi
fi

noLogin=$(grep -w "$_arg_userToEnable" /etc/passwd | grep "nologin")
unlockedaccount=$(passwd -S "$_arg_userToEnable" | cut -f2 -d " " | grep -v "L")
if [[ -z $noLogin && -n $unlockedaccount ]]; then
  _PRINT_HELP=no die "[Error] User '$_arg_userToEnable' is already enabled." 1
fi

if [[ -f /bin/bash ]]; then
  preferredShell="/bin/bash"
elif [[ -f /bin/sh ]]; then
  preferredShell="/bin/sh"
fi

# Attempt to change the shell of the user to /bin/bash to enable login capabilities.
if ! usermod "$_arg_userToEnable" -s "$preferredShell"; then
  _PRINT_HELP=no die "[Error] Failed to change the shell for '$_arg_userToEnable' to '$preferredShell'." 1
fi

# Attempt to unlock the user account using usermod.
if ! usermod -U "$_arg_userToEnable"; then
  _PRINT_HELP=no die "[Error] Failed to unlock '$_arg_userToEnable' using usermod." 1
fi

# Check if the user has been successfully enabled by confirming 'nologin' is no longer set.
enabledUser=$(grep -w "$_arg_userToEnable" /etc/passwd | grep -v "nologin")
if [[ -n $enabledUser ]]; then
  echo "Successfully enabled '$_arg_userToEnable'."
else
  _PRINT_HELP=no die "[Error] Failed to enable '$_arg_userToEnable'." 1
fi





