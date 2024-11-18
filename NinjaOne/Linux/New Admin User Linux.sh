#!/usr/bin/env bash
#
# Description: Create a new admin user for Linux, by adding the user to the sudo group.

# Usage: [-u|--user <arg>] [-p|--pass <arg>] [-g|--group <arg>] [-d|--disable <arg>] [-h|--help]
# -u, --user: User Name for new user account. (no default)
# -p, --pass: Password for new user account. (no default)
# -g, --group: Name of group to add the new user account to. (default 'sudo')
# -d, --disable: Date to disable account. (no default)
# -h, --help: Prints help

# # When called, the process ends.
# Args:
# 	$1: The exit message (print to stderr)
# 	$2: The exit code (default is 1)
# if env var _PRINT_HELP is set to 'yes', the usage is print to stderr (prior to $1)
# Example:
# 	test -f "$_arg_infile" || _PRINT_HELP=yes die "Can't continue, have to supply file as an argument, got '$_arg_infile'" 4
die() {
    local _ret="${2:-1}"
    test "${_PRINT_HELP:-no}" = yes && print_help >&2
    echo "$1" >&2
    exit "${_ret}"
}

# Function that evaluates whether a value passed to it begins by a character
# that is a short option of an argument the script knows about.
# This is required in order to support getopts-like short options grouping.
begins_with_short_option() {
    local first_option all_short_options='uph'
    first_option="${1:0:1}"
    test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}
_arg_user=
_arg_pass=
_arg_group="sudo"
_arg_disable=

if [[ -n "${username}" ]]; then
    _arg_user=$username
fi
if [[ -n "${password}" ]]; then
    _arg_pass=$password
fi
if [[ -n "${group}" ]] && [[ "${group}" != "null" ]]; then
    _arg_group=$group
fi
if [[ -n "${disableAfterDate}" ]] && [[ "${disableAfterDate}" != "null" ]]; then
    _arg_disable=$(date -d "$disableAfterDate" +'%Y-%m-%d')
fi

# Function that prints general usage of the script.
# This is useful if users asks for it, or if there is an argument parsing error (unexpected / spurious arguments)
# and it makes sense to remind the user how the script is supposed to be called.
print_help() {
    printf '%s\n' "Create a new admin user."
    printf 'Usage: %s [-u|--user <arg>] [-p|--pass <arg>] [-g|--group <arg>] [-e|--enable <arg>] [-d|--disable <arg>] [-h|--help]\n' "$0"
    printf '\t%s\n' "-u, --user: User Name for new user account. (no default)"
    printf '\t%s\n' "-p, --pass: Password for new user account. (no default)"
    printf '\t%s\n' "-g, --group: Name of group to add the new user account to. (default 'sudo')"
    printf '\t%s\n' "-d, --disable: Date to disable account. (no default)"
    printf '\t%s\n' "-h, --help: Prints help"
}

# The parsing of the command-line
parse_commandline() {
    while test $# -gt 0; do
        _key="$1"
        case "$_key" in
        # We support whitespace as a delimiter between option argument and its value.
        # Therefore, we expect the --user or -u value.
        # so we watch for --user and -u.
        # Since we know that we got the long or short option,
        # we just reach out for the next argument to get the value.
        -u | --user)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_user="$2"
            shift
            ;;
        # We support the = as a delimiter between option argument and its value.
        # Therefore, we expect --user=value, so we watch for --user=*
        # For whatever we get, we strip '--user=' using the ${var##--user=} notation
        # to get the argument value
        --user=*)
            _arg_user="${_key##--user=}"
            ;;
        # We support getopts-style short arguments grouping,
        # so as -u accepts value, we allow it to be appended to it, so we watch for -u*
        # and we strip the leading -u from the argument string using the ${var##-u} notation.
        -u*)
            _arg_user="${_key##-u}"
            ;;
        # See the comment of option '--user' to see what's going on here - principle is the same.
        -p | --pass)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_pass="$2"
            shift
            ;;
        # See the comment of option '--user=' to see what's going on here - principle is the same.
        --pass=*)
            _arg_pass="${_key##--pass=}"
            ;;
        # See the comment of option '-u' to see what's going on here - principle is the same.
        -p*)
            _arg_pass="${_key##-p}"
            ;;
        # See the comment of option '--user' to see what's going on here - principle is the same.
        -g | --group)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_group="$2"
            shift
            ;;
        # See the comment of option '--user=' to see what's going on here - principle is the same.
        --group=*)
            _arg_group="${_key##--group=}"
            ;;
        # See the comment of option '-u' to see what's going on here - principle is the same.
        -g*)
            _arg_group="${_key##-g}"
            ;;
        # See the comment of option '--user' to see what's going on here - principle is the same.
        -d | --disable)
            test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
            _arg_disable="$2"
            shift
            ;;
        # See the comment of option '--user=' to see what's going on here - principle is the same.
        --disable=*)
            _arg_disable="${_key##--disable=}"
            ;;
        # See the comment of option '-u' to see what's going on here - principle is the same.
        -d*)
            _arg_disable="${_key##-d}"
            ;;
        # The help argument doesn't accept a value,
        # we expect the --help or -h, so we watch for them.
        -h | --help)
            print_help
            exit 0
            ;;
        # We support getopts-style short arguments clustering,
        # so as -h doesn't accept value, other short options may be appended to it, so we watch for -h*.
        # After stripping the leading -h from the argument, we have to make sure
        # that the first character that follows corresponds to a short option.
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

if [[ -z "${_arg_user}" ]]; then
    die "FATAL ERROR: User Name is required. '$_arg_user'" 1
fi

if [[ -z "${_arg_pass}" ]]; then
    die "FATAL ERROR: Password is required. '$_arg_pass'" 1
fi

if [ "$(id -u)" -eq 0 ]; then
    if grep -E "^$_arg_user" /etc/passwd >/dev/null; then
        # User already exists, add them to the group
        echo "$_arg_user exists!"
        if usermod -aG "$_arg_group" "$_arg_user"; then
            echo "User($_arg_user) has been added to $_arg_group group!"
        else
            echo "Failed to add a user to $_arg_group group!"
            exit 1
        fi
    else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' "$_arg_pass")
        if useradd -m -p "$pass" "$_arg_user"; then
            echo "User($_arg_user) has been added to system!"
        else
            echo "Failed to add a user!"
            exit 1
        fi
        if usermod -aG "$_arg_group" "$_arg_user"; then
            echo "User($_arg_user) has been added to $_arg_group group!"
        else
            echo "Failed to add a user to $_arg_group group!"
            exit 1
        fi
    fi
    if [[ -n "${_arg_disable}" ]]; then
        # Expire the user after date
        usermod -e "$_arg_disable" "$_arg_user"
    fi

else
    echo "Only root may add a user to the system."
    exit 2
fi





