#!/usr/bin/env bash

# Description: Sets the SSH login timeout via LoginGraceTime.
#
# Preset Parameter: --setTimeoutInSeconds "ReplaceMeWithANumber"
#   The server disconnects after this time if the user has not successfully logged in. If the value is 0, there is no time limit. The default is 120 seconds.
#
# Links: https://man.openbsd.org/sshd_config#LoginGraceTime

# Logs an error message and exits with the specified exit code
die() {
    local _ret="${2:-1}"
    echo "$1" >&2
    exit "${_ret}"
}

_sshd_config="/etc/ssh/sshd_config"

backup_file() {
    file_source=$1
    file_backup="${file_source}_$(date +%Y-%m-%d_%H-%M-%S).backup"
    if [[ -f "${file_source}" ]]; then
        echo "[Info] Backing up $file_source to $file_backup"
        cp "${file_source}" "${file_backup}"
    fi

    # Remove the oldest backup file if there are more than 3 backups

    # Get the list of backup files
    echo "[Info] Finding backup files..."
    _sshd_config_dir=$(dirname "${_sshd_config}")
    _sshd_config_file=$(basename "${_sshd_config}")
    backup_files=$(find "$_sshd_config_dir" -name "${_sshd_config_file}_*.backup" -printf '%T+ %p\n' 2>/dev/null | sort -r | tail -n +4 | cut -d' ' -f2-)
    # Loop through each backup file and remove it
    for backup_file in $backup_files; do
        echo "[Info] Removing $backup_file"
        rm -f "$backup_file"
    done
}

# Check that we are running as root
if [[ $EUID -ne 0 ]]; then
    die "[Error] This script must be run as root." 1
fi

if [[ -z "${setTimeoutInSeconds}" ]]; then
    die "[Error] Timeout was not specified." 1
fi

# Remove any leading zeros
setTimeoutInSeconds=$((setTimeoutInSeconds))

if ((setTimeoutInSeconds > 86400)); then
    die "[Error] Timeout can not be greater than 86400." 1
fi

if ((setTimeoutInSeconds < 0)); then
    die "[Error] Timeout can not be less than 0." 1
fi

_should_reload="false"

# Default is 0; which is disabled
_loginGraceTime="LoginGraceTime ${setTimeoutInSeconds}"

# Check if the sshd_config file exists
if [[ -f "${_sshd_config}" ]]; then
    # Check if the LoginGraceTime option is already set to _loginGraceTime
    if grep -q "^${_loginGraceTime}" "${_sshd_config}"; then
        echo "[Info] Timeout is already set to ${setTimeoutInSeconds}."
        _should_reload="false"
    elif grep -q "^LoginGraceTime .*" "${_sshd_config}"; then
        backup_file "${_sshd_config}"
        # First check if the option is not commented out and set to yes
        # Then set the LoginGraceTime option to ${setTimeoutInSeconds}
        sed -i "s/^LoginGraceTime.*/${_loginGraceTime}/" "${_sshd_config}"
        echo "[Info] LoginGraceTime set to ${setTimeoutInSeconds}."
        _should_reload="true"
    elif grep -q "^#LoginGraceTime" "${_sshd_config}"; then
        backup_file "${_sshd_config}"
        # First check if the option is commented out
        # Then set the LoginGraceTime option to ${setTimeoutInSeconds}
        sed -i "s/^#LoginGraceTime.*/${_loginGraceTime}/" "${_sshd_config}"
        echo "[Info] LoginGraceTime set to ${setTimeoutInSeconds}, as it was commented out."
        _should_reload="true"
    else
        backup_file "${_sshd_config}"
        # Append the LoginGraceTime option to the end of the sshd_config file
        # If the past checks have not found the option, appending it will ensure that it is set to no
        echo "${_loginGraceTime}" >>"${_sshd_config}"
        echo "[Info] LoginGraceTime set to ${setTimeoutInSeconds} at the end of the sshd_config file."
        _should_reload="true"
    fi

    # Check that this system is running systemd-based
    _type=$(
        # Get the type of init system
        file /sbin/init 2>/dev/null | awk -F/ '{print $NF}' 2>/dev/null
    )
    if [[ "${_type}" == "systemd" ]] && [ "$(command -v systemctl)" ]; then
        echo "[Info] Reloading ${sshd_service} service..."
        # Find the sshd service
        sshd_service=$(
            # Get the ssh service, if two are found use the first one. Likely the first one is a symlink to the actual service file.
            systemctl list-unit-files | grep -E "^(sshd|ssh|openssh-server)\.service" | awk -F' ' '{print $1}' | head -n 1
        )
        if [[ -z "${sshd_service}" ]]; then
            die "[Error] sshd service is not available. Please install it and try again." 1
        fi
        # Check that ssh service is enabled
        if systemctl is-enabled "${sshd_service}" >/dev/null; then
            echo "[Info] ${sshd_service} is enabled."
        else
            die "[Info] ${sshd_service} is not enabled. When enabled and started, PermitEmptyPasswords will be set to no." 0
        fi
        # Check that ssh service is running
        if systemctl is-active "${sshd_service}" >/dev/null; then
            echo "[Info] ${sshd_service} is running."
            if [[ "${_should_reload}" == "true" ]]; then
                # Reload sshd.service
                if systemctl reload "${sshd_service}"; then
                    echo "[Info] sshd service configuration reloaded."
                else
                    die "[Error] Failed to reload ${sshd_service}. Please try again." 1
                fi
            else
                echo "[Info] sshd service configuration will not be reloaded as there is no need to do so."
            fi
        else
            echo "[Info] ${sshd_service} is not running."
        fi
    else
        echo "[Info] Restarting sshd service..."
        # Check that the service command is available
        if ! [ "$(command -v service)" ]; then
            die "[Error] The service command is not available. Is this an initd type system (e.g. SysV)? Please try again." 1
        fi
        # Find the sshd service
        sshd_service=$(
            # Get the list of services
            service --status-all | awk -F' ' '{print $NF}' | grep sshd
        )
        if [[ -z "${sshd_service}" ]]; then
            die "[Error] sshd service is not available. Please install it and try again." 1
        fi
        if [[ "${_should_reload}" == "true" ]]; then
            # Restart sshd service
            if service "${sshd_service}" restart; then
                echo "[Info] sshd service restarted."
            else
                die "[Error] Failed to restart sshd service. Please try again." 1
            fi
        else
            echo "[Info] sshd service configuration will not be restarted as there is no need to do so."
        fi
    fi
else
    die "[Error] The sshd_config file does not exist." 1
fi




