#!/usr/bin/env bash

# Description: Disables a user account by changing its shell to /sbin/nologin and locking the account.
#
# Release Notes: Initial Release
#
# Below are all the valid parameters for this script.
#
# Preset Parameter: "ReplaceMeWithUsernameToDisable"
#   Username of the user you would like to disable.
#

# Help text function for when invalid input is encountered
print_help() {
  printf '\n### Below are all the valid parameters for this script. ###\n'
  printf '\nPreset Parameter: "ReplaceMeWithUsernameToDisable" \n'
  printf '\t%s\n' "Username of the user you would like to disable."
}

# Determines whether or not help text is nessessary and routes the output to stderr
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

_arg_userToDisable=

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
      if [[ -z $_arg_userToDisable ]]; then
        _arg_userToDisable=$1
      else
        _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1' but user '$_arg_userToDisable' was already specified!" 1
      fi
      ;;
    esac
    shift
  done
}

# Parse the command-line arguments passed to the script.
parse_commandline "$@"

if [[ -n $usernameToDisable ]]; then
  _arg_userToDisable="$usernameToDisable"
fi

# Check if the username to disable is empty and display an error if it is.
if [[ -z $_arg_userToDisable ]]; then
  _PRINT_HELP=yes die "[Error] The username of the user you would like to disable is required!'" 1
fi

# Validate the username to ensure it only contains lowercase letters, digits, hyphens, and underscores.
if [[ ! $_arg_userToDisable =~ ^[a-z0-9_-]+$ ]]; then
  _PRINT_HELP=no die "[Error] Invalid characters detected in '$_arg_userToDisable' usernames can only have a-z, 0-9 or -, _ characters!" 1
fi

# Search for the user in the /etc/passwd file and ensure the user account is not already set to 'nologin'.
passwdEntry=$(grep -w "$_arg_userToDisable" /etc/passwd)
if [[ -z $passwdEntry ]]; then
  _PRINT_HELP=no die "[Error] User '$_arg_userToDisable' does not exist." 1
fi

unlockedaccount=$(passwd -S "$_arg_userToDisable" | cut -f2 -d " " | grep -v "L")
nologin=$(grep -w "$_arg_userToDisable" /etc/passwd | cut -d ":" -f7 | grep "nologin")
if [[ -z $unlockedaccount && -n $nologin ]]; then
  _PRINT_HELP=no die "[Error] User '$_arg_userToDisable' is already disabled. $nologin" 1
fi

# Check if the 'sudo' command is available on the system.
sudoAvailable=$(command -v sudo)

# If 'sudo' is available, check if the specified user has sudo privileges and is not explicitly forbidden from using sudo.
if [[ -n $sudoAvailable ]]; then
  sudoAccess=$(sudo -l -U "$_arg_userToDisable" | grep -v "is not allowed to run sudo")
fi

# Initialize a flag to check for the availability of another administrative user.
anotherAdminAvaliable=false

# If the user to disable is 'root' or if they have sudo access, proceed to check for other admin users.
if [[ "$_arg_userToDisable" == "root" || -n $sudoAccess ]]; then
 # Fetch all user accounts with UID >= 1000 (typically regular users) and exclude the specified user and 'nobody'.
  allAccounts=$(cut -d ":" -f1,3 /etc/passwd | grep -v -w "$_arg_userToDisable" | grep -v "nobody" | awk -F ':' '$2 >= 1000 {print $1}')

  # If the user to disable is not 'root', add 'root' to the list of all accounts if it is enabled and not set to 'nologin'.
  if [[ ! "$_arg_userToDisable" == "root" ]]; then
    enabled=$(grep -w "root" /etc/passwd | grep -v "nologin")
    if [[ -n $enabled ]]; then
      allAccounts=$(echo "$allAccounts"; echo "root")
    fi
  fi

  # Iterate over each account to check if there are other admin users available.
  for account in $allAccounts; do
    # Skip checking accounts if 'sudo' is not available.
    if [[ -z $sudoAvailable ]]; then
      continue
    fi

    # Check if the current account has sudo access.
    sudoAccess=$(sudo -l -U "$account" | grep -v "is not allowed to run sudo")
    if [[ -z $sudoAccess ]]; then
      continue
    fi

    # Check if the current account is enabled (i.e., not set to 'nologin').
    accountEnabled=$(grep -w "$account" /etc/passwd | grep -v "nologin")
    if [[ -z $accountEnabled ]]; then
      continue
    fi

    # If an admin account is available and enabled, set the flag to true.
    anotherAdminAvaliable="true"
  done

  # If no other admin users are available, output an error and suggest creating another admin account.
  if [[ $anotherAdminAvaliable == "false" ]]; then
    _PRINT_HELP=no die "[Error] No other admins available. Please create another account to administer the system." 1
  fi
fi

# Attempt to change the shell of the user to /sbin/nologin to disable login capabilities.
if ! usermod "$_arg_userToDisable" -s /sbin/nologin; then
  _PRINT_HELP=no die "[Error] Failed to change the shell for '$_arg_userToDisable' to /sbin/nologin." 1
fi

# Attempt to lock the user account using usermod.
if ! usermod -L "$_arg_userToDisable"; then
  _PRINT_HELP=no die "[Error] Failed to lock '$_arg_userToDisable' using usermod." 1
fi

# Check if the user has been successfully disabled by confirming 'nologin' is set.
disabledUser=$(grep -w "$_arg_userToDisable" /etc/passwd | grep "nologin")
if [[ -n $disabledUser ]]; then
  echo "Successfully disabled '$_arg_userToDisable'."
else
  _PRINT_HELP=no die "[Error] Failed to disable '$_arg_userToDisable'." 1
fi





