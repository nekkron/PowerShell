#!/usr/bin/env bash
#
# Description: Shows the current secure token status for all accounts on the system.
#
# Preset Parameter: --showDisabledAccounts
#   Shows disabled accounts in the report.
#
# Preset Parameter: --multilineCustomFieldName "ReplaceMeWithYourCustomFieldName"
#   Specify the name of an optional multiline custom field to save the results.
#
# Preset Parameter: --help
#   Displays help text.
#
# Release Notes: Initial release.

# Initialize the script arguments
_arg_showDisabledAccounts="off"
_arg_multilineCustomFieldName=

# Function to print the help message
print_help() {
  printf '\n\n%s\n\n' 'Usage: [--showDisabledAccounts|-s] [--multilineCustomFieldName|-m <arg>] [--help|-h]'
  printf '%s\n' 'Preset Parameter: --showDisabledAccounts'
  printf '\t%s\n' "Show disabled accounts in the report."
  printf '%s\n' 'Preset Parameter: --multilineCustomFieldName "ReplaceMeWithYourCustomFieldName"'
  printf '\t%s\n' "Specify the name of an optional multiline custom field to save the results."
  printf '\n%s\n' 'Preset Parameter: --help'
  printf '\t%s\n' "Displays this help menu."
}

# Function to display an error message and optionally print the help message
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

# Function to parse the command-line arguments
parse_commandline() {
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --showDisabledAccounts | --showdisabledaccounts | --showDisabled | -s)
      _arg_showDisabledAccounts="on"
      ;;
    --multilineCustomFieldName | --multilineField | --multiline | --customField | -m)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_multilineCustomFieldName="$2"
      shift
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

# Parse the command-line arguments
parse_commandline "$@"

# If the script form is used, override the commandline arguments with the form information.
if [[ -n $multilineCustomFieldName ]]; then
  _arg_multilineCustomFieldName="$multilineCustomFieldName"
fi

if [[ -n $includeDisabledUsers && $includeDisabledUsers == "true" ]]; then
  _arg_showDisabledAccounts="on"
fi

# Get the list of user accounts with UniqueID greater than 499 (non-system accounts)
userAccounts=$(dscl . -list /Users UniqueID | awk '$2 > 499 {print $1}')
secureTokenAccounts=

# If no user accounts are found, display an error and exit
if [[ -z $userAccounts ]]; then
  _PRINT_HELP=no die "[Error] No user accounts were found." 1
fi

# Iterate through each user account to check secure token status and other attributes
for userAccount in $userAccounts; do
  # Check if the secure token is disabled
  secureTokenStatus=$(sysadminctl -secureTokenStatus "$userAccount" 2>&1 | grep "is DISABLED")

  if [[ -n $secureTokenStatus ]]; then
    secureTokenStatus="Disabled"
  else
    secureTokenStatus="Enabled"
  fi

  # Check if user account is disabled
  pwpolicy=$(dseditgroup -o checkmember -u "$userAccount" com.apple.access_disabled | grep "no $userAccount")
  authenticationAuthority=$(dscl . -read "/Users/$userAccount" AuthenticationAuthority | grep "DisabledUser")
  if [[ -n $pwpolicy && -z $authenticationAuthority ]]; then
    enabled="true"
  else
    enabled="false"
  fi

  # Skip disabled accounts if the argument to show disabled accounts is off
  if [[ $_arg_showDisabledAccounts == "off" && $enabled == "false" ]]; then
    continue
  fi

  # If the secure token status is disabled enable the alert.
  if [[ $secureTokenStatus == "Disabled" ]]; then
    accountsMissingSecureTokenFound="true"
  fi

  # Append the user account details to the secure token accounts string
  secureTokenAccounts+=$(printf '%s' '\n' "$userAccount" ';' "$secureTokenStatus" ';' "$enabled")
done

# If there are accounts missing a secure token, display an alert
if [[ $accountsMissingSecureTokenFound == "true" ]]; then
  echo ""
  echo "[Alert] There are accounts that do not currently have a secure token."
  echo ""
fi

# Prepare the header and table view for displaying the results
header=$(printf '%s' "Username" ';' "Secure Token" ';' "Enabled")

tableView="$header"
tableView+=$(printf '%s' '\n' "--------" ';' "------------" ';' "-------")
tableView+="$secureTokenAccounts"
tableView=$(printf '%b' "$tableView" | sed 's/$/\n/' | column -s ';' -t)
# Output the table view to the activity log.
printf '%b' "$tableView"
echo ""
echo ""

# If a multiline custom field name is specified, attempt to set the custom field
if [[ -n $_arg_multilineCustomFieldName ]]; then
  echo ""
  echo "Attempting to set Custom Field '$_arg_multilineCustomFieldName'..."

  # Formats the Secure Token data for the multiline custom field.
  multilineValue=$(printf '%b' "$secureTokenAccounts" | grep "\S" | awk -F ";" '{ 
      print "Username: "$1
      print "Secure Token: "$2
      print "Enabled: "$3 
      print ""
  }')

  # Try to set the multiline custom field using ninjarmm-cli and capture the output
  if ! output=$(printf '%b' "$multilineValue" | /Applications/NinjaRMMAgent/programdata/ninjarmm-cli set --stdin "$_arg_multilineCustomFieldName" 2>&1); then
    echo "[Error] $output" >&2
    EXITCODE=1
  else
    echo "Successfully set Custom Field '$_arg_multilineCustomFieldName'!"
  fi
fi

# Checks if an error code is set and exits the script with that code.
if [[ -n $EXITCODE ]]; then
  exit "$EXITCODE"
fi



