#!/usr/bin/env bash
#
# Description: Alerts when there is an inactive/unused account that has not logged in for the specified number of days.
#
# Preset Parameter: --daysInactive "90"
#   Alert if account has been inactive for x days.
#
# Preset Parameter: --showDisabled
#   Includes disabled accounts in alert and report.
#
# Preset Parameter: --multilineField "ReplaceMeWithNameOfYourMultilineField"
#   Name of an optional multiline custom field to save the results to.
#
# Preset Parameter: --wysiwygField "ReplaceMeWithNameOfYourWYSIWYGField"
#   Name of an optional WYSIWYG custom field to save the results to.
#
# Preset Parameter: --help
#   Displays some help text.
#
# Release Notes: Initial Release
#

# These are all our preset parameter defaults. You can set these = to something if you would prefer the script defaults to a certain parameter value.
_arg_daysInactive=
_arg_showDisabled="off"
_arg_multilineField=
_arg_wysiwygField=

# Help text function for when invalid input is encountered
print_help() {
  printf '\n\n%s\n\n' 'Usage: --daysInactive|-d <arg> [--multilineField|-m <arg>] [--wysiwygField|-w <arg>] [--showDisabled] [--help|-h]'
  printf '%s\n' 'Preset Parameter: --daysInactive "90"'
  printf '\t%s\n' "Alert if account has been inactive for x days."
  printf '%s\n' 'Preset Parameter: --showDisabled'
  printf '\t%s\n' "Includes disabled accounts in alert and report."
  printf '%s\n' 'Preset Parameter: --multilineField "ReplaceMeWithNameOfYourMultilineField"'
  printf '\t%s\n' "Name of an optional multiline custom field to save the results to."
  printf '%s\n' 'Preset Parameter: --wysiwygField "ReplaceMeWithNameOfYourWYSIWYGField"'
  printf '\t%s\n' "Name of an optional WYSIWYG custom field to save the results to."
  printf '\n%s\n' 'Preset Parameter: --help'
  printf '\t%s\n' "Displays this help menu."
}

# Determines whether or not help text is necessary and routes the output to stderr
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

# Converts a string input into an HTML table format.
convertToHTMLTable() {
  local _arg_delimiter=" "
  local _arg_inputObject

  # Process command-line arguments for the function.
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --delimiter | -d)
      test $# -lt 2 && echo "[Error] Missing value for the required argument" >&2 && return 1
      _arg_delimiter=$2
      shift
      ;;
    --*)
      echo "[Error] Got an unexpected argument" >&2
      return 1
      ;;
    *)
      _arg_inputObject=$1
      ;;
    esac
    shift
  done

  # Handles missing input by checking stdin or returning an error.
  if [[ -z $_arg_inputObject ]]; then
    if [ -p /dev/stdin ]; then
      _arg_inputObject=$(cat)
    else
      echo "[Error] Missing input object to convert to table" >&2
      return 1
    fi
  fi

  local htmlTable="<table>\n"
  htmlTable+=$(printf '%b' "$_arg_inputObject" | head -n1 | awk -F "$_arg_delimiter" '{
    printf "<tr>"
    for (i=1; i<=NF; i+=1)
      { printf "<th>"$i"</th>" }
    printf "</tr>"
    }')
  htmlTable+="\n"
  htmlTable+=$(printf '%b' "$_arg_inputObject" | tail -n +2 | awk -F "$_arg_delimiter" '{
    printf "<tr>"
    for (i=1; i<=NF; i+=1)
      { printf "<td>"$i"</td>" }
    print "</tr>"
    }')
  htmlTable+="\n</table>"

  printf '%b' "$htmlTable" '\n'
}

# Parses command-line arguments and sets script variables accordingly.
parse_commandline() {
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --daysInactive | --daysinactive | --days | -d)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_daysInactive=$2
      shift
      ;;
    --daysInactive=*)
      _arg_daysInactive="${_key##--daysInactive=}"
      ;;
    --multilineField | --multilinefield | --multiline | -m)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_multilineField=$2
      shift
      ;;
    --multilineField=*)
      _arg_multilineField="${_key##--multilineField=}"
      ;;
    --wysiwygField | --wysiwygfield | --wysiwyg | -w)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_wysiwygField=$2
      shift
      ;;
    --wysiwygField=*)
      _arg_wysiwygField="${_key##--wysiwygField=}"
      ;;
    --showDisabled | --showdisabled)
      _arg_showDisabled="on"
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

# Parses the command-line arguments passed to the script.
parse_commandline "$@"

# If dynamic script variables are used replace the commandline arguments with them.
if [[ -n $daysInactive ]]; then
  _arg_daysInactive="$daysInactive"
fi

if [[ -n $includeDisabled && $includeDisabled == "true" ]]; then
  _arg_showDisabled="on"
fi

if [[ -n $multilineCustomFieldName ]]; then
  _arg_multilineField="$multilineCustomFieldName"
fi

if [[ -n $wysiwygCustomFieldName ]]; then
  _arg_wysiwygField="$wysiwygCustomFieldName"
fi

# Check if _arg_daysInactive contains any non-digit characters or is less than zero.
# If any of these conditions are true, display the help text and terminate with an error.
if [[ -z $_arg_daysInactive || $_arg_daysInactive =~ [^0-9]+ || $_arg_daysInactive -lt 0 ]]; then
  _PRINT_HELP=yes die "FATAL ERROR: Days Inactive of '$_arg_daysInactive' is invalid! Days Inactive must be a positive number." 1
fi

# Check if both _arg_multilineField and _arg_wysiwygField are set and not empty.
if [[ -n "$_arg_multilineField" && -n "$_arg_wysiwygField" ]]; then
  # Convert both field names to uppercase to check for equality.
  multiline=$(echo "$_arg_multilineField" | tr '[:lower:]' '[:upper:]')
  wysiwyg=$(echo "$_arg_wysiwygField" | tr '[:lower:]' '[:upper:]')

  # If the converted names are the same, it means both fields cannot be identical.
  # If they are, terminate the script with an error.
  if [[ "$multiline" == "$wysiwyg" ]]; then
    _PRINT_HELP=no die 'FATAL ERROR: Multline Field and WYSIWYG Field cannot be the same name. https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Fields-Configuration-Device-Role-Fields'
  fi
fi

# Retrieves the list of user accounts with UniqueIDs greater than 499 (typically these are all not service accounts) from the local user directory.
userAccounts=$(cut -d ":" -f1,3 /etc/passwd | grep -v "nobody" | awk -F ':' '$2 >= 1000 {print $1}')

# Sets up a header string for the table that will display user account information.
header=$(printf '%s' "Username" ';' "Password Last Set" ';' "Last Logon" ';' "Enabled")

# Initializes an empty string to store information about relevant user accounts.
relevantAccounts=

# Iterates over each user account retrieved earlier.
for userAccount in $userAccounts; do
  # Extracts the last login information for that user, filtering out unnecessary lines and formatting.
  lastLogin=$(last -RF1 "$userAccount" | grep -v "wtmp" | grep "\S" | tr -s " " | cut -f3-7 -d " ")

  # Converts the last login date to seconds since the epoch, for easier date comparison.
  if [[ -n $lastLogin ]]; then
    lastLogin=$(date -d "$lastLogin" +"%s")
  fi

  # Calculates the cutoff date in seconds since the epoch for inactivity comparison, based on the days inactive argument.
  if [[ $_arg_daysInactive -gt 0 ]]; then
    cutoffDate=$(date -d "${_arg_daysInactive} days ago" +"%s")
  fi

  # Retrieves the timestamp when the password was last set for the user account and converts it to a readable format.
  passwordLastSet=$(passwd -S "$userAccount" | cut -f3 -d " ")

  # Checks if the user account is part of the group that defines disabled accounts, setting the 'enabled' variable accordingly.
  unlockedaccount=$(passwd -S "$userAccount" | cut -f2 -d " " | grep -v "L")
  nologin=$(grep "$userAccount" /etc/passwd | cut -d ":" -f7 | grep "nologin")
  if [[ -n $unlockedaccount && -z $nologin ]]; then
    enabled="true"
  else
    enabled="false"
  fi

  # Checks if the account is inactive based on the last login date and cutoff date or if the account should be included regardless of its active status.
  if [[ $_arg_daysInactive == "0" || -z "$lastLogin" || $lastLogin -le $cutoffDate ]]; then
    # Formats the last login date or sets it to "Never" if the user has never logged in.
    if [[ -n $lastLogin ]]; then
      lastLogin=$(date -d "@$lastLogin")
    else
      lastLogin="Never"
    fi

    # Skips adding disabled accounts to the output if they should not be shown.
    if [[ $_arg_showDisabled == "off" && $enabled == "false" ]]; then
      continue
    fi

    # Appends the account information to the 'relevantAccounts' string if it meets the criteria.
    relevantAccounts+=$(printf '%s' '\n' "$userAccount" ';' "$passwordLastSet" ';' "$lastLogin" ';' "$enabled")
    foundInactiveAccounts="true"
  fi
done

# Checks if there are any inactive accounts found.
if [[ $foundInactiveAccounts == "true" ]]; then
  # Formats a nice table for easier viewing
  tableView="$header"
  tableView+=$(printf '%s' '\n' "--------" ';' "-----------------" ';' "----------" ';' "-------")
  tableView+="$relevantAccounts"
  tableView=$(printf '%b' "$tableView" | column -s ';' -t)

  # Output to the activity log
  echo ""
  echo 'WARNING: Inactive accounts detected!'
  echo ""
  printf '%b' "$tableView"
  echo ""
else
  # If no inactive accounts were found, outputs a simple message.
  echo "No inactive accounts detected."
fi

# Checks if there is a multiline custom field set and if any inactive accounts have been found.
if [[ -n $_arg_multilineField && $foundInactiveAccounts == "true" ]]; then
  echo ""
  echo "Attempting to set Custom Field '$_arg_multilineField'..."

  # Formats the relevantAccounts data for the multiline custom field.
  multilineValue=$(printf '%b' "$relevantAccounts" | grep "\S" | awk -F ";" '{ 
      print "Username: "$1
      print "Password Last Set: "$2
      print "Last Logon: "$3
      print "Enabled: "$4 
      print ""
  }')

  # Tries to set the multiline custom field using ninjarmm-cli and captures the output.
  if ! output=$(printf '%b' "$multilineValue" | /opt/NinjaRMMAgent/programdata/ninjarmm-cli set --stdin "$_arg_multilineField" 2>&1); then
    echo "[Error] $output" >&2
    EXITCODE=1
  else
    echo "Successfully set Custom Field '$_arg_multilineField'!"
  fi
fi

# Checks if there is a WYSIWYG custom field set and if any inactive accounts have been found.
if [[ -n $_arg_wysiwygField && $foundInactiveAccounts == "true" ]]; then
  echo ""
  echo "Attempting to set Custom Field '$_arg_wysiwygField'..."

  # Initializes an HTML formatted string with headers and account details.
  htmlObject="$header"
  htmlObject+="$relevantAccounts"

  # Converts the text data to an HTML table format.
  htmlObject=$(convertToHTMLTable --delimiter ';' "$htmlObject")

  # Tries to set the WYSIWYG custom field using ninjarmm-cli and captures the output.
  if ! output=$(echo "$htmlObject" | /opt/NinjaRMMAgent/programdata/ninjarmm-cli set --stdin "$_arg_wysiwygField" 2>&1); then
    echo "[Error] $output" >&2
    EXITCODE=1
  else
    echo "Successfully set Custom Field '$_arg_wysiwygField'!"
  fi
fi

# Checks if an error code is set and exits the script with that code.
if [[ -n $EXITCODE ]]; then
  exit "$EXITCODE"
fi




