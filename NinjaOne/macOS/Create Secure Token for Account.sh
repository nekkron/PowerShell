#!/usr/bin/env bash
#
# Description: Grants secure token access to a Service Account. The account will be created as a service account if it doesn't exist. Service Accounts will not show up at the desktop login.
#
# Example: --newAccountUsername "MyTestUser" --newAccountPasswordCustomField "MySecurePasswordCustomField"
#   This will create the user "MyTestUser" as a service account if they do not already exist, then retrieve their password from the custom field.
#   Then, prompt the user for an administrator account to generate the secure token.
#
#   [Info] Found existing user account myAdmin.
#   2024-07-22 14:57:34.631 sysadminctl[2346:15733] - Done!
#   [Info] Successfully added SecureToken to myAdmin.
#
# Example: --newAccountUsername "MyTestUser23" --newAccountPasswordCustomField "MySecurePasswordCustomField" --optionalAuthenticationAccountUsername "cheart" --optionalAuthenticationAccountPasswordCustomField "myLocalAdminCustomField"
#   This will create the user "MyTestUser23" as a service account if they do not already exist, then retrieve their password from the custom field.
#   Then, it will generate the secure token using the admin username given and the value pulled from the authentication secure custom field.
#
#   [Info] Verified chickenheart has SecureToken.
#   [Info] Found existing user account MyTestUser23.
#   2024-07-22 15:06:23.476 sysadminctl[3939:26350] - Done!
#   [Info] Successfully added SecureToken to MyTestUser23.
#
# Preset Parameter: --newAccountUsername "ReplaceMeWithTheUserToGrantASecureToken"
#   Specify the username to grant secure token access to. This user will be created if they do not exist. 
#   This parameter is required and does not pull from a custom field.
#
# Preset Parameter: --newAccountPasswordCustomField "ReplaceMeWithTheNameOfASecureCustomField"
#   Specify the name of a secure custom field to retrieve the password used by the user specified in "--newAccountUsername". 
#   This parameter is required and retrieves its value from the secure custom field specified.
#
#  *** If the below parameters are not specified the end-user will be prompted for an admin account to use for the secure token creation. ***
#
# Preset Parameter: --optionalAuthenticationAccountUsername "ReplaceMeWithTheUsernameOfAnAdministrator"
#   Optionally specify the username of a local administrator you would like to use to grant the secure token.
#   This parameter is optional and its value is not pulled from a custom field.
#
# Preset Parameter: --optionalAuthenticationAccountPasswordCustomField "ReplaceMeWithTheNameOfASecureCustomField"
#   Optionally specify the name of a secure custom field to retrieve the password for the user specified in "--optionalAuthenticationAccountUsername".
#   This parameter is optional and retrieves its value from the secure custom field specified.
#
# Preset Parameter: --help
#   Displays help text.
#
# Release Notes: Updated help block

die() {
    local _ret="${2:-1}"
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    echo "$1" >&2
    exit "${_ret}"
}

begins_with_short_option() {
    local first_option all_short_options='upadvh'
    first_option="${1:0:1}"
    test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

GetCustomField() {
    customfieldName=$1
    dataPath=$(printenv | grep -i NINJA_DATA_PATH | awk -F = '{print $2}')
    value=""
    if [ -e "${dataPath}/ninjarmm-cli" ]; then
        value=$("${dataPath}"/ninjarmm-cli get "$customfieldName")
    else
        value=$(/Applications/NinjaRMMAgent/programdata/ninjarmm-cli get "$customfieldName")
    fi
    if [[ "${value}" == *"Unable to find the specified field"* ]]; then
        echo ""
        return 1
    else
        echo "$value"
    fi
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_newAccountUsername=
_arg_newAccountPasswordCustomField=
_arg_optionalAuthenticationAccountUsername=
_arg_optionalAuthenticationAccountPasswordCustomField=

print_help() {
  printf '\n\n%s\n\n' 'Usage: [--newAccountUsername|-u <arg>] [--newAccountPasswordCustomField|-p <arg>] [--optionalAuthenticationAccountUsername|-a <arg>] [--optionalAuthenticationAccountPasswordCustomField|-d <arg>] [--help|-h]'
  printf '%s\n' 'Preset Parameter: --newAccountUsername "ReplaceMeWithTheUserToGrantASecureToken"'
  printf '\t%s\n' "Specify the username to grant secure token access to. This user will be created if they do not exist. This parameter is required and does not pull from a custom field."
  printf '%s\n' 'Preset Parameter: --newAccountPasswordCustomField "ReplaceMeWithYourCustomFieldName"'
  printf '\t%s\n' "Specify the name of a secure custom field to retrieve the password used by the user specified in '--newAccountUsername'. This parameter is required and retrieves its value from the secure custom field specified."
  printf '%s\n' 'Preset Parameter: --optionalAuthenticationAccountUsername "ReplaceMeWithTheUsernameOfAnAdministrator"'
  printf '\t%s\n' "Optionally specify the username of a local administrator you would like to use to grant the secure token. This parameter is optional and its value is not pulled from a custom field."
  printf '%s\n' 'Preset Parameter: --optionalAuthenticationAccountPasswordCustomField "ReplaceMeWithTheNameOfASecureCustomField"'
  printf '\t%s\n' "Optionally specify the name of a secure custom field to retrieve the password for the user specified in '--optionalAuthenticationAccountUsername'. This parameter is optional and retrieves its value from the secure custom field specified."
  printf '\n%s\n' 'Preset Parameter: --help'
  printf '\t%s\n' "Displays this help menu."
}

parse_commandline() {
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        -u | --username | --newAccountUsername | --newaccountusername)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_newAccountUsername="$2"
            shift
            ;;
        --username=*)
            _arg_newAccountUsername="${_key##--newAccountUsername=}"
            ;;
        -p | --password | --newAccountPasswordCustomField | --newaccountpasswordcustomfield)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_newAccountPasswordCustomField="$2"
            shift
            ;;
        --newAccountPasswordCustomField=*)
            _arg_newAccountPasswordCustomField="${_key##--newAccountPasswordCustomField=}"
            ;;
        -a | --adminuser | --optionalAuthenticationAccountUsername | --optionalauthenticationaccountusername)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_optionalAuthenticationAccountUsername="$2"
            shift
            ;;
        --optionalAuthenticationAccountUsername=*)
            _arg_optionalAuthenticationAccountUsername="${_key##--optionalAuthenticationAccountUsername=}"
            ;;
        -d | --adminpassword | --optionalAuthenticationAccountPasswordCustomField | --optionalauthenticationaccountpasswordcustomfield)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_optionalAuthenticationAccountPasswordCustomField="$2"
            shift
            ;;
        --optionalauthenticationaccountpasswordcustomfield=*)
            _arg_optionalAuthenticationAccountPasswordCustomField="${_key##--optionalauthenticationaccountpasswordcustomfield=}"
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

parse_commandline "$@"

# Get Script Variables and override parameters
if [[ -n $(printenv | grep -i newAccountUsername | awk -F = '{print $2}') ]]; then
    _arg_newAccountUsername=$(printenv | grep -i newAccountUsername | awk -F = '{print $2}')
fi
if [[ -n $(printenv | grep -i newAccountPasswordCustomField | awk -F = '{print $2}') ]]; then
    # Get the password from the custom field
    if ! _arg_newAccountPasswordCustomField=$(GetCustomField "$(printenv | grep -i newAccountPasswordCustomField | awk -F = '{print $2}')"); then
        # Exit if the custom field is empty
        if [[ -z "${_arg_newAccountPasswordCustomField}" ]]; then
            echo "[Error] Secure Custom Field ($(printenv | grep -i newAccountPasswordCustomField | awk -F = '{print $2}')) was not found. Please check that the secure custom field contains a password."
            exit 1
        fi
        # Exit if the custom field is not found
        echo "[Error] Custom Field ($(printenv | grep -i newAccountPasswordCustomField | awk -F = '{print $2}')) was not found. Please check the custom field name."
        exit 1
    fi
fi
if [[ -n $(printenv | grep -i optionalAuthenticationAccountUsername | awk -F = '{print $2}') ]]; then
    _arg_optionalAuthenticationAccountUsername=$(printenv | grep -i optionalAuthenticationAccountUsername | awk -F = '{print $2}')
fi
if [[ -n $(printenv | grep -i optionalAuthenticationAccountPasswordCustomField | awk -F = '{print $2}') ]]; then
    # Get the password from the custom field
    if ! _arg_optionalAuthenticationAccountPasswordCustomField=$(GetCustomField "$(printenv | grep -i optionalAuthenticationAccountPasswordCustomField | awk -F = '{print $2}')"); then
        # Exit if the custom field is empty
        if [[ -z "${_arg_optionalAuthenticationAccountPasswordCustomField}" ]]; then
            echo "[Error] Secure Custom Field ($(printenv | grep -i optionalAuthenticationAccountPasswordCustomField | awk -F = '{print $2}')) was not found. Please check that the secure custom field contains a password."
            exit 1
        fi
        # Exit if the custom field is not found
        echo "[Error] Custom Field ($(printenv | grep -i optionalAuthenticationAccountPasswordCustomField | awk -F = '{print $2}')) was not found. Please check the custom field name."
        exit 1
    fi
fi

# If both username and password are empty
if [[ -z "${_arg_newAccountUsername}" ]]; then
    echo "[Error] User Name is required."
    if [[ -z "${_arg_newAccountPasswordCustomField}" ]]; then
        echo "[Error] Password is required, please set the password in the secure custom field."
    fi
    exit 1
fi

# If username is not empty and password is empty
if [[ -n "${_arg_newAccountUsername}" ]] && [[ -z "${_arg_newAccountPasswordCustomField}" ]]; then
    echo "[Error] Password is required, please set the password in the secure custom field."
    exit 1
fi

# If username is not empty and password is empty
if [[ -n "${_arg_optionalAuthenticationAccountUsername}" ]] && [[ -z "${_arg_optionalAuthenticationAccountPasswordCustomField}" ]]; then
    echo "[Error] Password is required, please set the password in the secure custom field."
    exit 1
fi

UserAccount=$_arg_newAccountUsername
UserPass=$_arg_newAccountPasswordCustomField
UserFullName="ServiceAccount"
secureTokenAdmin=$_arg_optionalAuthenticationAccountUsername
secureTokenAdminPass=$_arg_optionalAuthenticationAccountPasswordCustomField
macOSVersionMajor=$(sw_vers -productVersion | awk -F . '{print $1}')
macOSVersionMinor=$(sw_vers -productVersion | awk -F . '{print $2}')
macOSVersionBuild=$(sw_vers -productVersion | awk -F . '{print $3}')

# Check script prerequisites.

# Exits if macOS version predates the use of SecureToken functionality.
# Exit if macOS < 10.
if [ "$macOSVersionMajor" -lt 10 ]; then
    echo "[Warn] macOS version ${macOSVersionMajor} predates the use of SecureToken functionality, no action required."
    exit 0
# Exit if macOS 10 < 10.13.4.
elif [ "$macOSVersionMajor" -eq 10 ]; then
    if [ "$macOSVersionMinor" -lt 13 ]; then
        echo "[Warn] macOS version ${macOSVersionMajor}.${macOSVersionMinor} predates the use of SecureToken functionality, no action required."
        exit 0
    elif [ "$macOSVersionMinor" -eq 13 ] && [ "$macOSVersionBuild" -lt 4 ]; then
        echo "[Warn] macOS version ${macOSVersionMajor}.${macOSVersionMinor}.${macOSVersionBuild} predates the use of SecureToken functionality, no action required."
        exit 0
    fi
fi

# Exits if $UserAccount already has SecureToken.
if sysadminctl -secureTokenStatus "$UserAccount" 2>&1 | grep -q "ENABLED"; then
    echo "${UserAccount} already has a SecureToken. No action required."
    exit 0
fi

# Exits with error if $secureTokenAdmin does not have SecureToken
# (unless running macOS 10.15 or later, in which case exit with explanation).

if [ -n "$secureTokenAdmin" ]; then
    if sysadminctl -secureTokenStatus "$secureTokenAdmin" 2>&1 | grep -q "DISABLED"; then
        if [ "$macOSVersionMajor" -gt 10 ] || [ "$macOSVersionMajor" -eq 10 ] && [ "$macOSVersionMinor" -gt 14 ]; then
            echo "[Warn] Neither ${secureTokenAdmin} nor ${UserAccount} has a SecureToken, but in macOS 10.15 or later, a SecureToken is automatically granted to the first user to enable FileVault (if no other users have SecureToken), so this may not be necessary. Try enabling FileVault for ${UserAccount}. If that fails, see what other user on the system has SecureToken, and use its credentials to grant SecureToken to ${UserAccount}."
            exit 0
        else
            echo "[Error] ${secureTokenAdmin} does not have a valid SecureToken, unable to proceed. Please update to another admin user with SecureToken."
            exit 1
        fi
    else
        echo "[Info] Verified ${secureTokenAdmin} has SecureToken."
    fi
fi

# Creates a new user account.
create_user() {
    # Check if the user account exists
    if id "$1" >/dev/null 2>&1; then
        echo "[Info] Found existing user account $1."
    else
        echo "[Warn] Account $1 doesn't exist. Attempting to create..."
        # Create a new user
        dscl . -create /Users/"$1"
        # Add the display name of the User
        dscl . -create /Users/"$1" RealName "$3"
        # Replace password_here with your desired password to set the password for this user
        dscl . -passwd /Users/"$1" "$2"
        # Set the Unique ID for the New user. Replace with a number that is not already taken.
        LastID=$(dscl . -list /Users UniqueID | sort -nr -k 2 | head -1 | grep -oE '[0-9]+$')
        NextID=$((LastID + 1))
        dscl . -create /Users/"$1" UniqueID $NextID
        # Set the group ID for the user
        dscl . -create /Users/"$1" PrimaryGroupID 20
        # Append the User with admin privilege. If this line is not included the user will be set as standard user.
        # sudo dscl . -append /Groups/admin GroupMembership "$1"
        echo "[Info] Account $1 created."
    fi
}
# Adds SecureToken to target user.
securetoken_add() {
    if [ -n "$3" ]; then
        # Admin user name was given. Do not prompt the user.
        sysadminctl \
            -secureTokenOn "$1" \
            -password "$2" \
            -adminUser "$3" \
            -adminPassword "$4"
    else
        # Admin user name was not given. Prompt the local user.
        currentUser=$(stat -f%Su /dev/console)
        currentUserUID=$(id -u "$currentUser")
        launchctl asuser "$currentUserUID" sudo -iu "$currentUser" \
            sysadminctl \
            -secureTokenOn "$1" \
            -password "$2" \
            interactive
    fi
    # Verify successful SecureToken add.
    secureTokenCheck=$(sysadminctl -secureTokenStatus "${1}" 2>&1)
    if echo "$secureTokenCheck" | grep -q "DISABLED"; then
        echo "[Error] Failed to add SecureToken to ${1}. Please rerun policy; if issue persists, a manual SecureToken add will be required to continue."
        exit 126
    elif echo "$secureTokenCheck" | grep -q "ENABLED"; then
        echo "[Info] Successfully added SecureToken to ${1}."
    else
        echo "[Error] Unexpected result, unable to proceed. Please rerun policy; if issue persists, a manual SecureToken add will be required to continue."
        exit 1
    fi
}

# Create new user if it doesn't already exist.
create_user "$UserAccount" "$UserPass" "$UserFullName"
# Add SecureToken using provided credentials.
securetoken_add "$UserAccount" "$UserPass" "$secureTokenAdmin" "$secureTokenAdminPass"




