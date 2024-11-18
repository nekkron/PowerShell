#!/usr/bin/env bash
#
# Description: Retrieves the ConnectWise ScreenConnect launch URL and saves it to a custom field (defaults to screenconnectURL). Requires the domain used for ScreenConnect and a Session Group the machine is a part of to successfully build the URL.
#
# Preset Parameter: --instanceId "ReplaceMeWithYourInstanceId"
#   The Instance ID for your instance of ScreenConnect. Used to differentiate between multiple installed ScreenConnect instances.
#   To get the instance ID, you can see it in the program name, e.g., connectwisecontrol-yourinstanceidhere.
#   It's also available in the ScreenConnect Admin Center (Administration > Advanced > Server Information).
#
# Preset Parameter: --screenconnectDomain "replace.me"
#   The domain used for your ScreenConnect instance.
#
# Preset Parameter: --sessionGroup "ReplaceMe"
#   A session group that contains all your machines (defaults to All Machines).
#
# Preset Parameter: --customField "ReplaceMeWithAnyMultilineCustomField"
#   The custom field you would like to store this information in.
#
# Preset Parameter: --help
#   Displays some help text.


# These are all our preset parameter defaults. You can set these = to something if you would prefer the script defaults to a certain parameter value.
_arg_instanceId=
_arg_screenconnectdomain=
_arg_sessiongroup="All Machines"
_arg_customfield="screenconnectURL"
_fieldValue=

# Help text function for when invalid input is encountered
print_help() {
    printf '\n\n%s\n\n' 'Usage: [--instanceId|-i <arg>] [--screenconnectDomain|-d <arg>] [--sessionGroup|-g <arg>] [--customField|-c <arg>] [--help|-h]'
    printf '%s\n' 'Preset Parameter: --instanceid "ReplaceWithYourInstanceID"'
    printf '\t%s\n' "Replace the text encased in quotes with your instance id. You can see the instance id in the ScreenConnect Admin Center (Administration > Advanced > Server Information). It's also usually present in the application name on already installed instance. e.g., connectwisecontrol-yourinstanceid."
    printf '\n%s\n' 'Preset Parameter: --screenconnectDomain "replace.me"'
    printf '\t%s' "Replace the text encased in quotes with the domain used for ConnectWise ScreenConnect. e.g. 'example.screenconnect.com'"
    printf '\n%s\n' 'Preset Parameter: --sessionGroup "Replace Me"'
    printf '\t%s' "Replace the text encased in quotes with the name of a Session Group that contains all of your machines e.g., 'All Machines'"
    printf '\n%s\n' 'Preset Parameter: --customField "replaceMe"'
    printf '\t%s' "Replace the text encased in quotes with the name of a custom field you'd like to store this information to (defaults to screenconnectUrl). E.g. 'screenconnectUrl'"
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

# Grabbing the parameters and parsing through them.
parse_commandline() {
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        --screenconnectdomain | --screenconnectDomain | --domain | -d)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_screenconnectdomain=$2
            shift
            ;;
        --screenconnectdomain=*)
            _arg_screenconnectdomain="${_key##--screenconnectdomain=}"
            ;;
        --instanceId | --instanceid | -i)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_instanceId=$2
            shift
            ;;
        --instanceid=*)
            _arg_instanceId="${_key##--instanceid=}"
            ;;
        --sessionGroup | --sessiongroup | -g)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_sessiongroup=$2
            shift
            ;;
        --sessiongroup=*)
            _arg_sessiongroup="${_key##--sessiongroup=}"
            ;;
        --customField | --customfield | -c)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_customfield=$2
            shift
            ;;
        --customfield=*)
            _arg_customfield="${_key##--customfield=}"
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

# Function to set a custom field
setCustomField() {
    echo "$_fieldValue" | /opt/NinjaRMMAgent/programdata/ninjarmm-cli set --stdin "$_arg_customfield"
}

export PATH=$PATH:/usr/sbin:/usr/bin

parse_commandline "$@"

# If script form is used, override command-line arguments
if [[ -n $screenconnectDomain ]]; then
    _arg_screenconnectdomain="$screenconnectDomain"
fi

if [[ -n $sessionGroup ]]; then
    _arg_sessiongroup="$sessionGroup"
fi

if [[ -n $instanceId ]]; then
    _arg_instanceId="$instanceId"
fi

if [[ -n $customFieldName ]]; then
    _arg_customfield="$customFieldName"
fi

# If we weren't given an instance id we should warn that this is not advised.
if [[ -z $_arg_instanceId ]]; then
    echo "WARNING: Without the instance id we will be unable to tell which ScreenConnect instance is yours (if multiple are installed). This could result in the wrong URL being displayed."
    echo "To get the instance id you can find it in ScreenConnect itself (Admin > Advanced > Server Information > Instance Identifier Fingerprint). It's also in the application name on every installed copy 'connectwisecontrol-yourinstanceidhere'"
fi

# --screenconnectDomain and --sessionGroup are required. We should also escape the session group given.
if [[ -z $_arg_screenconnectdomain || -z $_arg_sessiongroup ]]; then
    _PRINT_HELP=yes die "FATAL ERROR: Unable to build the URL without the Domain and Session Group!" 1
else
    _arg_sessiongroup=$(python3 -c "import urllib.parse;print(urllib.parse.quote('$_arg_sessiongroup'))")
fi

# Double check ScreenConnect is installed
installedPkg=$(ls /opt | grep "connectwisecontrol-$_arg_instanceId")
if [[ -z $installedPkg ]]; then
    _PRINT_HELP=no die "FATAL ERROR: It appears ConnectWise ScreenConnect is not installed!" 1
fi

# Lets start building some urls
for pkg in $installedPkg; do
    file="/opt/$pkg/ClientLaunchParameters.txt"
    id=$(grep -Eo 's=.{8}-.{4}-.{4}-.{4}-.{12}' "$file" | sed 's/s=//g' | sed 's/&e=Access//g')
    instanceid=${pkg//"connectwisecontrol-"/}
    # We shouldn't have multiple results but if we do we should warn the technician
    if [[ -n "$launchurls" ]]; then
        echo "WARNING: Multiple installed instances detected and no instance id was given. One of these urls will be incorrect."
        launchurls=$(
            printf '%s\n' "$launchurls"
            printf '%s\t' "$instanceid"
            printf '%s\n' "https://$_arg_screenconnectdomain/Host#Access/$_arg_sessiongroup//$id/Join"
        )
    else
        launchurls=$(
            printf '%s\t\t' "InstanceID"
            printf '%s\n' "LaunchURL"
            printf '%s\t' "$instanceid"
            printf '%s\t' "https://$_arg_screenconnectdomain/Host#Access/$_arg_sessiongroup//$id/Join"
        )
    fi
done

# Check that we were successful
if [[ -n $launchurls ]]; then
    echo "Launch URL(s) Created"
else
    _PRINT_HELP=no die "FATAL ERROR: Failed to create Launch URL(s)!" 1
fi

# Change how we output the results based on how many urls we received.
if [[ $(echo "$launchurls" | wc -l) -gt 2 ]]; then
    _fieldValue="$launchurls"
    echo "$_fieldValue"
else
    _fieldValue=$(echo "$launchurls" | tail -n 1 | awk '{print $2}')
    echo "$_fieldValue"
fi

echo "Setting Custom Field..."
setCustomField
exit 0





