#!/usr/bin/env bash
#
# Description: Updates the /etc/issue file and adds it to the SSH banner. If Gnome is installed, ensure a banner is displayed above login and disable automatic login.
#
# Preset Parameter: --bannerText "ReplaceMeWithYourMessage"
#   The message you would like to display inside the logon banner.
#
# Preset Parameter: --clear
#   Clears /etc/issue, Gnome banner text, and reverts sshd config.
#
# Preset Parameter: --forceRestart
#   Schedules a restart 60 seconds from now so that the login banner may take immediate effect.'
#
# Release Notes: Initial Release

# Initialize variables
_arg_bannertext=
_arg_clear="off"
_arg_forceRestart="off"

# Function to display help message
print_help() {
  printf '\n\n%s\n\n' 'Usage: --bannerText <arg> [--clear|-c] [--forceRestart|-r] [--help|-h]'
  printf '%s\n' 'Preset Parameter: --bannerText "ReplaceMeWithYourMessage"'
  printf '\t%s\n' 'The message you would like to display inside the logon banner.'
  printf '%s\n' 'Preset Parameter: --clear'
  printf '\t%s\n' 'Clears /etc/issue, Gnome banner text, and reverts sshd config.' 
  printf '%s\n' 'Preset Parameter: --forceRestart'
  printf '\t%s\n' 'Schedules a restart 60 seconds from now so that the login banner may take immediate effect.'
  printf '%s\n' 'Preset Parameter: --help'
  printf '\t%s\n' "Displays this help menu."
}

# Function to display error message and exit
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

# Function to parse command line arguments
parse_commandline() {
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --bannerText | --bannertext | -b)
      test $# -lt 2 && die "Missing value for argument '$_key'." 1
      _arg_bannertext=$2
      shift
      ;;
    --bannerText=*)
      _arg_bannertext="${_key##--bannerText=}"
      ;;
    --clear | -c)
      _arg_clear="on"
      ;;
    --forceRestart | --forcerestart | -r)
      _arg_forceRestart="on"
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

# Parse command line arguments
parse_commandline "$@"

# Check if script variables are set and replace command line arguments with the script variables.
if [[ -n $bannerText ]]; then
  _arg_bannertext="$bannerText"
fi
if [[ -n $forceRestart && $forceRestart == "true" ]]; then
  _arg_forceRestart="on"
fi
if [[ -n $clearAndRemoveConfigChanges && $clearAndRemoveConfigChanges == "true" ]]; then
  _arg_clear="on"
fi

# Trim leading and trailing whitespace from _arg_bannertext
if [[ -n $_arg_bannertext ]]; then
  _arg_bannertext=$(echo "$_arg_bannertext" | sed 's/^[ \t]*//' | sed 's/\ *$//g')
fi

# Check if banner text is required and not provided
if [[ -z $_arg_bannertext && $_arg_clear != "on" ]]; then
  echo "[Error] banner text is required!" >&2
  exit 1
fi

# Check if both setting and clearing banner text are requested
if [[ -n $_arg_bannertext && $_arg_clear == "on" ]]; then
  echo "[Error] Cannot set and clear banner text at the same time. Please do not fill in the banner text box when the clear and remove checkbox is checked." >&2
  exit 1
fi

# Display the current /etc/issue content
echo "### Modifying /etc/issue From ###"
cat '/etc/issue'
echo ""

# Display the new banner text
echo "### To ###"
echo "$_arg_bannertext"
echo ""

# Update /etc/issue with the new banner text
echo "$_arg_bannertext" >/etc/issue

# Extract the Banner configuration from the sshd_config file, ignoring commented lines
bannerFile=$(grep "Banner" /etc/ssh/sshd_config | grep -v "#" | xargs | cut -f2 -d' ')

# Check conditions to back up the sshd_config file
if [[ -f /etc/ssh/sshd_config && (((-z $bannerFile || $bannerFile != "/etc/issue" ) && $_arg_clear == "off") || (-n $bannerFile && $_arg_clear == "on")) ]]; then
  # Get the current timestamp
  timestamp=$(date +%s)
  # Create a backup file name
  backupFile="sshd_config.$timestamp.back"

  echo "Backing up sshd config to /etc/ssh/$backupFile"

  # Attempt to copy sshd_config to the backup file
  if ! cp "/etc/ssh/sshd_config" "/etc/ssh/$backupFile"; then
    echo "[Error] Unable to backup sshd config!" >&2
    EXITCODE=1
    # Set the flag to indicate backup failure
    failedBackup="true"
  fi
fi

# Create or update the Banner configuration based on conditions
if [[ -f /etc/ssh/sshd_config && -z $failedBackup && $_arg_clear == "off" && -z $bannerFile ]]; then
  # If Banner is not set and clear is off, add the Banner configuration
  if echo "    Banner /etc/issue" >>"/etc/ssh/sshd_config"; then
    echo "Successfully created sshd login banner."
  else
    echo "[Error] Unable to create sshd login banner!" >&2
    EXITCODE=1
  fi
elif [[ -f /etc/ssh/sshd_config && -z $failedBackup && $_arg_clear == "off" && $bannerFile != "/etc/issue" ]]; then
  # If Banner is set to a different value and clear is off, update the Banner configuration
  if sed -i 's/Banner.*/Banner \/etc\/issue/' /etc/ssh/sshd_config &>/dev/null; then
    echo "Successfully updated sshd login banner."
  else
    echo "[Error] Failed to update sshd login banner!" >&2
    EXITCODE=1
  fi
elif [[ -f /etc/ssh/sshd_config && -z $failedBackup && $_arg_clear == "on" && -n $bannerFile ]]; then
   # If Banner is set and clear is on, comment out the Banner configuration
  if sed -i 's/Banner/#Banner/' /etc/ssh/sshd_config &>/dev/null; then
    echo "Successfully removed sshd login banner."
  else
    echo "[Error] Failed to remove sshd login banner!" >&2
    EXITCODE=1
  fi
fi

# Check for Gnome and KDE session files to determine if they are installed
for f in /usr/bin/*session; do
  if echo "$f" | grep "gnome" &>/dev/null; then
    gnomeInstalled="true"
  fi

  if echo "$f" | grep "plasma" &>/dev/null; then
    kdeInstalled="true"
  fi
done

# Add login banner for Gnome if Gnome is installed and clear is off
if [[ -n $gnomeInstalled && $_arg_clear == "off" ]]; then
  echo ""
  echo "Gnome installation detected."

  automaticLogins=$(grep "AutomaticLoginEnable" /etc/gdm3/custom.conf | grep -v "#" | grep -i "true")
  if [[ -n $automaticLogins ]]; then
    echo ""
    echo "Automatic logins detected. Disabling automatic login."
    
    # Get the current timestamp
    timestamp=$(date +%s)
    # Create a backup file name
    backupFile="custom.conf.$timestamp.back"

    echo "Backing up gdm3 custom.conf config to /etc/gdm3/$backupFile"

    sed -i "s/AutomaticLoginEnable.*/AutomaticLoginEnable=False/g" /etc/gdm3/custom.conf &>/dev/null
    echo ""
  fi

  echo "Adding login banner for gui logins."

  # Create the dconf profile for gdm if it doesn't exist
  if [[ ! -f '/etc/dconf/profile/gdm' ]]; then
    {
      echo "user-db:user"
      echo "system-db:gdm"
      echo "file-db:/usr/share/gdm/greeter-dconf-defaults"
    } >>'/etc/dconf/profile/gdm'
  fi

  # Create the dconf database directory for gdm if it doesn't exist
  if [[ ! -d '/etc/dconf/db/gdm.d' ]]; then
    mkdir /etc/dconf/db/gdm.d
  fi

  # Escape single quotes in _arg_bannertext for use in the GUI banner text
  guiBannerText=${_arg_bannertext//\'/\\\'}

  # Check if the Gnome banner configuration file does not exist
  if [[ ! -f '/etc/dconf/db/gdm.d/01-banner-message' ]]; then
    # Create the banner configuration file with the specified settings
    {
      echo "[org/gnome/login-screen]"
      echo "banner-message-enable=true"
      echo "banner-message-text='$guiBannerText'"
    } >>'/etc/dconf/db/gdm.d/01-banner-message'
  else
    # Escape single quotes again for updating existing configuration
    guiBannerText=${_arg_bannertext//\'/\\\\\'}
    # Enable the banner message and update the text in the existing configuration file
    sed -i "s/banner-message-enable=false/banner-message-enable=true/" '/etc/dconf/db/gdm.d/01-banner-message' &>/dev/null
    sed -i "s/banner-message-text=.*/banner-message-text='$guiBannerText'/" '/etc/dconf/db/gdm.d/01-banner-message' &>/dev/null
  fi

  # Apply the changes to the dconf database
  if dconf update; then
    echo "Successfully added graphical login banner."
  else
    echo "Failed to add graphical login banner" >&2
    exit 1
  fi
# Check if Gnome is installed and clear argument is set to "on"
elif [[ -n $gnomeInstalled && $_arg_clear == "on" ]]; then
  echo ""
  echo "Gnome installation detected. Removing login banner for gui logins (if present)."

  # If the Gnome banner configuration file exists, disable the banner message
  if [[ -f '/etc/dconf/db/gdm.d/01-banner-message' ]]; then
    sed -i "s/banner-message-enable=true/banner-message-enable=false/" '/etc/dconf/db/gdm.d/01-banner-message' &>/dev/null
  fi

  # Apply the changes to the dconf database
  if dconf update; then
    echo "Successfully removed graphical login banner."
  else
    echo "Failed to remove graphical login banner" >&2
    exit 1
  fi
fi

# Check if KDE is installed
if [[ -n $kdeInstalled ]]; then
  echo "WARNING: KDE install detected. Unable to set login banner for KDE gui."
fi

# Checks if an error code is set and exits the script with that code.
if [[ -n $EXITCODE ]]; then
  exit "$EXITCODE"
fi

# If forceRestart argument is set to "on", schedule a system restart in 1 minute
if [[ $_arg_forceRestart == "on" ]]; then
  echo ""
  shutdown -r "+1"
fi




