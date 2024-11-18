#!/usr/bin/env bash
#
# Description: Set Power and Sleep settings. It can adjust either the plugged-in or battery settings if requested. Please note, not all devices support all options.
#
# Preset Parameter: --powerSourceSetting "Both"
#   Should these changes apply when the device is plugged in, on battery, or both?
#
# Preset Parameter: --screenTimeout "10"
#		Time in minutes to wait before turning off the screen. (0 to disable)
#
# Preset Parameter: --sleepTimeout "10"
#		Time in minutes to wait before the computer sleeps. (0 to disable)
#
# Preset Parameter: --diskTimeout "10"
#		Time in minutes for the disk to spin down when idle. (0 to disable)
#
# Preset Parameter: --powernap "Disable"
#		When the Mac goes to sleep, Power Nap activates periodically to update information such as Mail, Calendar, and other iCloud events.
#
# Preset Parameter: --terminalKeepAlive "Enable"
#		Prevents the system from going to sleep when a terminal session (like a remote login) is active, only allowing sleep if the session has been idle for too long.
#
# Preset Parameter: --dimOnBattery "Enable"
#		Slightly turn down the display brightness when switching to battery power.
#
# Preset Parameter: --lowPowerMode "Enable"
#		Reduces energy consumption by lowering the system performance and brightness, stopping background processes, and adjusting system settings to extend battery life.
#
# Preset Parameter: --tcpKeepAlive "Enable"
#		Ensures that a network connection remains active by periodically sending keepalive packets to prevent the connection from being dropped due to inactivity.
#
# Preset Parameter: --wakeOnNetwork "Only on Power Adapter"
#		Wake when an Ethernet magic packet is received.
#
# Preset Parameter: --help
#		Displays some help text.
#
# Release Notes: Initial Release

# Define initial argument variables with default values
_arg_powerSourceSetting="Both"
_arg_screenTimeout=
_arg_sleepTimeout=
_arg_diskTimeout=
_arg_powernap=
_arg_terminalKeepAlive=
_arg_dimOnBattery=
_arg_wakeOneNetwork=
_arg_lowPowerMode=
_arg_tcpKeepAlive=

# Function to display help menu
print_help() {
  printf '\n\n%s\n\n' 'Usage: [--powerSourceSetting|-p <arg>] [--someSwitch|-s] [--help|-h]'
  printf '%s\n' 'Preset Parameter: --powerSourceSetting "Both"'
  printf '\t%s\n' "Should these changes apply when the device is plugged in, on battery, or both?"
  printf '%s\n' 'Preset Parameter: --screenTimeout "10"'
  printf '\t%s\n' "Time in minutes to wait before turning off the screen. (0 to disable)"
  printf '%s\n' 'Preset Parameter: --sleepTimeout "10"'
  printf '\t%s\n' "Time in minutes to wait before the computer sleeps. (0 to disable)"
  printf '%s\n' 'Preset Parameter: --diskTimeout "10"'
  printf '\t%s\n' "Time in minutes for the disk to spin down when idle. (0 to disable)"
  printf '%s\n' 'Preset Parameter: --powernap "Disable"'
  printf '\t%s\n' "When the Mac goes to sleep, Power Nap activates periodically to update information such as Mail, Calendar and other iCloud events."
  printf '%s\n' 'Preset Parameter: --terminalKeepAlive "Enable"'
  printf '\t%s\n' "Prevents the system from going to sleep when a terminal session (like a remote login) is active, only allowing sleep if the session has been idle for too long."
  printf '%s\n' 'Preset Parameter: --dimOnBattery "Enable"'
  printf '\t%s\n' "Slightly turn down the display brightness when switching to battery power."
  printf '%s\n' 'Preset Parameter: --lowPowerMode "Enable"'
  printf '\t%s\n' "Reduces energy consumption by lowering the system performance and brightness, stopping background processes, and adjusting system settings to extend battery life."
  printf '%s\n' 'Preset Parameter: --tcpKeepAlive "Enable"'
  printf '\t%s\n' "Ensures that a network connection remains active by periodically sending keepalive packets to prevent the connection from being dropped due to inactivity."
  printf '%s\n' 'Preset Parameter: --wakeOnNetwork "Only on Power Adapter"'
  printf '\t%s\n' "Wake when an Ethernet magic packet is received."
  printf '\n%s\n' 'Preset Parameter: --help'
  printf '\t%s\n' "Displays this help menu."
}

# Function to display error message and exit the script
die() {
  local _ret="${2:-1}"
  echo "$1" >&2
  test "${_PRINT_HELP:-no}" = yes && print_help >&2
  exit "${_ret}"
}

# Function to parse command-line arguments
parse_commandline() {
  while test $# -gt 0; do
    _key="$1"
    case "$_key" in
    --powerSourceSetting | --powersourcesetting | --powersource)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_powerSourceSetting=$2
      shift
      ;;
    --powerSourceSetting=*)
      _arg_powerSourceSetting="${_key##--powerSourceSetting=}"
      ;;
    --screenTimeout | --screentimeout | --screen)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_screenTimeout=$2
      shift
      ;;
    --screenTimeout=*)
      _arg_screenTimeout="${_key##--screenTimeout=}"
      ;;
    --sleepTimeout | --sleeptimeout | --sleep)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_sleepTimeout=$2
      shift
      ;;
    --sleepTimeout=*)
      _arg_sleepTimeout="${_key##--sleepTimeout=}"
      ;;
    --diskTimeout | --disktimeout | --disk)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_diskTimeout=$2
      shift
      ;;
    --diskTimeout=*)
      _arg_diskTimeout="${_key##--diskTimeout=}"
      ;;
    --powernap | --powerNap)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_powernap=$2
      shift
      ;;
    --powernap=*)
      _arg_powernap="${_key##--powernap=}"
      ;;
    --terminalKeepAlive | --terminalkeepawake | --terminalkeepalive)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_terminalKeepAlive=$2
      shift
      ;;
    --terminalKeepAlive=*)
      _arg_terminalKeepAlive="${_key##--terminalKeepAlive=}"
      ;;
    --dimOnBattery | --dimonbattery | --dim)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_dimOnBattery=$2
      shift
      ;;
    --dimOnBattery=*)
      _arg_dimOnBattery="${_key##--dimOnBattery=}"
      ;;
    --lowPowerMode | --lowpowermode | --lpm)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_lowPowerMode=$2
      shift
      ;;
    --lowPowerMode=*)
      _arg_lowPowerMode="${_key##--lowPowerMode=}"
      ;;
    --tcpKeepAlive | --tcpkeepalive | --tcp)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_tcpKeepAlive=$2
      shift
      ;;
    --tcpKeepAlive=*)
      _arg_tcpKeepAlive="${_key##--tcpKeepAlive=}"
      ;;
    --wakeOnNetwork | --wakeonnetwork | --won)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_wakeOneNetwork=$2
      shift
      ;;
    --wakeOnNetwork=*)
      _arg_wakeOneNetwork="${_key##--wakeOnNetwork=}"
      ;;
    --help | -h)
      _PRINT_HELP=yes die 0
      ;;
    *)
      _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'"1
      ;;
    esac
    shift
  done
}

# Function to set power settings
set_powersetting() {
  while test $# -gt 0; do
    local _key="$1"
    case "$_key" in
    --setting)
      test $# -lt 2 && die "Missing value for the argument '$_key'."1
      local _setting=$2
      shift
      ;;
    --value)
      test $# -lt 2 && die "Missing value for the argument '$_key'."1
      local _value=$2
      shift
      ;;
    --errorMessage)
      test $# -lt 2 && die "Missing value for the argument '$_key'."1
      local _errorMessage=$2
      shift
      ;;
    --successMessage)
      test $# -lt 2 && die "Missing value for the argument '$_key'."1
      local _successMessage=$2
      shift
      ;;
    --singleSetting)
      local _singleSetting="on"
      ;;
    *)
      _PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'"1
      ;;
    esac
    shift
  done

  # Check if required parameters are provided
  if [[ -z $_setting || -z $_value || -z $_errorMessage || -z $_successMessage ]]; then
    echo "[Error] One of the required parameters was not provided." >&2
    exit 1
  fi

  # Apply setting for "Plugged In" if applicable
  if [[ ($_arg_powerSourceSetting == "Both" || $_arg_powerSourceSetting == "Plugged In") && $_singleSetting != "on" ]]; then
    pmset -c "$_setting" "$_value"
  fi

  # Apply setting for "On Battery" if applicable
  if [[ ($_arg_powerSourceSetting == "Both" || $_arg_powerSourceSetting == "On Battery") && $_singleSetting != "on" && -n $batteryOptions ]]; then
    pmset -b "$_setting" "$_value"
  fi

  # Apply setting for all power sources if single setting is enabled
  if [[ $_singleSetting == "on" ]]; then
    pmset -a "$_setting" "$_value"
  fi

  # Retrieve and verify the new value of the setting
  newvalue=$(pmset -g custom | grep -w "$_setting")
  if [[ -z $batteryOptions && $_singleSetting != "on" ]]; then
    newvalueAC=$(echo "$newvalue" | xargs | cut -f2 -d' ')
  elif [[ $_singleSetting != "on" ]]; then
    newvalueDC=$(echo "$newvalue" | xargs | cut -f2 -d' ')
    newvalueAC=$(echo "$newvalue" | xargs | cut -f4 -d' ')
  else
    newvalue=$(echo "$newvalue" | xargs | cut -f2 -d' ')
  fi

  # Warn if unable to verify the setting change
  if [[ -z $newvalue ]]; then
    echo "Warning: Unable to verify setting change for '$_setting'."
  fi

  # Check and report the new value for "Plugged In" setting
  if [[ ($_arg_powerSourceSetting == "Both" || $_arg_powerSourceSetting == "Plugged In") && $_singleSetting != "on" && -n $newvalue ]]; then
    if [[ $newvalueAC != "$_value" ]]; then
      echo "[Error] $_errorMessage on the 'Plugged In' Policy." >&2
      EXITCODE=1
    else
      echo "$_successMessage on the 'Plugged In' Policy."
    fi
  fi

  # Check and report the new value for "On Battery" setting
  if [[ ($_arg_powerSourceSetting == "Both" || $_arg_powerSourceSetting == "On Battery") && $_singleSetting != "on" && -n $newvalue && -n $batteryOptions ]]; then
    if [[ $newvalueDC != "$_value" ]]; then
      echo "[Error] $_errorMessage on the 'Battery' Policy." >&2
      EXITCODE=1
    else
      echo "$_successMessage on the 'Battery' Policy."
    fi
  fi

  # Check and report the new value for single setting
  if [[ $_singleSetting == "on" && -n $newvalue ]]; then
    if [[ $newvalue != "$_value" ]]; then
      echo "[Error] $_errorMessage" >&2
      EXITCODE=1
    else
      echo "$_successMessage"
    fi
  fi

  echo ""
}

# Call the function to parse command-line arguments
parse_commandline "$@"

# If script form values are set, replace the command-line parameters with these values
if [[ -n $powerSourceSetting ]]; then
  _arg_powerSourceSetting="$powerSourceSetting"
fi
if [[ -n $screenTimeoutInMinutes ]]; then
  _arg_screenTimeout="$screenTimeoutInMinutes"
fi
if [[ -n $sleepTimeoutInMinutes ]]; then
  _arg_sleepTimeout="$sleepTimeoutInMinutes"
fi
if [[ -n $diskTimeoutInMinutes ]]; then
  _arg_diskTimeout="$diskTimeoutInMinutes"
fi
if [[ -n $powerNap ]]; then
  _arg_powernap="$powerNap"
fi
if [[ -n $terminalKeepAlive ]]; then
  _arg_terminalKeepAlive="$terminalKeepAlive"
fi
if [[ -n $dimTheDisplayOnBattery ]]; then
  _arg_dimOnBattery="$dimTheDisplayOnBattery"
fi
if [[ -n $lowPowerMode ]]; then
  _arg_lowPowerMode="$lowPowerMode"
fi
if [[ -n $tcpKeepAlive ]]; then
  _arg_tcpKeepAlive="$tcpKeepAlive"
fi
if [[ -n $wakeOnNetwork ]]; then
  _arg_wakeOneNetwork="$wakeOnNetwork"
fi

# Check if the device has battery options available
batteryOptions=$(pmset -g custom | grep "Battery Power")

# Validate the power source setting
if [[ -z $_arg_powerSourceSetting || ($_arg_powerSourceSetting != "Both" && $_arg_powerSourceSetting != "Plugged In" && $_arg_powerSourceSetting != "On Battery") ]]; then
  echo "[Error] An invalid power source was given '$_arg_powerSourceSetting'. The only valid options are 'Both', 'Plugged In', and 'On Battery'." >&2
  exit 1
fi

if [[ -z $_arg_screenTimeout && -z $_arg_sleepTimeout && -z $_arg_diskTimeout && -z $_arg_powernap && -z $_arg_terminalKeepAlive && -z $_arg_dimOnBattery && -z $_arg_wakeOneNetwork && -z $_arg_lowPowerMode && -z $_arg_tcpKeepAlive ]]; then
  PRINT_HELP=yes die "[Error] No action given to take. Please specify a power setting to set." 1
fi

# Check if setting battery power source on a device without a battery
if [[ $_arg_powerSourceSetting == "On Battery" && -z $batteryOptions ]]; then
  echo "[Error] Cannot set battery power source setting on a device that does not have a battery." >&2
  exit 1
fi

# Warn if trying to set battery power source on a device without a battery
if [[ $_arg_powerSourceSetting == "Both" && -z $batteryOptions ]]; then
  echo "[Warning] Cannot set battery power source setting on a device that does not have a battery. Ignoring battery power source settings."
fi

# Validate screen timeout argument
if [[ -n $_arg_screenTimeout && (! $_arg_screenTimeout =~ [0-9]+ || $_arg_screenTimeout -lt 0) ]]; then
  echo "[Error] An invalid screen timeout argument was given '$_arg_screenTimeout'. Please specify a positive number representing the desired timeout in minutes." >&2
  exit 1
fi

# Validate sleep timeout argument
if [[ -n $_arg_sleepTimeout && (! $_arg_sleepTimeout =~ [0-9]+ || $_arg_sleepTimeout -lt 0) ]]; then
  echo "[Error] An invalid sleep timeout argument was given '$_arg_sleepTimeout'. Please specify a positive number representing the desired timeout in minutes." >&2
  exit 1
fi

# Validate disk timeout argument
if [[ -n $_arg_diskTimeout && (! $_arg_diskTimeout =~ [0-9]+ || $_arg_diskTimeout -lt 0) ]]; then
  echo "[Error] An invalid disk timeout argument was given '$_arg_diskTimeout'. Please specify a positive number representing the desired timeout in minutes." >&2
  exit 1
fi

# Validate powernap setting
if [[ -n $_arg_powernap && $_arg_powernap != "Disable" && $_arg_powernap != "Enable" ]]; then
  echo "[Error] An invalid power nap setting was given '$_arg_powernap'. The only valid options are 'Disable' or 'Enable'." >&2
  exit 1
fi

# Validate terminal keep alive setting
if [[ -n $_arg_terminalKeepAlive && $_arg_terminalKeepAlive != "Disable" && $_arg_terminalKeepAlive != "Enable" ]]; then
  echo "[Error] An invalid terminal keep alive setting was given '$_arg_terminalKeepAlive'. The only valid options are 'Disable' or 'Enable'." >&2
  exit 1
fi

# Validate dim on battery setting
if [[ -n $_arg_dimOnBattery && $_arg_dimOnBattery != "Disable" && $_arg_dimOnBattery != "Enable" ]]; then
  echo "[Error] An invalid dim on battery setting was given '$_arg_dimOnBattery'. The only valid options are 'Disable' or 'Enable'." >&2
  exit 1
fi

# Validate low power mode setting
if [[ -n $_arg_lowPowerMode && $_arg_lowPowerMode != "Disable" && $_arg_lowPowerMode != "Enable" ]]; then
  echo "[Error] An invalid low power mode setting was given '$_arg_lowPowerMode'. The only valid options are 'Disable' or 'Enable'." >&2
  exit 1
fi

# Validate TCP keep alive setting
if [[ -n $_arg_tcpKeepAlive && $_arg_tcpKeepAlive != "Disable" && $_arg_tcpKeepAlive != "Enable" ]]; then
  echo "[Error] An invalid tcp keep alive setting was given '$_arg_tcpKeepAlive'. The only valid options are 'Disable' or 'Enable'." >&2
  exit 1
fi

# Validate wake on network setting
if [[ -n $_arg_wakeOneNetwork && $_arg_wakeOneNetwork != "Never" && $_arg_wakeOneNetwork != "Always" && $_arg_wakeOneNetwork != "Only on Power Adapter" ]]; then
  echo "[Error] An invalid wake one network setting was given '$_arg_wakeOneNetwork'. The only valid options are 'Never', 'Always' and 'Only on Power Adapter'." >&2
  exit 1
fi

# Set screen timeout if provided
if [[ -n $_arg_screenTimeout ]]; then
  timeoutError="Failed to set screen timeout of '$_arg_screenTimeout' minutes"
  timeoutSuccess="Successfully set screen timeout of '$_arg_screenTimeout' minutes"

  # Call the function to set the power setting for screen timeout
  set_powersetting --setting "displaysleep" --value "$_arg_screenTimeout" --errorMessage "$timeoutError" --successMessage "$timeoutSuccess"
fi

# Set sleep timeout if provided
if [[ -n $_arg_sleepTimeout ]]; then
  sleepError="Failed to set sleep timeout of '$_arg_sleepTimeout' minutes"
  sleepSuccess="Successfully set sleep timeout of '$_arg_sleepTimeout' minutes"

  # Call the function to set the power setting for sleep timeout
  set_powersetting --setting "sleep" --value "$_arg_sleepTimeout" --errorMessage "$sleepError" --successMessage "$sleepSuccess"
fi

# Set disk timeout if provided
if [[ -n $_arg_diskTimeout ]]; then
  diskError="Failed to set disk timeout of '$_arg_diskTimeout' minutes"
  diskSuccess="Successfully set disk timeout of '$_arg_diskTimeout' minutes"

  # Call the function to set the power setting for disk timeout
  set_powersetting --setting "disksleep" --value "$_arg_diskTimeout" --errorMessage "$diskError" --successMessage "$diskSuccess"
fi

# Set power nap setting if provided
if [[ -n $_arg_powernap ]]; then
  if [[ $_arg_powernap == "Enable" ]]; then
    _powernap_setting=1
    napError="Failed to enable powernap"
    napSuccess="Successfully enabled powernap"
  else
    _powernap_setting=0
    napError="Failed to disable powernap"
    napSuccess="Successfully disabled powernap"
  fi

  # Call the function to set the power setting for power nap
  set_powersetting --setting "powernap" --value "$_powernap_setting" --errorMessage "$napError" --successMessage "$napSuccess"
fi

# Set terminal keep alive setting if provided
if [[ -n $_arg_terminalKeepAlive ]]; then
  if [[ $_arg_terminalKeepAlive == "Enable" ]]; then
    _terminal_setting=1
    terminalError="Failed to enable terminal keep alive"
    terminalSuccess="Successfully terminal keep alive"
  else
    _terminal_setting=0
    terminalError="Failed to disable terminal keep alive"
    terminalSuccess="Successfully disabled terminal keep alive"
  fi

  # Call the function to set the power setting for terminal keep alive
  set_powersetting --setting "ttyskeepawake" --value "$_terminal_setting" --errorMessage "$terminalError" --successMessage "$terminalSuccess"
fi

# Set the "dim on battery" setting if the argument is provided
if [[ -n $_arg_dimOnBattery ]]; then
  if [[ $_arg_dimOnBattery == "Enable" ]]; then
    _dim_setting=1
    dimError="Failed to enable the setting 'dim on battery'."
    dimSuccess="Successfully enabled the setting 'dim on battery'."
  else
    _dim_setting=0
    dimError="Failed to disable the setting 'dim on battery'."
    dimSuccess="Successfully disabled the setting 'dim on battery'."
  fi

  # Call the function to set the power setting for dim on battery
  set_powersetting --setting "lessbright" --value "$_dim_setting" --errorMessage "$dimError" --successMessage "$dimSuccess" --singleSetting
fi

# Set the low power mode setting if the argument is provided
if [[ -n $_arg_lowPowerMode ]]; then
  if [[ $_arg_lowPowerMode == "Enable" ]]; then
    _lpm_setting=1
    lpmError="Failed to enable low power mode"
    lpmSuccess="Successfully enabled low power mode"
  else
    _lpm_setting=0
    lpmError="Failed to disable low power mode"
    lpmSuccess="Successfully disabled low power mode"
  fi

  # Call the function to set the power setting for low power mode
  set_powersetting --setting "lowpowermode" --value "$_lpm_setting" --errorMessage "$lpmError" --successMessage "$lpmSuccess"
fi

# Set the TCP keep alive setting if the argument is provided
if [[ -n $_arg_tcpKeepAlive ]]; then
  if [[ $_arg_tcpKeepAlive == "Enable" ]]; then
    _tcp_setting=1
    tcpError="Failed to enable tcp keep alive"
    tcpSuccess="Successfully enabled tcp keep alive"
  else
    _tcp_setting=0
    tcpError="Failed to disable tcp keep alive"
    tcpSuccess="Successfully disabled tcp keep alive"
  fi

  # Call the function to set the power setting for TCP keep alive
  set_powersetting --setting "tcpkeepalive" --value "$_tcp_setting" --errorMessage "$tcpError" --successMessage "$tcpSuccess"
fi

# Set the wake on network setting if the argument is provided
if [[ -n $_arg_wakeOneNetwork ]]; then
  case $_arg_wakeOneNetwork in
  "Never")
    pmset -a womp 0
    ;;
  "Always")
    pmset -a womp 1
    ;;
  "Only on Power Adapter")
    if [[ -n $batteryOptions ]]; then
      pmset -b womp 0
    fi
    pmset -c womp 1
    ;;
  esac

  # Retrieve and verify the new value of the wake on network setting
  newvalue=$(pmset -g custom | grep -w "womp")
  if [[ -z $batteryOptions ]]; then
    # Get the new value for the "Plugged In" policy if no battery options
    newvalueAC=$(echo "$newvalue" | xargs | cut -f2 -d' ')
  else
    # Get the new values for both "Battery" and "Plugged In" policies
    newvalueDC=$(echo "$newvalue" | xargs | cut -f2 -d' ')
    newvalueAC=$(echo "$newvalue" | xargs | cut -f4 -d' ')
  fi

  # Check and report the new value for "Always" and "Only on Power Adapter" settings
  if [[ $_arg_wakeOneNetwork == "Always" || $_arg_wakeOneNetwork == "Only on Power Adapter" ]]; then
    if [[ $newvalueAC != 1 ]]; then
      echo "[Error] Unable to enable wake on network on the 'Plugged In' Policy." >&2
      EXITCODE=1
    else
      echo "Successfully enabled wake on network on the 'Plugged In' Policy."
    fi
  fi

  # Check and report the new value for "Never" setting
  if [[ $_arg_wakeOneNetwork == "Never" ]]; then
    if [[ $newvalueAC != 0 ]]; then
      echo "[Error] Unable to disable wake on network on the 'Plugged In' Policy." >&2
      EXITCODE=1
    else
      echo "Successfully disabled wake on network on the 'Plugged In' Policy."
    fi
  fi

  # Check and report the new value for "Always" setting on battery
  if [[ -n $batteryOptions && $_arg_wakeOneNetwork == "Always" ]]; then
    if [[ $newvalueDC != 1 ]]; then
      echo "[Error] Unable to enable wake on network on the 'Battery' Policy." >&2
      EXITCODE=1
    else
      echo "Successfully enabled wake on network on the 'Battery' Policy."
    fi
  fi

  # Check and report the new value for "Never" and "Only on Power Adapter" settings on battery
  if [[ -n $batteryOptions && ($_arg_wakeOneNetwork == "Never" || $_arg_wakeOneNetwork == "Only on Power Adapter") ]]; then
    if [[ $newvalueDC != 0 ]]; then
      echo "[Error] Unable to disable wake on network on the 'Battery' Policy." >&2
      EXITCODE=1
    else
      echo "Successfully disabled wake on network on the 'Battery' Policy."
    fi
  fi
fi

# Exit the script with the set exit code if it is defined
if [[ -n $EXITCODE ]]; then
  exit "$EXITCODE"
fi




