#!/usr/bin/env bash
#
# Description: Download and install ConnectWise ScreenConnect. This script supports automatic customization of the company name, device type, location, and other ScreenConnect fields.
#
# Preset Parameter: --screenconnectdomain "replace.me"
#   Replace the text encased in quotes to have the script build the download URL and then install ScreenConnect.
#
# Preset Parameter: --useOrgName
#   Modifies your URL to use the organization name in the "Company Name" Field in ScreenConnect.
#
# Preset Parameter: --useLocation
#   Modifies your URL to use the Location Name in the "Site" Field in ScreenConnect.
#
# Preset Parameter: --deviceType "REPLACEME"
#   Modifies your URL to fill in the "Device Type" field in ScreenConnect. (Either Workstation or Laptop).
#
# Preset Parameter: --Department "REPLACEME"
#   Modifies your URL to fill in the Department name with the text encased in quotes
#
# Preset Parameter: --skipSleep
#   By default, this script sleeps at a random interval (between 3 and 30 seconds) before downloading the installation file.
#   This option skips the sleep interval.
#
# Pre-set Parameter: --help
#   Displays some help text.

# These are all our preset parameter defaults. You can set these = to something if you would prefer the script automatically assumed a parameter is used.
_arg_screenconnectdomain=
# For parameters that don't have arguments "on" or "off" is used.
_arg_useOrgName="off"
_arg_useLocation="off"
_arg_department=
_arg_devicetype=
_arg_destfolder=/tmp
_arg_skipsleep="off"
_arg_installJava="off"

# Help text function for when invalid input is encountered
print_help() {
  printf '\n\n%s\n\n' 'Usage: [--screenconnectdomain <arg>] [--useOrgName] [--useLocation] [--deviceType <arg>] [--department <arg>] [--skipSleep] [-h|--help]'
  printf '\n%s\n' 'Preset Parameter: --screenconnectdomain "replace.me"'
  printf '\t%s' "Replace the text encased in quotes with the domain used for ConnectWise ScreenConnect. e.g. 'example.screenconnect.com'"
  printf '\n%s\n' 'Preset Parameter: --useOrgName'
  printf '\t%s\n' "Modifies your URL in order to fill in the 'Company Name' field in ScreenConnect with the Organization Name."
  printf '\n%s\n' 'Preset Parameter: --useLocation'
  printf '\t%s\n' "Modifies your URL to fill in the 'Site Name' field in ScreenConnect with the device's location as specified in Ninja."
  printf '\n%s\n' 'Preset Parameter: --department "YourDesiredDepartmentName"'
  printf '\t%s\n' "Modifies your URL in order to fill in the 'Department' field in ScreenConnect with the text encased in quotes."
  printf '\n%s\n' 'Preset Parameter: --devicetype "YourDesiredDeviceType"'
  printf '\t%s\n' "Modifies your URL in order to fill in the 'Device Type' field in ScreenConnect with the text encased in quotes."
  printf '\n%s\n' 'Preset Parameter: --skipSleep'
  printf '\t%s\n' "By default this script will sleep at a random interval between 3 and 60 seconds prior to download. Use this option to skip this behavior."
  printf '\n%s\n' 'Preset Parameter: --installJava'
  printf '\t%s\n' "Install Java if it's not already present."
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
    --deviceType | --devicetype)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_devicetype="$2"
      shift
      ;;
    --devicetype=*)
      _arg_devicetype="${_key##--devicetype=}"
      ;;
    --department | --Department)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_department="$2"
      shift
      ;;
    --department=*)
      _arg_department="${_key##--department=}"
      ;;
    --installJava)
      _arg_installJava="on"
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

# If script form is used, override command-line arguments

if [[ -n $screenconnectDomainName ]]; then
  _arg_screenconnectdomain="$screenconnectDomainName"
fi

if [[ -n $installJavaIfMissing && $installJavaIfMissing == "true" ]]; then
  _arg_installJava="on"
fi

if [[ -n $instanceId ]]; then
  _arg_instanceId="$instanceId"
fi

if [[ -n $useNinjaOrganizationName && $useNinjaOrganizationName == "true" ]]; then
  _arg_useOrgName="on"
fi

if [[ -n $useNinjaLocationName && $useNinjaLocationName == "true" ]]; then
  _arg_useLocation="on"
fi

if [[ -n $deviceType ]]; then
  _arg_devicetype="$deviceType"
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
      sleepTime=$((3 + RANDOM % 30))
      echo "Sleeping for $sleepTime seconds."
      sleep $sleepTime
    fi

    echo "Download Attempt $i"
    wget -q -O "$_arg_destfolder/$filename" "$url"

    file=$_arg_destfolder/$filename
    if [[ -f $file ]]; then
      echo 'Download was successful!'
      i=4
    else
      echo 'Attempt Failed!'
      ((i += 1))
    fi
  done
}

# Check if deb or rpm distro
usesDeb=$(command -v dpkg)
usesRpm=$(command -v rpm)

if [[ -z $usesDeb && -z $usesRpm ]]; then
  _PRINT_HELP=no die "FATAL ERROR: rpm or dpkg cannot be found. ConnectWise ScreenConnect cannot be installed on this system. https://screenconnect.connectwise.com/blog/remote-support-access/remote-desktop-linux" 1
fi

# If we're not given a download method error out
if [[ -z $_arg_screenconnectdomain ]]; then
  _PRINT_HELP=yes die "FATAL ERROR: A download url or the domain you use for ScreenConnect is required to install ScreenConnect." 1
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

# Setting filename depending on if its a Debian package or a Redhat package.
if [[ -n $usesDeb ]]; then
  filename="ClientSetup.deb"
else
  filename="ClientSetup.rpm"
fi

# If a file already exists with that name remove it.
if [[ -f "$_arg_destfolder/$filename" ]]; then
  rm "$_arg_destfolder/$filename"
fi

# Start the build process
echo "Building URL..."
usesPython2=$(command -v python2)
usesPython3=$(command -v python3)

if [[ -z $usesPython2 && -z $usesPython3 ]]; then
  _PRINT_HELP=no die "FATAL ERROR: python is required for this script to function!"
fi

# For anything we put in the url we'll need to escape it as wget won't do this conversion for us.
encodeURL() {
  local toEncode=$1
  local encodedURL

  if [[ -n $usesPython3 ]]; then
    encodedURL=$(python3 -c "import urllib.parse;print(urllib.parse.quote('$toEncode'))")
  else
    encodedURL=$(python2 -c "import urllib;print urllib.quote('$toEncode')")
  fi
  echo "$encodedURL"
}

companyName=$(encodeURL "$NINJA_COMPANY_NAME")
baseURL="https://$_arg_screenconnectdomain/Bin/$companyName.$filename?e=Access&y=Guest"

# If the technician specified --useOrgName (or any other switch/flag) we set it to "on" when we parse the parameters
if [[ $_arg_useOrgName == "on" ]]; then
  orgName=$(encodeURL "$NINJA_ORGANIZATION_NAME")
  baseURL="$baseURL&c=$orgName"
else
  # If they decided to not use that field we just leave it blank so ScreenConnect will skip over it.
  baseURL="$baseURL&c="
fi

if [[ $_arg_useLocation == "on" ]]; then
  location=$(encodeURL "$NINJA_LOCATION_NAME")
  baseURL="$baseURL&c=$location"
else
  baseURL="$baseURL&c="
fi

if [[ -n $_arg_department ]]; then
  _arg_department=$(encodeURL "$_arg_department")
  baseURL="$baseURL&c=$_arg_department"
else
  baseURL="$baseURL&c="
fi

if [[ -n $_arg_devicetype ]]; then
  _arg_devicetype=$(encodeURL "$_arg_devicetype")
  baseURL="$baseURL&c=$_arg_devicetype&c=&c=&c=&c="
else
  baseURL="$baseURL&c=&c=&c=&c=&c="
fi

url="$baseURL"
echo "URL Built: $url"

# At this point we should have everything setup for us to be able to download the file.
downloadFile

# Lets check if the download was a success
file="$_arg_destfolder/$filename"
if [[ ! -f $file ]]; then
  _PRINT_HELP=no die "FATAL ERROR: The Installation File has failed to download please try again." 1
fi

# Grabs a list of all installed packages and then filters it by connectwisecontrol-yourinstanceid
if [[ -n $usesDeb ]]; then
  packageName=$(dpkg --info $file | grep "Package: " | sed 's/Package: //g')
  installedPkg=$(dpkg -l | grep "$packageName")
else
  packageName=$(rpm -qp $file --info | grep "Name" | sed 's/Name *: //g')
  installedPkg=$(rpm -q "$packageName" | grep -v "installed")
fi

if [[ -n $installedPkg ]]; then
  echo "ConnectWise ScreenConnect is already installed!"
  exit 0
else
  echo "ConnectWise ScreenConnect is not installed. Installing..."
fi

# Checking for dependencies and if they're not installed install them
javaIsInstalled=$(java -version 2>&1 | grep Runtime)
if [[ -z $javaIsInstalled && $_arg_installJava == "on" ]]; then
  echo "Java is not installed. Java is required to install ConnectWise ScreenConnect. Attempting to install automatically."
  if [[ -n $usesDeb ]]; then
    if apt-get update; then
      echo "Updated apt package repos successfully. Installing default-jre..."
      if apt-get install -y default-jre; then
        echo "Default jre installed successfully!"
      else
        rm "$file"
        _PRINT_HELP=no die "FATAL ERROR: Failed to install default-jre using apt-get! We recommend fixing this prior to attempting to install ScreenConnect." 1
      fi
    else
      rm "$file"
      _PRINT_HELP=no die "FATAL ERROR: Failed to update package repositories using apt-get update! We recommend fixing this prior to attempting to install ScreenConnect." 1
    fi
  else
    usesDnf=$(command -v dnf)
    if [[ -n $usesDnf ]]; then
      if dnf install java -y; then
        echo "Installed latest jre successfully!"
      else
        rm "$file"
        _PRINT_HELP=no die "FATAL ERROR: Failed to install latest jre using dnf! We recommend fixing this prior to attempting to install ScreenConnect." 1
      fi
    else
      if yum install java -y; then
        echo "Installed latest jre successfully!"
      else
        rm "$file"
        _PRINT_HELP=no die "FATAL ERROR: Failed to install latest jre using yum! We recommend fixing this prior to attempting to install ScreenConnect." 1
      fi
    fi 
  fi
elif [[ -z $javaIsInstalled ]]; then
  rm "$file"
  _PRINT_HELP=no die "FATAL ERROR: Please check the box 'Install Java If Missing' in order to have this script install Java as it is required."
else
  echo "Java is installed!"
fi

# Start installing
echo "Installing application..."
if [[ -n $usesDeb ]]; then
  if dpkg -i "$file"; then
    echo "Exit Code: $?"
    echo "ConnectWise ScreenConnect Installed Successfully!"
    rm "$file"
    exit 0
  else
    echo "Exit Code: $?"
    rm "$file"
    _PRINT_HELP=no die "FATAL ERROR: The Installation has failed!" 1
  fi
else
  if rpm -i "$file"; then
    echo "Exit Code: $?"
    echo "ConnectWise ScreenConnect Installed Successfully!"
    rm "$file"
    exit 0
  else
    echo "Exit Code: $?"
    rm "$file"
    _PRINT_HELP=no die "FATAL ERROR: The Installation has failed!" 1
  fi
fi





