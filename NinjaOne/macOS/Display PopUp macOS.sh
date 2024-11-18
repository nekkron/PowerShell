#!/usr/bin/env bash
#
# Description: Creates a popup window on the user's screen. Use Restart Reminder to display a request to the end user to restart their computer. Please run as 'System'.
#
# Preset Parameter: --restartreminder
#   Displays a generic restart PopUp. Can be overridden with parameters. Equivalent to the below parameters.
#   --title 'NinjaOne Rmm'
#   --message 'Your IT Administrator is requesting that you restart your computer. Click "Restart Now" after saving your work.'
#   --buttonltext 'Restart Now'
#   --buttonrtext 'Ignore'
#   --buttonlaction 'shutdown -r now'
#   --timeout 900
#
# Preset Parameter: --title 'ReplaceWithYourDesiredHeader'
#   Replace the text encased in quotes to replace the text in the title bar of the popup window (defaults to 'NinjaOne RMM').
#
# Preset Parameter: --message 'ReplaceWithYourPopUpMessage'
#   Replace the text encased in quotes to put some text inside of the PopUp Window.
#
# Preset Parameter: --iconpath 'A URL or /a/path/to/an/image.png'
#   Replace the text encased in quotes with either a url to an image or a filepath to an icon. The script uses the NinjaOne Logo by default.
#   For best results use a 512px x 512px png. Though other formats and sizes will work.
#   Highly recommend keeping a 1:1 ratio for the width and height.
#   Supported formats: png, jpg, jpeg, webp, bmp, ico and gif (will not be animated in popup)
#   If you have a base64 encoding of your image you could also replace the default base64 on line 46.
#
# Preset Parameter: --buttonltext 'ReplaceWithNameOfButton'
#   Replace the text encased in quotes with the name/text inside the left button.
#
# Preset Parameter: --buttonrtext 'ReplaceWithNameOfButton'
#   Replace the text encased in quotes with the name/text inside the right button.
#
# Preset Parameter: --timeout 'ReplaceWithAnumberofSeconds'
#   Replace the text encased in quotes with the number of seconds you'd like the PopUp to display for. 0 never times out.
#
# Preset Parameter: --buttonlaction 'ReplaceWithYourDesiredAction(Executes in Bash)'
#   Replace the text encased in quotes with the command you'd like to run when the left button is clicked by the user (executes in bash).
#
# Preset Parameter: --buttonraction 'ReplaceWithYourDesiredAction(Executes in Bash)'
#   Replace the text encased in quotes with the command you'd like to run when the right button is clicked by the user (executes in bash).
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
_arg_buttonrtext=
_arg_buttonraction=
_arg_buttonltext=
_arg_buttonlaction=
_arg_timeoutaction=
_arg_timeout=900
_arg_restartreminder="off"

# This function will print out some help text if the user entered something wrong
print_help() {
  printf '\t%s\n\n' 'Usage: [-t|--title <arg>] [-m|-msg|--message <arg>] [-i|-icon|--iconpath <arg>] [-blt|-btnltxt|--buttonltext <arg>] [-brt|-btnrtxt|--buttonrtext <arg>] [-bla|-btnlact|--buttonlaction <arg>] [-bra|-btnract|--buttonraction <arg>] [-to|--timeout <arg>] [-toa|-toact|--timeoutaction <arg>] [-restart|--restartreminder] [-h|--help]'
  printf '\t%s\n' "Preset Parameter: --restartreminder"
  printf '\t\t%s\n' "Displays a generic restart PopUp. Can be overridden with parameters. Equivalent to the below parameters."
  printf '\t\t%s\n' "--title 'NinjaOne RMM'"
  printf '\t\t%s\n' "--message 'Your IT Administrator is requesting that you restart your computer. Click 'Restart Now' after saving your work.'"
  printf '\t\t%s\n' "--buttonltext 'Restart Now'"
  printf '\t\t%s\n' "--buttonrtext 'Ignore'"
  printf '\t\t%s\n' "--buttonlaction 'shutdown -r now'"
  printf '\t\t%s\n' "--timeout '900'"
  printf '\t%s\n' "Preset Parameter: --title 'ReplaceWithYourDesiredHeader'"
  printf '\t\t%s\n' "Replace the text encased in quotes to replace the text in the title bar of the popup window (defaults to 'NinjaOne RMM')"
  printf '\t%s\n' "Preset Parameter: --message 'ReplaceWithYourPopUpMessage'"
  printf '\t\t%s\n' "Replace the text encased in quotes to put some text inside of the PopUp Window"
  printf '\t%s\n' "Preset Parameter: --iconpath 'A URL or /a/path/to/an/image.png'"
  printf '\t\t%s\n' "Replace the text encased in quotes with either a url to an image or a filepath to an icon. The script uses the NinjaOne Logo by default."
  printf '\t%s\n' "Preset Parameter: --buttonltext 'ReplaceWithNameOfButton'"
  printf '\t\t%s\n' "Replace the text encased in quotes with the name/text inside the left button."
  printf '\t%s\n' "Preset Parameter: --buttonrtext 'ReplaceWithNameOfButton'"
  printf '\t\t%s\n' "Replace the text encased in quotes with the name/text inside the right button."
  printf '\t%s\n' "Preset Parameter: --timeout 'ReplaceWithAnumberofSeconds'"
  printf '\t\t%s\n' "Replace the text encased in quotes with the number of seconds you'd like the PopUp to display for. 0 never times out."
  printf '\t%s\n' "Preset Parameter: --buttonlaction 'ReplaceWithYourDesiredAction(Executes in Bash)'"
  printf '\t\t%s\n' "Replace the text encased in quotes with the command you'd like to run when the left button is clicked by the user (executes in bash)."
  printf '\t%s\n' "Preset Parameter: --buttonraction 'ReplaceWithYourDesiredAction(Executes in Bash)'"
  printf '\t\t%s\n' "Replace the text encased in quotes with the command you'd like to run when the right button is clicked by the user (executes in bash)."
  printf '\t%s\n' "Preset Parameter: --timeoutaction 'ReplaceWithYourDesiredAction(Executes in Bash)'"
  printf '\t\t%s\n' "Replace the text encased in quotes with the command you'd like to run when the dialog box times out (executes in bash)."
}

# Deciphers the parameters given and stores them as variables
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
    -blt | -btnltxt | --buttonltext)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_buttonltext="$2"
      shift
      ;;
    --buttonltext=*)
      _arg_buttonltext="${_key##--buttonltext=}"
      ;;
    -bla | -btnlact | -btnlaction | --buttonlaction)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_buttonlaction="$2"
      shift
      ;;
    --buttonlaction=*)
      _arg_buttonlaction="${_key##--buttonlaction=}"
      ;;
    -brt | -btnrtxt | -btnrtext | --buttonrtext)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_buttonrtext="$2"
      shift
      ;;
    --buttonrtext=*)
      _arg_buttonrtext="${_key##--buttonrtext=}"
      ;;
    -bra | -btnract | -btnraction | --buttonraction)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_buttonraction="$2"
      shift
      ;;
    --buttonraction=*)
      _arg_buttonraction="${_key##--buttonraction=}"
      ;;
    -to | --timeout)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_timeout="$2"
      shift
      ;;
    --timeout=*)
      _arg_timeout="${_key##--timeout=}"
      ;;
    -toa | -toact | --timeoutaction | --timeoutAction)
      test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
      _arg_timeoutaction="$2"
      shift
      ;;
    --timeoutaction=*)
      _arg_timeoutaction="${_key##--timeoutaction=}"
      ;;
    -restart | --restartreminder | --restartReminder)
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

parse_commandline "$@"

# This function will be used to download an image file if requested.
downloadFile() {
  i=1
  while [[ $i -lt 4 ]]; do
    if [[ ! $_arg_skipsleep == "on" ]]; then
      sleepTime=$((1 + RANDOM % 7))
      echo "Sleeping for $sleepTime seconds."
      sleep $sleepTime
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

if [[ -n $title ]]; then
  _arg_title=$title
fi

if [[ -n $message ]]; then
  _arg_message=$message
fi

if [[ -n $iconPath ]]; then
  _arg_iconpath=$iconPath
fi

if [[ -n $buttonLeftText ]]; then
  _arg_buttonltext=$buttonLeftText
fi

if [[ -n $buttonLeftAction ]]; then
  _arg_buttonlaction=$buttonLeftAction
fi

if [[ -n $buttonRightText ]]; then
  _arg_buttonrtext=$buttonRightText
fi

if [[ -n $buttonRightAction ]]; then
  _arg_buttonraction=$buttonRightAction
fi

if [[ -n $timeout ]]; then
  _arg_timeout=$timeout
fi

if [[ -n $timeoutAction ]]; then
  _arg_timeoutaction=$timeoutAction
fi

if [[ -n $restartReminder && $restartReminder == "true" ]]; then
  _arg_restartreminder="on"
fi

# If --restartreminder was selected we'll want to preset some of the parameters.
if [[ $_arg_restartreminder == "on" ]]; then
  if [[ -z $_arg_buttonltext ]]; then
    _arg_buttonltext="Restart Now"
  fi

  if [[ -z $_arg_buttonrtext ]]; then
    _arg_buttonrtext="Ignore"
  fi

  if [[ -z $_arg_message ]]; then
    _arg_message="Your IT Administrator is requesting that you restart your computer. Click 'Restart Now' after saving your work."
  fi

  if [[ -z $_arg_buttonlaction ]]; then
    _arg_buttonlaction='shutdown -r $(date -v +30S "+%H%M")'
  fi

  if [[ -z $_arg_timeout ]]; then
    _arg_timeout=900
  fi
fi

# Cannot name the button cancel.
if [[ $_arg_buttonltext == "Cancel" || $_arg_buttonrtext == "Cancel" ]]; then
  _PRINT_HELP=no die "FATAL ERROR: Cannot name the button 'Cancel' or we'll be unable to check the dialog response." 1
fi

# Must give a number
pattern='^[0-9]+$'
if [[ ! $_arg_timeout =~ $pattern ]]; then
  _PRINT_HELP=no die "FATAL ERROR: --timeout requires a number of seconds in order to work. ex. '60' for 60 seconds." 1
fi

# Creates a working directory that we'll use for our icons
if [[ ! -d "$workingdir" ]]; then
  mkdir $workingdir
fi

# If we were given a url we'll want to download it. Since we don't really know the file we'll just not give it an extension.
pattern='^http(.?)://(.*)'
if [[ $_arg_iconpath =~ $pattern ]]; then
  echo "URL Given, downloading image..."

  url=$_arg_iconpath
  _arg_destfolder=$workingdir
  _arg_filename="downloadedimg"

  downloadFile
  _arg_iconpath=$workingdir/downloadedimg
fi

# If the script was given an iconpath as a parameter we'll want to use that instead.
if [[ -n $iconbase64 && -z $_arg_iconpath ]]; then
  base64 -D <<<$iconbase64 >$workingdir/base64img
  _arg_iconpath=$workingdir/base64img
elif [[ ! $_arg_iconpath == "$workingdir/downloadedimg" ]]; then
  cp "$_arg_iconpath" "$workingdir"
fi

# This will be used to check that the file is an image or something else
mimetype=$(file --mime-type -b "$_arg_iconpath" | grep "image" | sed 's/image\///g')
if [[ -z $mimetype ]]; then
  _PRINT_HELP=no die "FATAL ERROR: File was either not an image or does not exist!" 1
fi

# Convert whatever we were given into a png (so we can later turn that into an icon file)
if [[ ! $mimetype == "png" ]]; then
  sips -s format png "$_arg_iconpath" --out "$workingdir/img.png" >/dev/null
  rm "$_arg_iconpath"
else
  mv "$_arg_iconpath" "$workingdir/img.png"
fi

# Working folder for the iconset
if [[ ! -d "$workingdir/$_arg_title.iconset" ]]; then
  mkdir "$workingdir/$_arg_title.iconset"
fi

# If the file was successfully converted we'll turn it into an icon file
file=$workingdir/img.png
if [[ -f $file ]]; then
  sips -z 16 16 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_16x16.png" >/dev/null
  sips -z 32 32 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_32x32.png" >/dev/null
  sips -z 64 64 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_128x128.png" >/dev/null
  sips -z 256 256 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_256x256.png" >/dev/null
  sips -z 512 512 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "${workingdir}/img.png" --out "${workingdir}/${_arg_title}.iconset/icon_512x512.png" >/dev/null

  rm "$workingdir/img.png"

  cd "$workingdir" >/dev/null || _PRINT_HELP=no die "FATAL ERROR: Unable to access $workingdir" 1
  iconutil -c icns "$_arg_title.iconset"
  cd - >/dev/null || _PRINT_HELP=no die "FATAL ERROR: Unable to access previous working directory?" 1

  rm -R "$workingdir/$_arg_title.iconset"
  _arg_iconpath=$workingdir/$_arg_title.icns
else
  _PRINT_HELP=no die "FATAL ERROR: Looks like the image failed to convert to a png?" 1
fi

# If no button text was given these will be the defaults
if [[ -z $_arg_buttonltext ]]; then
  _arg_buttonltext="Ignore"
fi

if [[ -z $_arg_buttonrtext ]]; then
  _arg_buttonrtext="Accept"
fi

# osascript actually creates the dialog box we'll need all the variables from earlier for that.
dialog="$(
  osascript - "$_arg_message" "$_arg_title" "$_arg_iconpath" "$_arg_buttonltext" "$_arg_buttonrtext" "$_arg_timeout" <<EOF
  on run argv
    display dialog item 1 of argv with title item 2 of argv \
    with icon POSIX file { item 3 of argv } \
    buttons { item 4 of argv , item 5 of argv } default button 2 \
    giving up after { item 6 of argv }
  end run
EOF
)"

# These three if statements check what the response to the PopUp was and performs an action based on that if requested.
if [[ $dialog == *"gave up:true" ]]; then
  echo "PopUp message timed out (the user ignored it)."
  if [[ -n $_arg_timeoutaction ]]; then
    eval "$_arg_timeoutaction"
  fi
  exit 0
fi

if [[ $dialog == "button returned:$_arg_buttonltext"* ]]; then
  echo "$_arg_buttonltext Button Clicked!"
  if [[ -n $_arg_buttonlaction ]]; then
    eval "$_arg_buttonlaction"
  fi
  exit 0
fi

if [[ $dialog == "button returned:$_arg_buttonrtext"* ]]; then
  echo "$_arg_buttonrtext Button Clicked!"
  if [[ -n $_arg_buttonraction ]]; then
    eval "$_arg_buttonraction"
  fi
  exit 0
fi

_PRINT_HELP=no die "FATAL ERROR: Did the PopUp display? Failed to check the dialog response." 1





