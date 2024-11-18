#!/usr/bin/env bash
#
# Description: Download and Install ConnectWise ScreenConnect. Supports automatic customization of the company name, device type, location, and other ScreenConnect fields.
#
# Preset Parameter: --screenconnectdomain "replace.me"
#   Replace the text encased in quotes to have the script build the download URL and then install ScreenConnect.
#
# Preset Parameter: --useOrgName
#   Modifies your URL to use the organization name in the "Company Name" field in ScreenConnect.
#
# Preset Parameter: --useLocation
#   Modifies your URL to use the Location Name in the "Site" field in ScreenConnect.
#
# Preset Parameter: --useDeviceType
#   Modifies your URL to fill in the "Device Type" field in ScreenConnect. (Either Workstation or Laptop).
#
# Preset Parameter: --Department "REPLACEME"
#   Modifies your URL to fill in the Department name with the text encased in quotes.
#
# Preset Parameter: --skipSleep
#   By default, this script sleeps at a random interval (between 3 and 30 seconds) before downloading the installation file.
#   This option skips the random sleep interval.
#
# Preset Parameter: --help
#   Displays some help text.

# These are all our preset parameter defaults. You can set these = to something if you would prefer the script automatically assumed a parameter is used.
_arg_instanceId=
_arg_screenconnectdomain=
# For parameters that don't have arguments "on" or "off" is used.
_arg_useOrgName="off"
_arg_useLocation="off"
_arg_useDeviceType="off"
_arg_department=
_arg_filename="ClientSetup.pkg"
_arg_destfolder=/tmp
_arg_skipsleep="off"

# Help text function for when invalid input is encountered
print_help() {
  printf '\n\n%s\n\n' 'Usage: [--screenconnectdomain <arg>] [--useOrgName] [--useLocation] [--useDeviceType] [--department <arg>] [--skipSleep] [-h|--help]'
  printf '\n%s\n' 'Preset Parameter: --screenconnectdomain "replace.me"'
  printf '\t%s\n' "Replace the text encased in quotes with the domain used for ConnectWise ScreenConnect. ex. 'example.screenconnect.com'"
  printf '\n%s\n' 'Preset Parameter: --useOrgName'
  printf '\t%s\n' "Builds the url so the 'Company Name' field in ScreenConnect is filled in with the Organization Name."
  printf '\n%s\n' 'Preset Parameter: --useLocation'
  printf '\t%s\n' "Builds the url so the 'Site Name' field in ScreenConnect is filled in with the Location the device is in in Ninja."
  printf '\n%s\n' 'Preset Parameter: --useDeviceType'
  printf '\t%s\n' "Builds the url so the 'Device Type' field in ScreenConnect is filled in with the detected device type (Laptop or Workstation)."
  printf '\n%s\n' 'Preset Parameter: --department "YourDesiredDepartmentName"'
  printf '\t%s\n' "Builds the url so the 'Department' field in ScreenConnect is filled in with the text encased in quotes."
  printf '\n%s\n' 'Preset Parameter: --skipSleep'
  printf '\t%s\n' "By default this script will sleep at a random interval between 3 and 60 seconds prior to download. Use this option to skip this behavior."
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
    --screenconnectdomain | --domain)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_screenconnectdomain=$2
      shift
      ;;
    --screenconnectdomain=*)
      _arg_screenconnectdomain="${_key##--screenconnectdomain=}"
      ;;
    --useOrgName | --useorgname | --orgname)
      _arg_useOrgName="on"
      ;;
    --useLocation | --useOrgLocation | --uselocation | --location)
      _arg_useLocation="on"
      ;;
    --useDeviceType | --usedevicetype | --devicetype)
      _arg_useDeviceType="on"
      ;;
    --department | --Department)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_department="$2"
      shift
      ;;
    --department=*)
      _arg_department="${_key##--department=}"
      ;;
    --skipsleep | --skipSleep)
      _arg_skipsleep="on"
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

parse_commandline "$@"

# If dynamic script variables are used override the comand line arguments

if [[ -n $screenconnectDomainName ]]; then
  _arg_screenconnectdomain="$screenconnectDomainName"
fi

if [[ -n $useNinjaOrganizationName && $useNinjaOrganizationName == "true" ]]; then
  _arg_useOrgName="on"
fi

if [[ -n $useNinjaLocationName && $useNinjaLocationName == "true" ]]; then
  _arg_useLocation="on"
fi

if [[ -n $addDeviceType && $addDeviceType == "true" ]]; then
  _arg_useDeviceType="on"
fi

if [[ -n $department ]]; then
  _arg_department="$department"
fi

if [[ -n $skipSleep && $skipSleep == "true" ]]; then
  _arg_skipsleep="on"
fi

# This function will download our file when we're ready for that.
downloadFile() {
  i=1
  while [[ $i -lt 4 ]]; do
    if [[ ! $_arg_skipsleep == "on" ]]; then
      sleep_time=$((3 + RANDOM % 60))
      echo "Sleeping for $sleep_time seconds..."
      sleep $sleep_time
    fi

    echo "Download Attempt $i"
    curl -L "$url" -o "$_arg_destfolder/$_arg_filename" -s -f

    file=$_arg_destfolder/$_arg_filename
    if [[ -f $file ]]; then
      echo 'Download was successful!'
      i=4
    else
      echo 'Attempt Failed!'
      ((i += 1))
    fi
  done
}

# If we're not given a download method error out
if [[ -z $_arg_screenconnectdomain ]]; then
  _PRINT_HELP=yes die "FATAL ERROR: The domain you use for ScreenConnect is required to install ScreenConnect." 1
fi

pattern='^http(.?)://(.*)'
if [[ $_arg_screenconnectdomain =~ $pattern ]]; then
  _arg_screenconnectdomain=${_arg_screenconnectdomain//http*:\/\//}
  echo "You accidentally included http with the domain. Using '$_arg_screenconnectdomain' instead."
fi

# If the destination folder doesn't exist create it.
if [[ ! -d $_arg_destfolder ]]; then
  mkdir "$_arg_destfolder"
fi

# If a file already exists with that name remove it.
if [[ -f "$_arg_destfolder/$_arg_filename" ]]; then
  rm "$_arg_destfolder/$_arg_filename"
fi

# Start the build process
echo "Building URL..."
# For anything we put in the url we'll need to escape it as curl won't do this conversion for us.
companyName=$(echo "$NINJA_COMPANY_NAME" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"')
baseURL="https://$_arg_screenconnectdomain/Bin/$companyName.ClientSetup.pkg?e=Access&y=Guest"

# If the technician specified --useOrgName (or any other switch/flag) we set it to "on" when we parse the parameters
if [[ $_arg_useOrgName == "on" ]]; then
  orgName=$(echo "$NINJA_ORGANIZATION_NAME" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"')
  baseURL="$baseURL&c=$orgName"
else
  # If they decided to not use that field we just leave it blank so ScreenConnect will skip over it.
  baseURL="$baseURL&c="
fi

if [[ $_arg_useLocation == "on" ]]; then
  location=$(echo "$NINJA_LOCATION_NAME" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"')
  baseURL="$baseURL&c=$location"
else
  baseURL="$baseURL&c="
fi

if [[ -n $_arg_department ]]; then
  _arg_department=$(echo "$_arg_department" | perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"')
  baseURL="$baseURL&c=$_arg_department"
else
  baseURL="$baseURL&c="
fi

# Getting whether or not the device is a laptop is a bit tricky. Fortunately only MacBooks are laptops (everything else is too old to worry about e.g. PowerBooks).
if [[ $_arg_useDeviceType == "on" ]]; then
  modelName=$(system_profiler SPHardwareDataType -detaillevel mini | grep "Model Name" | sed 's/Model Name://' | xargs)
  modelIdentifier=$(system_profiler SPHardwareDataType -detaillevel mini | grep "Model Identifier" | sed 's/Model Identifier://' | xargs)

  if [[ $modelName == *"MacBook"* || $modelIdentifier == *"MacBook"* ]]; then
    deviceType="Laptop"
  else
    deviceType="Workstation"
  fi

  baseURL="$baseURL&c=$deviceType&c=&c=&c=&c="
else
  baseURL="$baseURL&c=&c=&c=&c=&c="
fi

url="$baseURL"
echo "URL Built: $url"

# At this point we should have everything setup for us to be able to download the file.
downloadFile

# Lets check if the download was a success
file="$_arg_destfolder/$_arg_filename"
if [[ ! -f $file ]]; then
  _PRINT_HELP=no die "FATAL ERROR: The Installation File has failed to download please try again." 1
fi

# Analyze .pkg file and grab application name
pkgutil --expand $file "$_arg_destfolder/ScreenConnect"
pkgname=$(grep -Eo "connectwisecontrol-.*" "$_arg_destfolder/ScreenConnect/PackageInfo" | sed 's/".*//')

# Grabs a list of all installed packages and then filters it by connectwisecontrol-yourinstanceid
if [[ -z $pkgname ]]; then
  echo "WARNING: Failed to get package name from .Pkg file. Checking if ANY ScreenConnect instance is installed."
  installedPkg=$(pkgutil --pkgs | grep "connectwisecontrol-")
else
  installedPkg=$(pkgutil --pkgs | grep "$pkgname")
fi

if [[ -n $installedPkg ]]; then
  echo "Connectwise ScreenConnect is already installed!"
  exit 0
else
  echo "ConnectWise ScreenConnect is not installed. Installing..."
fi

# Start installing
echo "Installing application..."
if installer -pkg "$file" -target /; then
  echo "Exit Code: $?"
  echo "Connectwise ScreenConnect Installed Successfully!"
  rm "$file"
  exit 0
else
  echo "Exit Code: $?"
  rm "$file"
  _PRINT_HELP=no die "FATAL ERROR: The Installation has failed!" 1
fi




