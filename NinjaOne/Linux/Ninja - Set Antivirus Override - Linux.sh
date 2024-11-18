#!/usr/bin/env bash
#
# Description: Add an antivirus to the device details or override the existing antivirus information.
#
# Preset Parameter: --antivirusName "ReplaceMeWithYourDesiredName"
#   Name of the antivirus you would like to appear in the device details.
#
# Preset Parameter: --antivirusVersion "1.0.2"
#   Specify the version number of the antivirus.
#
# Preset Parameter: --antivirusStatus "Up-to-Date"
#   Specify whether the antivirus definitions are Up-to-Date, Out-of-Date, or Unknown.
#
# Preset Parameter: --antivirusState "ON"
#   Specify the current status of the antivirus.
#
# Preset Parameter: --removeOverride
#   Remove all existing overrides.
#
# Preset Parameter: --antivirusState
#   Append or update an existing override.
#
# Preset Parameter: --help
#		Displays a help menu.
#
# Release Notes: Initial Release

# Initialize variables
_arg_antivirusName=
_arg_antivirusVersion=
_arg_antivirusStatus=
_arg_antivirusState=
_arg_removeOverride="off"
_arg_append="off"

# Function to display help message
print_help() {
  printf '\n\n%s\n\n' 'Usage: [--antivirusName|-n <arg>] [--antivirusVersion|-v <arg>] [--antivirusStatus|--status <arg>] [--antivirusState|--state <arg>] [--removeOverride|-r] [--append|-a] [--help|-h] '
  printf '%s\n' 'Preset Parameter: --antivirusName "ReplaceMeWithYourDesiredName"'
  printf '\t%s\n' "Name of the antivirus you would like to appear in the device details."
  printf '%s\n' 'Preset Parameter: --antivirusVersion "1.0.2"'
  printf '\t%s\n' "Specify the version number of the antivirus."
  printf '%s\n' 'Preset Parameter: --antivirusStatus "Up-to-Date"'
  printf '\t%s\n' "Specify whether the antivirus definitions are Up-to-Date, Out-of-Date, or Unknown."
  printf '%s\n' 'Preset Parameter: --antivirusState "ON"'
  printf '\t%s\n' "Specify the current status of the antivirus."
  printf '%s\n' 'Preset Parameter: --removeOverride'
  printf '\t%s\n' "Remove all existing overrides."
  printf '%s\n' 'Preset Parameter: --antivirusState'
  printf '\t%s\n' "Append or update an existing override."
  printf '\n%s\n' 'Preset Parameter: --help'
  printf '\t%s\n' "Displays this help menu."
}

# Function to print an error message and exit
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
    --antivirusName | --antivirusname | --name | -n)
      test $# -lt 2 && die "Missing value for the argument '$_key'." 1
      _arg_antivirusName=$2
      shift
      ;;
    --antivirusName=*)
      _arg_antivirusName="${_key##--antivirusName=}"
      ;;
    --antivirusVersion | --antivirusversion | --version | -v)
      test $# -lt 2 && die "Missing value for the argument '$_key'." 1
      _arg_antivirusVersion=$2
      shift
      ;;
    --antivirusVersion=*)
      _arg_antivirusVersion="${_key##--antivirusVersion=}"
      ;;
    --antivirusStatus | --antivirusstatus | --status)
      test $# -lt 2 && die "Missing value for the argument '$_key'." 1
      _arg_antivirusStatus=$2
      shift
      ;;
    --antivirusStatus=*)
      _arg_antivirusStatus="${_key##--antivirusStatus=}"
      ;;
    --antivirusState | --antivirusstate | --state)
      test $# -lt 2 && die "Missing value for the argument '$_key'." 1
      _arg_antivirusState=$2
      shift
      ;;
    --antivirusState=*)
      _arg_antivirusState="${_key##--antivirusState=}"
      ;;
    --removeOverride | --remove | -r)
      _arg_removeOverride="on"
      ;;
    --append | --Append | -a)
      _arg_append="on"
      ;;
    --help | -h)
      _PRINT_HELP=yes die 0
      ;;
    *)
      _PRINT_HELP=yes die "[Error] Got an unexpected argument '$1'" 1
      ;;
    esac
    shift
  done
}

# Parse the command line arguments
parse_commandline "$@"

# Replace commandline parameters with script form variables
if [[ -n $avName ]]; then
  _arg_antivirusName="$avName"
fi
if [[ -n $avVersion ]]; then
  _arg_antivirusVersion="$avVersion"
fi
if [[ -n $avStatus ]]; then
  _arg_antivirusStatus="$avStatus"
fi
if [[ -n $avState ]]; then
  _arg_antivirusState="$avState"
fi
if [[ -n $append && $append == "true" ]]; then
  _arg_append="on"
fi
if [[ -n $removeOverride && $removeOverride == "true" ]]; then
  _arg_removeOverride="on"
fi

# Ensure that removing an override and adding/updating an override are not done simultaneously
if [[ $_arg_removeOverride == "on" && (-n $_arg_antivirusName || -n $_arg_antivirusState || -n $_arg_antivirusStatus || -n $_arg_antivirusVersion || $_arg_append == "on") ]]; then
  _PRINT_HELP=no die "[Error] Cannot remove an override and add an override at the same time." 1
fi

# Check for required antivirus name and escape special characters if necessary
reservedCharacters='[\"]'
if [[ -z $_arg_antivirusName && $_arg_removeOverride != "on" ]]; then
  if [[ $_arg_append == "on" ]]; then
    _PRINT_HELP=yes die "[Error] Antivirus name was not given. The antivirus name is required when updating or adding a new override!" 1
  else
    _PRINT_HELP=yes die "[Error] Antivirus name was not given. Antivirus name, state, and status are required when adding a new override!" 1
  fi
elif [[ -n $_arg_antivirusName && $_arg_antivirusName =~ $reservedCharacters ]]; then
  _arg_antivirusName=${_arg_antivirusName//\\/\\\\}
  _arg_antivirusName=${_arg_antivirusName//\"/\\\"}
fi

# Check for required antivirus status
if [[ -z $_arg_antivirusStatus && $_arg_removeOverride != "on" && $_arg_append != "on" ]]; then
  _PRINT_HELP=yes die "[Error] Antivirus status was not given. Antivirus name, state, and status are required!" 1
fi

# Validate antivirus status
if [[ -n $_arg_antivirusStatus && $_arg_antivirusStatus != "Up-to-Date" && $_arg_antivirusStatus != "Out-of-Date" && $_arg_antivirusStatus != "Unknown" ]]; then
  _PRINT_HELP=no die "[Error] An invalid antivirus status of '$_arg_antivirusStatus' was given. Only the following statuses are valid. 'Up-to-Date', 'Out-of-Date', and 'Unknown'." 1
fi

# Check for required antivirus state
if [[ -z $_arg_antivirusState && $_arg_removeOverride != "on" && $_arg_append != "on" ]]; then
  _PRINT_HELP=yes die "[Error] Antivirus state was not given. Antivirus name, state, and status are required!" 1
else
  _arg_antivirusState=$(echo "$_arg_antivirusState" | tr '[:lower:]' '[:upper:]')
fi

# Validate antivirus state
if [[ -n $_arg_antivirusState && $_arg_antivirusState != "ON" && $_arg_antivirusState != "OFF" && $_arg_antivirusState != "EXPIRED" && $_arg_antivirusState != "SNOOZED" && $_arg_antivirusState != "UNKNOWN" ]]; then
  _PRINT_HELP=no die "[Error] An invalid antivirus state of '$_arg_antivirusState' was given. Only the following states are valid. 'ON', 'OFF', 'EXPIRED', 'SNOOZED', and 'UNKNOWN'." 1
fi

# Validate antivirus version
if [[ -n $_arg_antivirusVersion && $_arg_antivirusVersion =~ [^0-9\.] ]]; then
  _PRINT_HELP=no die "[Error] The antivirus version given '$_arg_antivirusVersion' contains an invalid character. Only the following characters are allowed. '0-9' and '.'" 1
fi

# Check if the removeOverride flag is set to "on"
if [[ $_arg_removeOverride == "on" ]]; then
  echo "Removing override as requested."
  # Check if the override file exists
  if [[ ! -f "/opt/NinjaRMMAgent/programdata/customization/av_override.json" ]]; then
    echo "No override present."
    exit 0
  # Try to remove the override file and capture any error output
  elif output=$(rm "/opt/NinjaRMMAgent/programdata/customization/av_override.json" 2>&1); then
    echo "Succesfully removed override!"
    exit 0
  # Print an error message if the removal fails
  else
    echo "[Error] Failed to remove override!"
    echo "[Error] $output"
  fi
fi

# Check if the customization directory exists
if [[ ! -d "/opt/NinjaRMMAgent/programdata/customization" ]]; then
  echo "Creating customization folder at '/opt/NinjaRMMAgent/programdata/customization'."
  # Try to create the customization directory and capture any error output
  if output=$(mkdir "/opt/NinjaRMMAgent/programdata/customization" 2>&1); then
    echo "Folder created."
  else
    # Print an error message if the creation fails
    echo "[Error] Unable to create customization folder." >&2
    echo "[Error] $output" >&2
    exit 1
  fi
fi

# Check if the append flag is set to "on" and the override JSON file exists
if [[ $_arg_append == "on" && -f "/opt/NinjaRMMAgent/programdata/customization/av_override.json" ]]; then
  # Extract antivirus names, versions, statuses and states from the JSON file
  avNames=$(grep "av_name" "/opt/NinjaRMMAgent/programdata/customization/av_override.json" | tr -s " " | sed s/\"av_name\"://g | sed -e 's/^[[:space:]]*//' | sed 's/[\",]//g' | sed -e 's/[[:space:]]*$//')
  avVersions=$(grep "av_version" "/opt/NinjaRMMAgent/programdata/customization/av_override.json" | tr -s " " | sed s/\"av_version\"://g | sed -e 's/^[[:space:]]*//' | sed 's/[\",]//g' | sed -e 's/[[:space:]]*$//')
  avStatuses=$(grep "av_status" "/opt/NinjaRMMAgent/programdata/customization/av_override.json" | tr -s " " | sed s/\"av_status\"://g | sed -e 's/^[[:space:]]*//' | sed 's/[\",]//g' | sed -e 's/[[:space:]]*$//')
  avStates=$(grep "av_state" "/opt/NinjaRMMAgent/programdata/customization/av_override.json" | tr -s " " | sed s/\"av_state\"://g | sed -e 's/^[[:space:]]*//' | sed 's/[\",]//g' | sed -e 's/[[:space:]]*$//')

  # Find the line number of the existing antivirus entry with the given name
  existingAV=$(echo "$avNames" | grep -n "$_arg_antivirusName" | sed 's/:.*//g')

  # Determine the desired antivirus status
  if [[ -n $_arg_antivirusStatus ]]; then
    desiredStatus=$_arg_antivirusStatus
  elif [[ -n $existingAV ]]; then
    desiredStatus=$(echo "$avStatuses" | sed -n "${existingAV}p")
  fi

  # Determine the desired antivirus state
  if [[ -n $_arg_antivirusState ]]; then
    desiredState=$_arg_antivirusState
  elif [[ -n $existingAV ]]; then
    desiredState=$(echo "$avStates" | sed -n "${existingAV}p")
  fi

  # Check if both status and state are provided
  if [[ -z $desiredStatus || -z $desiredState ]]; then
    _PRINT_HELP=no die "[Error] Antivirus state or status are missing from the override entry. Please provide both in addition to the antivirus name!" 1
  fi

  # Update the existing antivirus entry if found
  if [[ -n $existingAV ]]; then
    echo "Attempting to update override."

    # Update antivirus version if provided
    if [[ -n $_arg_antivirusVersion ]]; then
      modified_json=$(awk -v target="$existingAV" -v value="$_arg_antivirusVersion" 'BEGIN { av_count = 1 }
      /av_version/ { 
        if (av_count == target){ 
          sub( /av_version.*/ , "av_version\":  \""value"\"," ) 
        }
        av_count++
      }{ print }' "/opt/NinjaRMMAgent/programdata/customization/av_override.json")

      if echo "$modified_json" >"/opt/NinjaRMMAgent/programdata/customization/av_override.json"; then
        echo "Successfully updated the antivirus version!"
      else
        echo "[Error] Failed to update the antivirus version!" >&2
        exit 1
      fi
    fi

    # Update antivirus status if provided
    if [[ -n $_arg_antivirusStatus ]]; then
      modified_json=$(awk -v target="$existingAV" -v value="$_arg_antivirusStatus" 'BEGIN { av_count = 1 }
      /av_status/ { 
        if (av_count == target){ 
          sub( /av_status.*/ , "av_status\":  \""value"\"," ) 
        }
        av_count++
      }{print}' "/opt/NinjaRMMAgent/programdata/customization/av_override.json")

      if echo "$modified_json" >"/opt/NinjaRMMAgent/programdata/customization/av_override.json"; then
        echo "Successfully updated the override status!"
      else
        echo "[Error] Failed to update the override status!" >&2
        exit 1
      fi
    fi

    # Update antivirus state if provided
    if [[ -n $_arg_antivirusState ]]; then
      modified_json=$(awk -v target="$existingAV" -v value="$_arg_antivirusState" 'BEGIN { av_count = 1 }
      /av_state/ { 
        if (av_count == target){ 
          sub( /av_state.*/ , "av_state\":  \""value"\"" ) 
        }
        av_count++
      }{print}' "/opt/NinjaRMMAgent/programdata/customization/av_override.json")

      if echo "$modified_json" >"/opt/NinjaRMMAgent/programdata/customization/av_override.json"; then
        echo "Successfully updated the override state!"
      else
        echo "[Error] Failed to update the override state!" >&2
        exit 1
      fi
    fi

    exit
  fi

  # Print a message indicating that the script is attempting to append an override
  echo "Attempting to append override."
  # Initialize a counter for indexing
  i=1
  # Initialize the JSON structure for antivirus overrides
  avOverrides="{
  \"av_override\": [
"
  # Loop through each antivirus name
  for avName in $avNames; do
    # Extract the corresponding antivirus version, status and state for the current index
    avVersion=$(echo "$avVersions" | sed -n "${i}p")
    avStatus=$(echo "$avStatuses" | sed -n "${i}p")
    avState=$(echo "$avStates" | sed -n "${i}p")

    # Append the current antivirus entry to the JSON structure
    avOverrides+="    {
      \"av_name\":  \"${avName}\",
      \"av_version\": \"${avVersion}\",
      \"av_status\":  \"${avStatus}\",
      \"av_state\": \"${avState}\"
    },
"
    # Increment the counter for the next iteration
    i=$((i + 1))
  done

  # Close the JSON structure
  avOverrides+="    {
      \"av_name\":  \"${_arg_antivirusName}\",
      \"av_version\": \"${_arg_antivirusVersion}\",
      \"av_status\":  \"${_arg_antivirusStatus}\",
      \"av_state\": \"${_arg_antivirusState}\"
    }
  ]
}
"

  # Attempt to write the JSON structure containing antivirus overrides to the specified file
  if echo "$avOverrides" >"/opt/NinjaRMMAgent/programdata/customization/av_override.json"; then
    echo "Succesfully added override."
    exit
  else
    echo "[Error] Failed to add override." >&2
    exit 1
  fi
fi

# Check if the antivirus state or status arguments are missing
if [[ -z $_arg_antivirusState || -z $_arg_antivirusStatus ]]; then
  _PRINT_HELP=no die "[Error] Antivirus name, state and status are required when adding a new override!" 1
fi

# Construct the JSON string for the antivirus override
JSON_STRING="{
  \"av_override\": [
    {
      \"av_name\":  \"${_arg_antivirusName}\",
      \"av_version\":  \"${_arg_antivirusVersion}\",
      \"av_status\":  \"${_arg_antivirusStatus}\",
      \"av_state\":  \"${_arg_antivirusState}\"
    }
  ]
}
"

# Attempt to write the JSON string to the specified file
if echo "$JSON_STRING" >"/opt/NinjaRMMAgent/programdata/customization/av_override.json"; then
  # If the write operation is successful, print a success message
  echo "Succesfully created override."
else
  # If the write operation fails, print an error message to standard error
  echo "[Error] Failed to create override." >&2
  exit 1
fi




