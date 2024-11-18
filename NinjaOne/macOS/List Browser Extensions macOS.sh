#!/usr/bin/env bash

#
# Description: Get the browser extensions for Safari, Chrome, Firefox, and Edge that are installed on a macOS system.
#
# Usage: [multilineCustomFieldName] [wysiwygCustomFieldName]
#
# Release Notes: Fixed 10% width bug.
#
# Example Output:
#
# Safari Extensions:
# User: john, Name: com.betafish.adblock-mac.SafariMenu, Id: 3KKZV48AQD
# User: ken, Name: com.rockysandstudio.MKPlayer.MKPlayer-Extension, Id: 2N35YUC83U
#
# Chrome Extensions:
# User: john, Name: Chrome Web Store Payments, Id: nmmhkkegccagdldgiimedpiccmgmieda, Version: 1.0.0.6, Profile Name: test1
# User: john, Name: Turn Off the Lights, Id: bfbmjmiodbnnpllbbbfblcplfjjepjdn, Version: 4.2.6.0, Profile Name: test2
# User: ken, Name: Google Docs Offline, Id: ghbmnnjooekpmoecnnnilnnbdlolhkhi, Version: 1.76.1, Profile Name: Person 1
#
# Firefox Addons:
# User: john, Name: Return YouTube Dislike, Id: {762f9885-5a13-4abd-9c77-433dcd38b8fd}, Description: Returns ability to see dislike statistics on youtube, Profile Name: default-release
# User: john, Name: Stylebot, Id: {52bda3fd-dc48-4b3d-a7b9-58af57879f1e}, Description: Change the appearance of the web instantly, Profile Name: default-release
# User: ken, Name: Search by Image, Id: {2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}, Description: A powerful reverse image search tool, with support for various search engines, such as Google, Bing, Yandex, Baidu and TinEye., Profile Name: default-release
#
# Edge Extensions:
# User: john, Name: Google Docs Offline, Id: ghbmnnjooekpmoecnnnilnnbdlolhkhi, Version: 1.76.2, Profile Name: test 3
# User: john, Name: Edge relevant text changes, Id: jmjflgjpcpepeafmmgdpfkogkghcpiha, Version: 1.2.1, Profile Name: test 3
# User: ken, Name: Google Docs Offline, Id: ghbmnnjooekpmoecnnnilnnbdlolhkhi, Version: 1.76.2, Profile Name: Profile 1

_arg_multilineField=$1
_arg_wysiwygField=$2

# Determines whether or not help text is necessary and routes the output to stderr
die() {
    local _ret="${2:-1}"
    echo "$1" >&2
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    exit "${_ret}"
}

# Prints the help text
print_help() {
    echo "Get the browser extensions for Safari, Chrome, Firefox, and Edge that are installed on a macOS system."
    echo "Usage: [multilineCustomFieldName] [wysiwygCustomFieldName]"
}

# Check if --help or -h is passed as an argument
for _arg in "$@"; do
    case "$_arg" in
    --help | -h)
        print_help
        exit 0
        ;;
    esac
done

# Set the custom field value using ninjarmm-cli
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

# Check if the multilineCustomFieldName is set as environment variables
multiline=$(printenv | grep -i multilineCustomFieldName | awk -F = '{print $2}')
if [[ -n "$multiline" ]] && [[ "${multiline}" != "null" ]]; then
    _arg_multilineField=$(printenv | grep -i multilineCustomFieldName | awk -F = '{print $2}')
fi

# Check if the wysiwygCustomFieldName is set as environment variables
wysiwygField=$(printenv | grep -i wysiwygCustomFieldName | awk -F = '{print $2}')
if [[ -n "$wysiwygField" ]] && [[ "${wysiwygField}" != "null" ]]; then
    _arg_wysiwygField=$(printenv | grep -i wysiwygCustomFieldName | awk -F = '{print $2}')
fi

# Check if both _arg_multilineField and _arg_wysiwygField are set and not empty
if [[ -n "$_arg_multilineField" && -n "$_arg_wysiwygField" ]]; then
    # Convert both field names to uppercase to check for equality
    multiline=$(echo "$_arg_multilineField" | tr '[:lower:]' '[:upper:]')
    wysiwyg=$(echo "$_arg_wysiwygField" | tr '[:lower:]' '[:upper:]')

    # If the converted names are the same, it means both fields cannot be identical
    # If they are, terminate the script with an error
    if [[ "$multiline" == "$wysiwyg" ]]; then
        _PRINT_HELP=yes die '[Error] Multline Field and WYSIWYG Field cannot be the same name. https://ninjarmm.zendesk.com/hc/en-us/articles/360060920631-Custom-Fields-Configuration-Device-Role-Fields'
    fi
fi

# Warn that if not running as root, the script may not be able to access all user directories
if [[ $EUID -ne 0 ]]; then
    echo "[Warn] This script may not be able to access all user directories unless run as root."
fi

# Converts a string input into an HTML table format
convertToHTMLTable() {
    local _arg_delimiter=" "
    local _arg_inputObject

    # Process command-line arguments for the function
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        --delimiter | -d)
            test $# -lt 2 && echo "[Error] Missing value for the optional argument" >&2 && return 1
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

    # Handles missing input by checking stdin or returning an error
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

createExtList() {
    userHome=$1
    browser=$2 # chrome or edge
    user_name=$(echo "$userHome" | cut -d "/" -f 3)
    if [[ "${browser}" == "chrome" ]]; then
        manifests=$(find "${userHome}/Library/Application Support/Google/Chrome" -type f -name 'manifest.json' 2>/dev/null | grep "Extensions")
        profileLocalState="${userHome}/Library/Application Support/Google/Chrome/Local State"
    elif [[ "${browser}" == "edge" ]]; then
        manifests=$(find "${userHome}/Library/Application Support/Microsoft Edge" -type f -name 'manifest.json' 2>/dev/null | grep "Extensions")
        profileLocalState="${userHome}/Library/Application Support/Microsoft Edge/Local State"
    fi

    en_messages="_locales/en/messages.json"
    enUS_messages="_locales/en_US/messages.json"

    while IFS= read -r manifest; do
        # Check if we can read the manifest file
        if [ ! -f "$manifest" ]; then
            continue
        fi

        profileName=$(
            # Get profile name from profileLocalState that contains json data
            # "profile.info_cache.Default" is the default profile
            osascript -l JavaScript -e "
                    var profileLocalState = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding($.NSData.dataWithContentsOfFile('$profileLocalState'), $.NSUTF8StringEncoding)));
                    // Get each profile name based on the profile path
                    if ('$browser' === 'chrome') {
                        var profilePathName = '$manifest'.split('/')[7];
                    } else if ('$browser' === 'edge') {
                        var profilePathName = '$manifest'.split('/')[6];
                    }
                    for (var key in profileLocalState.profile.info_cache) {
                        if (key.toLowerCase() === profilePathName.toLowerCase()) {
                            var profileName = profileLocalState.profile.info_cache[key].name;
                            break;
                        }
                    }
                    profileName;
                "
        )

        # Get the id of the extension from the manifest path by splitting the path on '/' and getting the 9th element
        if [[ "${browser}" == "chrome" ]]; then
            extID=$(awk -F '/' '{print $10}' <<<"$manifest")
        elif [[ "${browser}" == "edge" ]]; then
            extID=$(awk -F '/' '{print $9}' <<<"$manifest")
        fi
        # Get name from manifest
        name=$(
            osascript -l JavaScript -e "
                var data = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding($.NSData.dataWithContentsOfFile('$manifest'), $.NSUTF8StringEncoding)));
                var name = data.name;
                name;
            "
        )
        # Get version from manifest
        version=$(
            osascript -l JavaScript -e "
                var data = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding($.NSData.dataWithContentsOfFile('$manifest'), $.NSUTF8StringEncoding)));
                var version = data.version;
                version;
            "
        )

        # Get the name of the extension from the messages.json file if the name contains "__MSG_"
        if [[ "${name}" =~ "__MSG_" ]]; then
            name=$(echo "$name" | sed 's/__MSG_//g' | sed 's/__$//g')
            if [ -f "$(dirname "$manifest")/$en_messages" ]; then
                # Check if message.json exists in en folder
                name=$(
                    osascript -l JavaScript -e "
                        var data = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding($.NSData.dataWithContentsOfFile('$(dirname "$manifest")/$en_messages'), $.NSUTF8StringEncoding)));
                        var searchKey = '$name';
                        var asLowercase = searchKey.toLowerCase();
                        var name = data[Object.keys(data).find(key => key.toLowerCase() === asLowercase)].message;
                        name;
                    " 2>/dev/null
                )
            elif [ -f "$(dirname "$manifest")/$enUS_messages" ]; then
                # Check if message.json exists in enUS folder
                name=$(
                    osascript -l JavaScript -e "
                        var data = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding($.NSData.dataWithContentsOfFile('$(dirname "$manifest")/$enUS_messages'), $.NSUTF8StringEncoding)));
                        var searchKey = '$name';
                        var asLowercase = searchKey.toLowerCase();
                        var name = data[Object.keys(data).find(key => key.toLowerCase() === asLowercase)].message;
                        name;
                    " 2>/dev/null
                )
            fi
        fi
        if [[ -n "$name" ]]; then
            printf "%s|%s|%s|%s|%s\n" "$user_name" "$profileName" "$name" "$extID" "$version"
        else
            printf "%s|%s|%s|%s|%s\n" "$user_name" "$profileName" "Name Not Found" "$extID" "$version"
        fi
    done <<<"$manifests"
}

# Get a list of all users in the /Users directory except Shared
users=()
for user in /Users/*; do
    if [[ -d "$user" && ! "$user" =~ /Users/Shared ]]; then
        users+=("${user##*/}")
    fi
done

# Error when no users are found
if [[ ${#users[@]} -eq 0 ]]; then
    _PRINT_HELP=no die "[Error] No user directories found in /Users"
fi

safari_title="Safari Extensions"
safari_extensions=""
chrome_title="Chrome Extensions"
chrome_extensions=""
firefox_title="Firefox Addons"
firefox_addons=""
edge_title="Edge Extensions"
edge_extensions=""

# Safari
for user in "${users[@]}"; do
    ext_plist="/Users/$user/Library/Containers/com.apple.Safari/Data/Library/Safari/AppExtensions/Extensions.plist"
    pattern='(com\..*)\s\((.*)\)'
    if [[ -f "$ext_plist" ]]; then
        safari_extensions+=$'\n'"$(
            grep -Eo "$pattern" "$ext_plist" | while read -r line; do
                ext_name=$(echo "$line" | awk -F ' ' '{print $1}')
                ext_id=$(echo "$line" | awk -F ' ' '{print $2}' | tr -d '()')
                printf "%s|%s|%s\n" "$user" "$ext_name" "$ext_id"
            done
        )"
    fi
done

# Chrome
for user in "${users[@]}"; do
    # Add a newline to the beginning of the string to separate the results from the previous user
    chrome_extensions+=$'\n'"$(createExtList "/Users/$user" "chrome")"
done

# Firefox Get installed Addons (not extensions)
firefox_addons=$(
    # Loop through each user profile
    for user in "${users[@]}"; do
        firefox_path="/Users/$user/Library/Application Support/Firefox"
        profile_dir="$firefox_path/Profiles"
        # Check if Profiles directory exists
        if [[ -d "$profile_dir" ]]; then
            profiles_ini_path="$firefox_path/profiles.ini"
            # Check if profiles.ini file exists
            if [[ -f "$profiles_ini_path" ]]; then
                profiles_ini=$(cat "$profiles_ini_path")
                # Parse the profiles.ini file and get the profile names and paths
                # Get each section
                awk -F '=' '/\[/{print $1}' <<<"$profiles_ini" | while read -r section; do
                    # Get the profile name
                    profile_name=$(
                        awk -F'=' -v section="$section" -v k="Name" '
                        $0==section{ f=1; next }
                        /\[/{ f=0; next }
                        f && $1==k{ print $0 }
                        ' <<<"$profiles_ini" | sed 's/^Name=//'
                    )
                    # Get the profile path
                    profile_path=$(
                        awk -F'=' -v section="$section" -v k="Path" '
                        $0==section{ f=1; next }
                        /\[/{ f=0; next }
                        f && $1==k{ print $0 }
                        ' <<<"$profiles_ini" | sed 's/^Path=//'
                    )
                    # Get the addons json file path
                    ext_dir="$firefox_path/$profile_path/addons.json"
                    if [[ -f "$ext_dir" ]]; then
                        # Get name, id, and description from the addons.json file
                        ff_results=$(
                            osascript -l JavaScript -e "
                                var data = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding($.NSData.dataWithContentsOfFile('$ext_dir'), $.NSUTF8StringEncoding)));
                                var addons = data.addons;
                                var result = '';
                                for (var i = 0; i < addons.length; i++) {
                                    var addon = addons[i];
                                    result += addon.name + ',' + addon.id + ',' + addon.description + '\n';
                                }
                                result;
                            "
                        )
                        Old_IFS=$IFS
                        echo "$ff_results" | while IFS=, read -r name id description; do
                            printf "%s|%s|%s|%s|%s\n" "$user" "$profile_name" "$name" "$id" "$description"
                        done
                        IFS=$Old_IFS
                    fi
                done
            fi
        fi
    done
)

# Edge
for user in "${users[@]}"; do
    # Add a newline to the beginning of the string to separate the results from the previous user
    edge_extensions+=$'\n'"$(createExtList "/Users/$user" "edge")"
done

if [[ -n $_arg_multilineField ]] || [[ -n $_arg_wysiwygField ]]; then
    # Add headers if a custom field is set
    if [[ -n "${safari_extensions}" ]]; then
        safari_extensions=$(echo -e "User|Name|Id\n$safari_extensions")
    fi
    if [[ -n "${chrome_extensions}" ]]; then
        chrome_extensions=$(echo -e "User|Profile Name|Name|Id|Version\n$chrome_extensions")
    fi
    if [[ -n "${firefox_addons}" ]]; then
        firefox_addons=$(echo -e "User|Profile Name|Name|Id|Description\n$firefox_addons")
    fi
    if [[ -n "${edge_extensions}" ]]; then
        edge_extensions=$(echo -e "User|Profile Name|Name|Id|Version\n$edge_extensions")
    fi
fi

# Checks if there is a multiline custom field set
if [[ -n $_arg_multilineField ]]; then
    echo ""
    echo "Attempting to set Custom Field '$_arg_multilineField'..."

    # Formats the extension data for the multiline custom field
    multilineValue=""
    # Check if any browser extensions were found
    if [[ -n "$safari_title" ]] && [[ -n "${safari_extensions}" ]]; then
        multilineValue+=$'\n'
        multilineValue+="$safari_title:"
        multilineValue+=$'\n'
        multilineValue+=$(
            # Convert the safari_extensions string to a table format. Skip the first line as it is the header
            echo "$safari_extensions" | tail -n +2 | while IFS='|' read -r user name id; do
                printf "User: %s, Name: %s, Id: %s\n" "$user" "$name" "$id"
            done
        )
    fi
    if [[ -n "$chrome_title" ]] && [[ -n "${chrome_extensions}" ]]; then
        multilineValue+=$'\n'
        multilineValue+="$chrome_title:"
        multilineValue+=$'\n'
        multilineValue+=$(
            # Convert the chrome_extensions string to a table format. Skip the first line as it is the header
            echo "$chrome_extensions" | tail -n +2 | while IFS='|' read -r user_name profileName name id version; do
                if [[ -n "$name" ]]; then
                    printf "User: %s, Profile Name: %s, Name: %s, Id: %s, Version: %s\n" "$user_name" "$profileName" "$name" "$id" "$version"
                fi
            done
        )
    fi
    if [[ -n "$firefox_title" ]] && [[ -n "${firefox_addons}" ]]; then
        multilineValue+=$'\n'
        multilineValue+="$firefox_title:"
        multilineValue+=$'\n'
        multilineValue+=$(
            # Convert the firefox_addons string to a table format. Skip the first line as it is the header
            echo "$firefox_addons" | tail -n +2 | while IFS='|' read -r user profileName name id description; do
                if [[ -n "$name" ]]; then
                    printf "User: %s, Profile Name: %s, Name: %s, Id: %s, Description: %s\n" "$user" "$profileName" "$name" "$id" "$description"
                fi
            done
        )
    fi
    if [[ -n "$edge_title" ]] && [[ -n "${edge_extensions}" ]]; then
        multilineValue+=$'\n'
        multilineValue+="$edge_title:"
        multilineValue+=$'\n'
        multilineValue+=$(
            # Convert the edge_extensions string to a table format. Skip the first line as it is the header
            echo "$edge_extensions" | tail -n +2 | while IFS='|' read -r user_name profileName name id version; do
                if [[ -n "$name" ]]; then
                    printf "User: %s, Profile Name: %s, Name: %s, Id: %s, Version: %s\n" "$user_name" "$profileName" "$name" "$id" "$version"
                fi
            done
        )
    fi
    # if all multilineValue is empty, set it to "No browser extensions found"
    if [[ -z "$multilineValue" ]]; then
        multilineValue="No browser extensions found"
    fi

    # Tries to set the multiline custom field using ninjarmm-cli and captures the output
    if ! output=$(printf '%b' "$multilineValue" | /Applications/NinjaRMMAgent/programdata/ninjarmm-cli set --stdin "$_arg_multilineField" 2>&1); then
        echo "[Error] $output" >&2
        EXITCODE=1
    else
        echo "[Info] Successfully set Custom Field '$_arg_multilineField'!"
    fi
fi

# Checks if there is a WYSIWYG custom field set
if [[ -n $_arg_wysiwygField ]]; then
    echo ""
    echo "Attempting to set Custom Field '$_arg_wysiwygField'..."

    # Initializes an HTML formatted string with headers and extension details
    # Check if any browser extensions were found
    if [[ -n "$safari_title" ]] && [[ -n "${safari_extensions}" ]]; then
        htmlObject+="<h2>$safari_title</h2>"
        htmlObject+=$(echo "$safari_extensions" | convertToHTMLTable --delimiter '|')
    fi
    if [[ -n "$chrome_title" ]] && [[ -n "${chrome_extensions}" ]]; then
        htmlObject+="<h2>$chrome_title</h2>"
        htmlObject+=$(echo "$chrome_extensions" | convertToHTMLTable --delimiter '|')
    fi
    if [[ -n "$firefox_title" ]] && [[ -n "${firefox_addons}" ]]; then
        htmlObject+="<h2>$firefox_title</h2>"
        htmlObject+=$(echo "$firefox_addons" | convertToHTMLTable --delimiter '|')
    fi
    if [[ -n "$edge_title" ]] && [[ -n "${edge_extensions}" ]]; then
        htmlObject+="<h2>$edge_title</h2>"
        htmlObject+=$(echo "$edge_extensions" | convertToHTMLTable --delimiter '|')
    fi
    # if all htmlObject is empty, set it to "No browser extensions found"
    if [[ -z "$htmlObject" ]]; then
        htmlObject="<p>No browser extensions found</p>"
    fi
    # Replace <table> with <table style='white-space:nowrap;'>
    htmlObject=${htmlObject//<table>/<table style=\'white-space:nowrap;\'>}
    # Tries to set the WYSIWYG custom field using ninjarmm-cli and captures the output
    if ! output=$(printf '%b' "$htmlObject" | /Applications/NinjaRMMAgent/programdata/ninjarmm-cli set --stdin "$_arg_wysiwygField" 2>&1); then
        echo "[Error] $output" >&2
        EXITCODE=1
    else
        echo "[Info] Successfully set Custom Field '$_arg_wysiwygField'!"
    fi
fi

# If both _arg_multilineField and _arg_wysiwygField are not set, or if there is an error saving to the custom fields, print the results
if [[ -z $_arg_multilineField && -z $_arg_wysiwygField ]] || [[ $EXITCODE -ne 0 ]]; then
    echo ""
    echo "$safari_title:"
    echo "$safari_extensions" | while IFS='|' read -r user name id; do
        if [[ -n "$name" ]]; then
            printf "User: %s, Name: %s, Id: %s\n" "$user" "$name" "$id"
        fi
    done
    echo ""
    echo "$chrome_title:"
    echo "$chrome_extensions" | while IFS='|' read -r user profileName name id version; do
        if [[ -n "$name" ]]; then
            printf "User: %s, Profile Name: %s, Name: %s, Id: %s, Version: %s\n" "$user" "$profileName" "$name" "$id" "$version"
        fi
    done
    echo ""
    echo "$firefox_title:"
    echo "$firefox_addons" | while IFS='|' read -r user profileName name id description; do
        if [[ -n "$name" ]]; then
            printf "User: %s, Profile Name: %s, Name: %s, Id: %s, Description: %s\n" "$user" "$profileName" "$name" "$id" "$description"
        fi
    done
    echo ""
    echo "$edge_title:"
    echo "$edge_extensions" | while IFS='|' read -r user profileName name id version; do
        if [[ -n "$name" ]]; then
            printf "User: %s, Profile Name: %s, Name: %s, Id: %s, Version: %s\n" "$user" "$profileName" "$name" "$id" "$version"
        fi
    done
    # If no extensions are found, print a message
    if [[ -z "$safari_extensions" ]] && [[ -z "$chrome_extensions" ]] && [[ -z "$firefox_addons" ]] && [[ -z "$edge_extensions" ]]; then
        echo "[Info] No Browser Extensions Found"
    fi
fi

# Checks if an error code is set and exits the script with that code
if [[ -n $EXITCODE ]]; then
    echo "[Error] Failed to save browser extensions to custom field '$_arg_multilineField' or '$_arg_wysiwygField'."
    exit "$EXITCODE"
fi





