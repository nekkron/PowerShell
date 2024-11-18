#!/usr/bin/env bash
#
# Description: Outputs messages on all connected terminals and creates a popup window on the end-user's screen. The popup requires ImageMagick and supports X11 KDE & X11 Gnome environments; other environments will only display the terminal message. Use the "Restart Reminder" feature to trigger a generic restart prompt.
#
# Preset Parameter: --restartreminder
#   Displays a generic restart PopUp. Can be overridden with parameters. Equivalent to the below parameters.
#   --title 'NinjaOne Rmm'
#   --message 'Your IT Administrator has scheduled a restart of your computer in the next 15 minutes. Please save your work as soon as possible to prevent data loss.'
#   --timeoutaction 'shutdown -r'
#
# Preset Parameter: --title 'ReplaceWithYourDesiredHeader'
#   Replace the text encased in quotes to replace the text in the title bar of the popup window (defaults to 'NinjaOne RMM').
#
# Preset Parameter: --message 'ReplaceWithYourPopUpMessage'
#   Replace the text encased in quotes to put some text inside of the PopUp Window.
#
# Preset Parameter: --iconpath 'A URL or /a/path/to/an/image.png'
#   Replace the text encased in quotes with either a url to an image or a filepath to an icon. The script uses the NinjaOne Logo by default.
#   For best results use a 128px x 128px png. Though other formats and sizes will work.
#   Highly recommend keeping a 1:1 ratio for the width and height.
#   Supported formats: png, jpg, jpeg, webp, bmp, ico and gif (will not be animated in popup)
#   If you have a base64 encoding of your image you could also replace the default base64 on line 37.
#
# Preset Parameter: --timeout 'ReplaceWithAnumberofSeconds'
#   Replace the text encased in quotes with the number of seconds you'd like the PopUp to display for.
#
# Preset Parameter: --okbuttonaction 'ReplaceWithYourDesiredAction(Executes in Bash)'
#   Replace the text encased in quotes with the command you'd like to run when the left button is clicked by the user (executes in bash).
#
# Preset Parameter: --exitbuttonaction 'ReplaceWithYourDesiredAction(Executes in Bash)'
#   Replace the text encased in quotes with the command you'd like to run when the popup window is closed (executes in bash).
#
# Preset Parameter: --timeoutaction 'ReplaceWithYourDesiredAction(Executes in Bash)'
#   Replace the text encased in quotes with the command you'd like to run when the dialog box times out (executes in bash).

# You can replace the below line with iconbase64='ReplaceThisWithYourBase64encodedimageEncasedInQuotes' and the script will decode the image and use it in the popup window.
iconbase64='iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAAAJFBMVEUARF0Apc0AmL8ApM0Aos0Aps7///8Am8ia1ug9rtLd8/jw+/2tMDHwAAAABXRSTlMBrBTIcce4nvwAAAIeSURBVHic7dvrcoMgEAXgiOAivv/7Fm+JBpCLwk7bsz86rcNkPw+Y0Gl5vd4lGtbLKSG7vmF18mwQnWpe3YcghP2Z1svU8OtbIOihm8op25M2gWBov9UqYJj/vSRzAGsEkhMglxngWINbdbxLAAAAAAAAAAAAAKAI8Oz2KRtApPWThEyAbT8NZwDZGpeav6sLIKXNMBwAtuGotTGTvTpMRms9qkxEBsDe/dz+A7B3rufeS/utrCKPkAywzfYmK8BeOHY+lBkzBImALfwDgA4XnNLphCTA4e43AKmL9vNMJD8pCQAna20nP5D+SfkQgJyp1qS9PYsEKQDnpVP627WYJCgBmGj+GRmUAFIraSXWBAwDcwJJk1AXMIzcgHgElQHxCGoDohHcBsybgIvPpei70S2A0csuaNkTBRBTbA7uAOb271E0+gWxOSgHfG87yD+wGsCz7fGONNf9iwGTb89DnlkwkUVQCPD2t1sXz9A6gMDT5YsgsggKARljI/vTMkDo7cU3B1USCL+oOwdVAMGF5RlcAxB+tBoBwq/JDlDcAPYEAGgDuPiNBwkgASSABJAAEkACSAAJIAEkgASQABL4JwlcA9w/9N4GTOZcl1OQMTgRoEannhv9O/+PCAAAAAAAAAAAAACAPwhgP+7HeOCR1jOfjBHI9dBrz9W/34/d9jyHLvvPweP2GdCx/3zyvLlAfZ8+l13LktJzAJ+nfgAP50EVLvPsRgAAAABJRU5ErkJggg=='
workingdir="/tmp/ninjaone-rmm-popup"

die() {
    local _ret="${2:-1}"
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    echo "$1" >&2
    exit "${_ret}"
}

# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_title="NinjaOne RMM"
_arg_message=
_arg_iconpath=
_arg_obuttonaction=
_arg_ebuttonaction=
_arg_timeoutaction=
_arg_timeout=900
_arg_restartreminder="off"

# The function will print out some help text if the user entered in something wrong
print_help() {
    printf '\t%s\n\n' 'Usage: [-t|--title <arg>] [-m|-msg|--message <arg>] [-i|-icon|--iconpath <arg>] [-ea | -ebtnact | -extbtnaction | --exitbuttonaction <arg>] [-oa | -okbtnact | -okbtnaction | --okbuttonaction <arg>] [-to | --timeout <arg>] [-toa | -toact| --timeoutaction <arg>] [ -restart | --restartreminder] [-h|--help]'
    printf '%s\n' "Preset Parameter: --restartreminder"
    printf '\t%s\n' "Displays a generic restart PopUp. Can be overridden with parameters. Equivelant to the below parameters."
    printf '\t%s\n' "--title 'NinjaOne Rmm'"
    printf '\t%s\n' "--message 'Your IT Administrator has scheduled a restart of your computer in the next 15 minutes. Please save your work as soon as possible to prevent data loss.'"
    printf '\t%s\n' "--timeoutaction 'shutdown -r'"
    printf '%s\n' "Preset Parameter: --title 'ReplaceWithYourDesiredHeader'"
    printf '\t%s\n' "Replace the text encased in quotes to replace the text in the title bar of the popup window (defaults to 'NinjaOne RMM')"
    printf '%s\n' "Preset Parameter: --message 'ReplaceWithYourPopUpMessage'"
    printf '\t%s\n' "Replace the text encased in quotes to put some text inside of the PopUp Window"
    printf '%s\n' "Preset Parameter: --iconpath 'A URL or /a/path/to/an/image.png'"
    printf '\t%s\n' "Replace the text encased in quotes with either a url to an image or a filepath to an icon. The script uses the NinjaOne Logo by default."
    printf '%s\n' "Preset Parameter: --timeout 'ReplaceWithAnumberofSeconds'"
    printf '\t%s\n' "Replace the text encased in quotes with the number of seconds you'd like the PopUp to display for."
    printf '%s\n' "Preset Parameter: --okbuttonaction 'ReplaceWithYourDesiredAction(Executes in Bash)'"
    printf '\t%s\n' "Replace the text encased in quotes with the command you'd like to run when the ok button is clicked by the user (executes in bash)."
    printf '%s\n' "Preset Parameter: --exitbuttonaction 'ReplaceWithYourDesiredAction(Executes in Bash)'"
    printf '\t%s\n' "Replace the text encased in quotes with the command you'd like to run when the user closes the dialog (executes in bash)."
    printf '%s\n' "Preset Parameter: --timeoutaction 'ReplaceWithYourDesiredAction(Executes in Bash)'"
    printf '\t%s\n' "Replace the text encased in quotes with the command you'd like to run when the dialog box times out (executes in bash)."
}

# decipher's the parameters given and stores them as variables
parse_commandline() {
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        -t | --title)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_title="$2"
            shift
            ;;
        --title=*)
            _arg_title="${_key##--title=}"
            ;;
        -m | -msg | --message)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_message="$2"
            shift
            ;;
        --message=*)
            _arg_message="${_key##--message=}"
            ;;
        --msg=*)
            _arg_message="${_key##--msg=}"
            ;;
        -i | -icon | --iconpath)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_iconpath="$2"
            shift
            ;;
        --iconpath=*)
            _arg_iconpath="${_key##--iconpath=}"
            ;;
        --icon=*)
            _arg_iconpath="${_key##--icon=}"
            ;;
        -ea | -ebtnact | -extbtnaction | --exitbuttonaction)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_ebuttonaction="$2"
            shift
            ;;
        --exitbuttonaction=*)
            _arg_ebuttonaction="${_key##--ebuttonaction=}"
            ;;
        -oa | -okbtnact | -okbtnaction | --okbuttonaction)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_obuttonaction="$2"
            shift
            ;;
        --okbuttonaction=*)
            _arg_obuttonaction="${_key##--obuttonaction=}"
            ;;
        -to | --timeout)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_timeout="$2"
            shift
            ;;
        --timeout=*)
            _arg_timeout="${_key##--timeout=}"
            ;;
        -toa | -toact | --timeoutaction)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_timeoutaction="$2"
            shift
            ;;
        --timeoutaction=*)
            _arg_timeoutaction="${_key##--timeoutaction=}"
            ;;
        -restart | --restartreminder)
            _arg_restartreminder="on"
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

# Initializes parameter processing
parse_commandline "$@"

if [[ -n $title ]]; then
    _arg_title=$title
fi

if [[ -n $message ]]; then
    _arg_message=$message
fi

if [[ -n $iconPath ]]; then
    _arg_iconpath=$iconPath
fi

if [[ -n $timeout ]]; then
    _arg_timeout=$timeout
fi

if [[ -n $timeoutAction ]]; then
    _arg_timeoutaction=$timeoutAction
fi

if [[ -n $okButtonAction ]]; then
    _arg_obuttonaction=$okButtonAction
fi

if [[ -n $exitButtonAction ]]; then
    _arg_ebuttonaction=$exitButtonAction
fi

if [[ -n $restartReminder && $restartReminder == "true" ]]; then
    _arg_restartreminder="on"
fi

# If --restartreminder was selected we'll want to preset some of the parameters
if [[ $_arg_restartreminder == "on" ]]; then
    if [[ -z $_arg_message ]]; then
        _arg_message="Your IT Administrator has scheduled a restart of your computer in the next 15 minutes. Please save your work as soon as possible to prevent data loss."
    fi

    if [[ -z $_arg_timeoutaction ]]; then
        _arg_timeoutaction='shutdown -r'
    fi
fi

# Grabbing information about the current setup
activeUsers=$(loginctl list-sessions | grep seat | sed 's/[0-9]\+//g' | sed 's/seat//g' | sed 's/tty//g' | xargs)
activeDisplay=$(w -oush | grep -Eo ' :[0-9]+' | uniq | head -1 | xargs)
GNOME=$(command -v zenity)
KDE=$(command -v kdialog)
imageMagick=$(command -v convert)

# Must give a number
pattern='^[0-9]+$'
if [[ ! $_arg_timeout =~ $pattern ]]; then
    _PRINT_HELP=no die "FATAL ERROR: --timeout requires a number of seconds in order to work. ex. '60' for 60 seconds." 1
fi

# No matter what we're going to send a message to all connected terminals
echo "Sending message to all connected terminals."
wall "$_arg_message"
if [[ -z $imageMagick ]]; then
    echo "WARNING: Image Magick is not installed. This script will be unable to display a popup without it. This script will still be able to send a message to all ssh connected terminals."
fi

# If not on a supported desktop environment or simply nobodies logged in skip this whole block.
if [[ (-n $GNOME || -n $KDE) && -n $activeDisplay && -n $activeUsers && -n $imageMagick ]]; then
    # Create's a working directory if it doesn't already exist
    if [[ ! -d "$workingdir" ]]; then
        mkdir $workingdir
    fi

    # If given a url attempt to download the image file
    pattern="https?://.*"
    if [[ $_arg_iconpath =~ $pattern ]]; then
        wget -q "$_arg_iconpath" -O "$workingdir/downloadedimg" -t 7 --random-wait
        _arg_iconpath=$workingdir/downloadedimg
    fi

    # If a base64 icon is provided and no other iconpath was specified use that.
    if [[ -n $iconbase64 && -z $_arg_iconpath ]]; then
        base64 -d <<<$iconbase64 >$workingdir/base64img
        _arg_iconpath=$workingdir/base64img
    # If an iconpath was provided copy it to the working directory
    elif [[ ! $_arg_iconpath == "$workingdir/downloadedimg" ]]; then
        cp "$_arg_iconpath" "$workingdir/downloadedimg"
        _arg_iconpath="$workingdir/downloadedimg"
    fi

    # Dobule check that we were given an image and find it's extension
    mimetype=$(file --mime-type -b "$_arg_iconpath" | grep "image")
    extension=$(file --extension -b "$_arg_iconpath" | sed 's/\/.*//g')

    # If the mimetype indicates its not an image error out
    if [[ -z $mimetype ]]; then
        _PRINT_HELP=no die "FATAL ERROR: No image found!" 1
    # If it's not a png we'll need to convert it to one and it'll need to be 128x128.
    elif [[ ! $extension == "png" ]]; then
        cp "$_arg_iconpath" "$workingdir/img.$extension"
        convert -resize 128x128! -background none -coalesce "$workingdir/img.$extension" "$workingdir/img.png"
        # Some image types ex. .ico files will have multiple pngs embeded in it. This ensures only one is selected.
        _arg_iconpath=$(find $workingdir/img*.png | tail -1)
    fi

    # If post conversion we don't have an image we can use error out
    if [[ -n $_arg_iconpath ]]; then
        mv "$_arg_iconpath" "$workingdir/$_arg_title.png"
        convert "$workingdir/$_arg_title.png" -resize 128x128! "/usr/share/pixmaps/$_arg_title.png"
        _arg_iconpath="/usr/share/pixmaps/$_arg_title.png"
    else
        _PRINT_HELP=no die "FATAL ERROR: Image missing after converting to png?" 1
    fi

    # If using the Gnome Desktop enviornment we'll need to use zenity otherwise we can use kdialog.
    if [[ -n $GNOME ]]; then
        export DISPLAY="$activeDisplay"
        for user in $activeUsers; do
            popup=$(
                $popup
                su "$user" -c 'xhost local:'"$user"'; zenity --window-icon "'"$_arg_iconpath"'" --title "'"$_arg_title"'" --icon-name "'"$_arg_title"'" --info --text "'"$_arg_message"'" --timeout "'"$_arg_timeout"'"'
                echo -e "\n$?"
            )
        done
    elif [[ -n $KDE ]]; then
        export DISPLAY="$activeDisplay"
        for user in $activeUsers; do
            popup=$(
                $popup
                # kdialog doesn't seem to have an option for an actual dialog to time out so we'll make a popup message instead
                su "$user" -c 'xhost local:'"$user"'; kdialog --icon "'"$_arg_iconpath"'" --title "'"$_arg_title"'" --passivepopup "'"$_arg_message"'" '"$_arg_timeout"''
                echo -e "\n$?"
            )
        done
    fi

    # This grabs the exitcode for each time the dialog was ran
    results=$(echo "$popup" | grep -Eo '[0-9]')
    for result in $results; do
        if [[ $result == -1 || $result == 254 ]]; then
            _PRINT_HELP=no die "FATAL ERROR: Unable to display popup?" 1
        fi

        # Kdialog will give an exit code of 2 when exiting while Gnome will give an exit code of 1
        if [[ -n $_arg_ebuttonaction && ($result == 1 || $result == 2) ]]; then
            echo "Exit Button Clicked"
            eval "$_arg_ebuttonaction"
        elif [[ $result == 1 || $result == 2 ]]; then
            echo "Exit Button Clicked"
        fi

        if [[ -n $_arg_obuttonaction && $result == 0 && -n $GNOME ]]; then
            echo "OK Button Clicked"
            eval "$_arg_obuttonaction"
        elif [[ $result == 0 && -n $GNOME ]]; then
            echo "OK Button Clicked"
        fi

        if [[ -n $_arg_timeoutaction && $result == 5 || (-n $KDE && $result == 0) ]]; then
            echo "Pop-up has timed out! Executing timeout action...."
            eval "$_arg_timeoutaction"
        elif [[ $result == 5 || (-n $KDE && $result == 0) ]]; then
            echo "Pop-up has timed out!"
        fi
    done

    # Removes the old icon
    rm "$_arg_iconpath"
else
    echo "No active X11 displays using GNOME or KDE were found. This script will display a terminal message only."
    if [[ ! $_arg_timeout == 0 ]]; then
        echo "Sleeping for $_arg_timeout seconds..."
        sleep "$_arg_timeout"
    fi
    if [[ -n $_arg_timeoutaction ]]; then
        echo "Executing timeout action."
        eval "$_arg_timeoutaction"
    fi
fi





