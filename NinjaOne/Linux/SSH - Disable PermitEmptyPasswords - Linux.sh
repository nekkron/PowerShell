#!/usr/bin/env bash

# Description: Explicitly disables PermitEmptyPasswords in OpenSSH.
#
# PermitEmptyPasswords defaults to no when not specified in the sshd_config file.
# This script will ensure that it is set to no to prevent SSH from accepting empty passwords.
#
# Links: https://man.openbsd.org/sshd_config#PermitEmptyPasswords
#
# Release Notes: Initial Release

# Logs an error message and exits with the specified exit code
die() {
    local _ret="${2:-1}"
    echo "$1" >&2
    exit "${_ret}"
}

# Check that we are running as root
if [[ $EUID -ne 0 ]]; then
    die "[Error] This script must be run as root." 1
fi

_should_reload="false"

# Check if the sshd_config file exists
if [[ -f /etc/ssh/sshd_config ]]; then
    # Check if the PermitEmptyPasswords option is already set to no
    if grep -q "^PermitEmptyPasswords no" /etc/ssh/sshd_config; then
        echo "[Info] PermitEmptyPasswords is already set to no."
        _should_reload="false"
    elif grep -q "^PermitEmptyPasswords yes" /etc/ssh/sshd_config; then
        # First check if the option is not commented out and set to yes
        # Then set the PermitEmptyPasswords option to no
        sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
        echo "[Info] PermitEmptyPasswords set to no."
        _should_reload="true"
    elif grep -q "^#PermitEmptyPasswords" /etc/ssh/sshd_config; then
        # First check if the option is commented out
        # Then set the PermitEmptyPasswords option to no
        sed -i 's/^#PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
        echo "[Info] PermitEmptyPasswords set to no, as it was commented out."
        _should_reload="true"
    else
        # Append the PermitEmptyPasswords option to the end of the sshd_config file
        # If the past checks have not found the option, appending it will ensure that it is set to no
        echo "PermitEmptyPasswords no" >>/etc/ssh/sshd_config
        echo "[Info] PermitEmptyPasswords set to no at the end of the sshd_config file."
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





