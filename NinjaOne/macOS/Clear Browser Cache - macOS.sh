#!/usr/bin/env bash

# Description: Clears the browser cache for users on a Mac.
#
# Parameter UserName: --UserName "User1,User2"
#   The names of the users to clear the cache for. If not specified, clears the current user's cache.
#
# Parameter Browser: --Browser "Chrome"
#   Clears the cache for the specified browser. If not specified, No browser will be cleared.
#   Valid options are "Chrome", "Firefox", "Edge", "Safari" or multiple browsers separated by a comma. For example, "Chrome,Firefox".
#
# Parameter Force: --Force
#   Will force close the selected browser before clearing the cache.

# These are all our preset parameter defaults. You can set these = to something if you would prefer the script defaults to a certain parameter value.
_arg_userNames=
_arg_browser=
_arg_force=

# Help text function for when invalid input is encountered
print_help() {
    printf '\n\n%s\n\n' 'Usage: [--UserName|-u <arg>] [--Browser|-b <arg>] [--Force|-f] [--help|-h]'
    printf '%s\n' 'Preset Parameter: --UserName "User1,User2"'
    printf '\t%s\n' "The names of the users to clear the cache for. If not specified, clears the current user's cache."
    printf '%s\n' 'Preset Parameter: --Browser "Chrome"'
    printf '\t%s\n' "Clears the cache for the specified browser. Separate multiple browsers with a comma. If not specified, No browser will be cleared."
    printf '\t%s\n' "Valid options are 'Chrome', 'Firefox', 'Edge', 'Safari'."
    printf '%s\n' 'Preset Parameter: --Force'
    printf '\t%s\n' "Will force close the selected browser before clearing the cache."
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
        -u | --UserName | --Username)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_userNames=$2
            shift
            ;;
        --UserName=*)
            _arg_userNames="${_key##--UserNames=}"
            ;;
        -b | -Browser | --Browser)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_browser=$2
            shift
            ;;
        --Browser=*)
            _arg_browser="${_key##--Browser=}"
            ;;
        -f | --Force)
            _arg_force="true"
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

checkAppExists() {
    _Application=$1
    _UserName=$2
    if [[ -z "${_Application}" ]]; then
        echo "[Error] No application was specified."
        exit 1
    fi

    if [ -f "/Applications/${_Application}" ] || [ -f "/Users/${_UserName}/Applications/${_Application}" ]; then
        return 1
    else
        return 0
    fi
}

closeApp() {
    _UserName=$1
    _Application=$2
    # Force close the app by the user name
    if [[ "${_arg_force}" == "true" ]] && [[ "${_runningAsRoot}" == "true" ]]; then
        if ! su "${_UserName}" -c "osascript -e 'tell application \"${_Application}\" to quit'" 2>/dev/null; then
            echo "[Warn] Failed to force close ${_Application} for user ${_UserName}."
        else
            echo "[Info] Successfully force closed ${_Application} for user ${_UserName}."
        fi
    elif [[ "${_arg_force}" == "true" ]] && [[ "${_runningAsRoot}" == "false" ]]; then
        if ! osascript -e "tell application \"${_Application}\" to quit" 2>/dev/null; then
            echo "[Warn] Failed to force close ${_Application} for user ${_UserName}."
        else
            echo "[Info] Successfully force closed ${_Application} for user ${_UserName}."
        fi
    fi
}

clearCache() {
    _UserName=$1

    if [[ -z "${_UserName}" ]]; then
        echo "[Warn] ${_UserName} is not a valid user name. Skipping."
        return
    fi

    # Check that the path /Users/"$_UserName"/ exists
    if [[ ! -d "/Users/$_UserName/Library" ]]; then
        echo "[Warn] User $_UserName does not exist. Skipping."
        return
    fi

    _browserFound="false"
    # Safari
    #   /Users/$_user/Library/Caches/com.apple.Safari/WebKitCache
    if [[ "${_arg_browser}" == *"Safari"* ]] || [[ "${_arg_browser}" == *"safari"* ]]; then
        _browserFound="true"
        # Check if the app exists
        if checkAppExists "Safari.app" "${_UserName}"; then
            # Check if the user is logged in
            # Force close Safari by the user name
            closeApp "$_UserName" "Safari"
            # Check if the cache directory exists
            if ls /Users/"$_UserName"/Library/Caches/com.apple.Safari/WebKitCache 2>/dev/null | head -n 1 | grep -q .; then
                # Clear the cache for Safari
                rm -rf /Users/"$_UserName"/Library/Caches/com.apple.Safari/WebKitCache 2>/dev/null
                echo "[Info] Cleared Safari cache for user $_UserName"
            else
                echo "[Warn] Safari cache directory does not exist. Skipping."
            fi
        else
            echo "[Warn] Safari.app is not installed. Skipping."
        fi
    fi

    # Chrome
    #   /Users/$_user/Library/Caches/Google/Chrome/*/Cache
    if [[ "${_arg_browser}" == *"Chrome"* ]] || [[ "${_arg_browser}" == *"chrome"* ]]; then
        _browserFound="true"
        # Check if the app exists
        if checkAppExists "Google Chrome.app" "${_UserName}"; then
            # Force close Chrome by the user name
            closeApp "$_UserName" "Google Chrome"
            # Check if the cache directories exists
            if ls /Users/"$_UserName"/Library/Caches/Google/Chrome/*/Cache 2>/dev/null | head -n 1 | grep -q .; then
                # Clear the cache for Chrome
                rm -rf /Users/"$_UserName"/Library/Caches/Google/Chrome/*/Cache 2>/dev/null
                echo "[Info] Cleared Chrome cache for user $_UserName"
            else
                echo "[Warn] Chrome cache directory does not exist. Skipping."
            fi
        else
            echo "[Warn] Google Chrome.app is not installed. Skipping."
        fi
    fi

    # Firefox
    #   /Users/$_user/Library/Caches/Firefox/Profiles/????????.*/cache2/*
    if [[ "${_arg_browser}" == *"Firefox"* ]] || [[ "${_arg_browser}" == *"firefox"* ]]; then
        _browserFound="true"
        # Check if the app exists
        if checkAppExists "Firefox.app" "${_UserName}"; then
            # Force close Firefox by the user name
            closeApp "$_UserName" "Firefox"
            # Check if the cache directories exists
            if ls /Users/"$_UserName"/Library/Caches/Firefox/Profiles/????????.*/cache2/* 2>/dev/null | head -n 1 | grep -q .; then
                # Clear the cache for Firefox
                rm -rf /Users/"$_UserName"/Library/Caches/Firefox/Profiles/????????.*/cache2/* 2>/dev/null
                echo "[Info] Cleared Firefox cache for user $_UserName"
            else
                echo "[Warn] Firefox cache directory does not exist. Skipping."
            fi
        else
            echo "[Warn] Firefox.app is not installed. Skipping."
        fi
    fi

    # Edge
    #   /Users/$_user/Library/Caches/Microsoft Edge/*/Cache
    if [[ "${_arg_browser}" == *"Edge"* ]] || [[ "${_arg_browser}" == *"edge"* ]]; then
        _browserFound="true"
        # Check if the app exists
        if checkAppExists "Microsoft Edge.app" "${_UserName}"; then
            # Force close Edge by the user name
            closeApp "$_UserName" "Microsoft Edge"
            # Check if the cache directories exists
            if ls /Users/"$_UserName"/Library/Caches/Microsoft\ Edge/*/Cache 2>/dev/null | head -n 1 | grep -q .; then
                # Clear the cache for Edge
                rm -rf /Users/"$_UserName"/Library/Caches/Microsoft\ Edge/*/Cache 2>/dev/null
                echo "[Info] Cleared Edge cache for user $_UserName"
            else
                echo "[Warn] Edge cache directory does not exist. Skipping."
            fi
        else
            echo "[Warn] Microsoft Edge.app is not installed. Skipping."
        fi
    fi

    if [[ "$_browserFound" == "false" ]]; then
        echo "[Error] At least one browser must be specified. Please specify one of the following: Chrome, Firefox, Edge, Safari."
        exit 1
    fi
}

parse_commandline "$@"

# If script variable is used override commandline arguments
if [[ -n $userNames ]]; then
    # Split userNames into an array
    _arg_userNames=$userNames
fi

if [[ -z $chrome ]] && [[ -z $firefox ]] && [[ -z $edge ]] && [[ -z $safari ]] && [[ -z $_arg_browser ]]; then
    echo "[Error] At least one browser must be specified. Please specify one of the following: Chrome, Firefox, Edge, Safari."
    exit 1
fi

# Append browser names to _arg_browser as we check if the name exists in _arg_browser later on
if [[ -n $chrome ]] && [[ "${chrome}" == "true" ]]; then
    _arg_browser="$_arg_browser,chrome"
fi
if [[ -n $firefox ]] && [[ "${firefox}" == "true" ]]; then
    _arg_browser="$_arg_browser,firefox"
fi
if [[ -n $edge ]] && [[ "${edge}" == "true" ]]; then
    _arg_browser="$_arg_browser,edge"
fi
if [[ -n $safari ]] && [[ "${safari}" == "true" ]]; then
    _arg_browser="$_arg_browser,safari"
fi

if [[ -n $force ]]; then
    if [[ "${force}" == "true" ]]; then
        _arg_force="true"
    else
        _arg_force="false"
    fi
fi

# Check if the user is running this script as root
_runningAsRoot="false"
if [[ $EUID -eq 0 ]]; then
    _runningAsRoot="true"
fi

_Users=()
if [[ -z "${_arg_userNames}" ]] && [[ $_runningAsRoot == "true" ]]; then
    # Get a list of all user names that can login
    _userNames=$(dscl . -list /Users UniqueID | awk '$2 > 499 {print $1}')
    # Loop through each user name
    for _userName in $_userNames; do
        # Trim whitespace from the user name
        _userName="${_userName##*( )}" # Remove leading whitespace
        _userName="${_userName%%*( )}" # Remove trailing whitespace
        _Users+=("$_userName")
    done
else
    IFS=',' read -r -a _userNames <<<"$_arg_userNames"
    for _userName in "${_userNames[@]}"; do
        # Trim whitespace from the user name
        _userName="${_userName##*( )}" # Remove leading whitespace
        _userName="${_userName%%*( )}" # Remove trailing whitespace
        _Users+=("$_userName")
    done
fi

if [[ $_runningAsRoot == "true" ]]; then
    # Check if the user is in the list of users to clear cache for
    for _userName in "${_Users[@]}"; do
        _user=$(echo "$_userName" | awk '{$1=$1};1')
        if dscl . read "/Users/$_user" 1>/dev/null 2>&1; then
            clearCache "$_user"
            echo ""
        else
            echo "[Warn] ${_user} is not a valid user name. Skipping."
        fi
    done
else
    if [[ "$(whoami)" == "${_arg_userNames}" ]] || [[ -z "${_arg_userNames}" ]]; then
        clearCache "$(whoami)"
    else
        echo "[Error] The script must be run as system/root to clear the cache for multiple users."
        exit 1
    fi
fi





