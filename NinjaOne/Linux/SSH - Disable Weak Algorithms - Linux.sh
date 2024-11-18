#!/usr/bin/env bash

# Description: Disables weak SSH algorithms.
#
# Release Notes: Initial Release
#
# Disables weak SSH algorithms.
#
# Links:
#  https://infosec.mozilla.org/guidelines/openssh
#  https://man.openbsd.org/sshd_config#KexAlgorithms
#  https://man.openbsd.org/sshd_config#Ciphers
#  https://man.openbsd.org/sshd_config#MACs
#  https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-131Ar2.pdf

_Ciphers='chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr'
_KexAlgorithms='curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256'
_MACs='hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com'

_HostKeys=("HostKey /etc/ssh/ssh_host_ed25519_key" "HostKey /etc/ssh/ssh_host_rsa_key" "HostKey /etc/ssh/ssh_host_ecdsa_key")

_sshd_config="/etc/ssh/sshd_config"

_restoreBackedUpConfig="false"

if [[ -n $restoreBackedUpConfig && $restoreBackedUpConfig == "true" ]]; then
    _restoreBackedUpConfig="true"
fi

# Logs an error message and exits with the specified exit code
die() {
    local _ret="${2:-1}"
    echo "$1" >&2
    exit "${_ret}"
}

backup_file() {
    # Source file to backup
    local file_source=$1
    # Get number of backups to keep from argument or default to 3
    local backup_keep_count=${2:-3}

    local file_source_dir
    local file_source_file
    local file_backup
    local backup_files
    file_backup="${file_source}_$(date +%Y-%m-%d_%H-%M-%S).backup"
    if [[ -f "${file_source}" ]]; then
        echo "[Info] Backing up $file_source to $file_backup"
        cp "${file_source}" "${file_backup}"
    fi

    # Remove the oldest backup file if there are more than 3 backups
    backup_keep_count="+$((backup_keep_count + 1))"

    # Get the list of backup files
    echo "[Info] Finding backup files..."
    file_source_dir=$(dirname "${file_source}")
    file_source_file=$(basename "${file_source}")
    backup_files=$(find "$file_source_dir" -name "${file_source_file}_*.backup" -printf '%T+ %p\n' 2>/dev/null | sort -r | tail -n "${backup_keep_count}" | cut -d' ' -f2-)
    # Loop through each backup file and remove it
    for backup_file in $backup_files; do
        echo "[Info] Removing $backup_file"
        rm -f "$backup_file"
    done
}

restart_sshd() {
    # Check that this system is running systemd-based
    _type=$(
        # Get the type of init system
        file /sbin/init 2>/dev/null | awk -F/ '{print $NF}' 2>/dev/null
    )
    if [[ "${_type}" == "systemd" ]] && [[ -n "$(command -v systemctl)" ]]; then
        echo "[Info] Reloading ${sshd_service} service..."
        # Find the sshd service
        sshd_service=$(
            # Get the ssh service, if two are found use the first one. Likely the first one is a symlink to the actual service file.
            systemctl list-unit-files | grep -E "^(sshd|ssh|openssh-server)\.service" | awk -F' ' '{print $1}' | head -n 1
        )
        if [[ -z "${sshd_service}" ]]; then
            die "[Error] sshd service is not available. Please install it and try again" 1
        fi
        # Check that ssh service is enabled
        if systemctl is-enabled "${sshd_service}" >/dev/null; then
            echo "[Info] ${sshd_service} is enabled"
        else
            die "[Info] ${sshd_service} is not enabled. When enabled and started, PermitEmptyPasswords will be set to no" 0
        fi
        # Check that ssh service is running
        if systemctl is-active "${sshd_service}" >/dev/null; then
            echo "[Info] ${sshd_service} is running"
            # Reload sshd.service
            if systemctl reload "${sshd_service}"; then
                echo "[Info] sshd service configuration reloaded"
            else
                die "[Error] Failed to reload ${sshd_service}" 1
            fi
        else
            echo "[Info] ${sshd_service} is not running"
        fi
    else
        echo "[Info] Restarting sshd service..."
        # Check that the service command is available
        if ! [ "$(command -v service)" ]; then
            die "[Error] The service command is not available. Is this an initd type system (e.g. SysV)?" 1
        fi
        # Find the sshd service
        sshd_service=$(
            # Get the list of services
            service --status-all | awk -F' ' '{print $NF}' | grep sshd
        )
        if [[ -z "${sshd_service}" ]]; then
            sshd_service=$(
                # Get the list of services
                service --status-all | awk -F' ' '{print $NF}' | grep ssh
            )
            if [[ -z "${sshd_service}" ]]; then
                die "[Error] sshd service is not available. Please install it and try again" 1
            fi
        fi
        # Restart sshd service
        if service "${sshd_service}" restart; then
            echo "[Info] sshd service restarted"
        else
            die "[Error] Failed to restart sshd service" 1
        fi
    fi
}

# Check that we are running as root
if [[ $EUID -ne 0 ]]; then
    die "[Error] This script must be run as root" 1
fi

# Check if sshd is installed
if ! command -v sshd &>/dev/null; then
    die "[Error] sshd is not installed" 1
fi

# Get the version of OpenSSH Server
_sshd_version=$(sshd -V 2>&1 | grep OpenSSH | awk '{print $1}' | cut -d '_' -f 2 | sed 's/,//g')
_sshd_version_major=$(echo "${_sshd_version}" | cut -d '.' -f 1)
_sshd_version_minor=$(echo "${_sshd_version}" | cut -d '.' -f 2)

# Check if the sshd version is less than 8.8
if [[ "${_sshd_version_major}" -lt 6 ]] || [[ "${_sshd_version_major}" -eq 6 ]] && [[ "${_sshd_version_minor}" -lt 7 ]]; then
    die "[Error] This script is only supported on OpenSSH Server 6.7 and above: Current version is ${_sshd_version}" 1
fi

if [[ $_restoreBackedUpConfig == "true" ]]; then
    # Get backup files
    backup_dir=$(dirname "${_sshd_config}")
    backup_file=$(basename "${_sshd_config}")
    backup_file_to_restore=$(find "${backup_dir}" -name "${backup_file}_*.backup" -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort | cut -f 2- -d ' ' | tail -n 1 | awk '{print $8}')

    if [ -f "${backup_file_to_restore}" ]; then
        echo "[Info] Restoring ${backup_file_to_restore}"
        cp "${backup_file_to_restore}" "${_sshd_config}" || die "[Error] Failed to restore ${backup_file}" 1
        echo "[Info] Successfully restored ${backup_file}"
    else
        echo "[Info] No backup file found, nothing to restore"
    fi

    exit 0
fi

# Check if the sshd_config file exists
if [[ -f "${_sshd_config}" ]]; then
    # Make a backup of the sshd_config file
    backup_file "${_sshd_config}"

    # Set KexAlgorithms
    if grep -q "^KexAlgorithms" /etc/ssh/sshd_config; then
        sed -i -e "s/^KexAlgorithms.*/KexAlgorithms ${_KexAlgorithms}/g" /etc/ssh/sshd_config
        echo "[Info] KexAlgorithms set to ${_KexAlgorithms}"
    else
        echo "KexAlgorithms ${_KexAlgorithms}" >>/etc/ssh/sshd_config
        echo "[Info] Added KexAlgorithms: ${_KexAlgorithms}"
    fi

    # Set Ciphers
    if grep -q "^Ciphers" /etc/ssh/sshd_config; then
        sed -i -e "s/^Ciphers.*/Ciphers ${_Ciphers}/g" /etc/ssh/sshd_config
        echo "[Info] Ciphers set to ${_Ciphers}"
    else
        echo "Ciphers ${_Ciphers}" >>/etc/ssh/sshd_config
        echo "[Info] Added Ciphers: ${_Ciphers}"
    fi

    # Set MACs
    if grep -q "^MACs" /etc/ssh/sshd_config; then
        sed -i -e "s/^MACs.*/MACs ${_MACs}/g" /etc/ssh/sshd_config
        echo "[Info] MACs set to ${_MACs}"
    else
        echo "MACs ${_MACs}" >>/etc/ssh/sshd_config
        echo "[Info] Added MACs: ${_MACs}"
    fi

    # Remove old HostKey entries
    if grep -q "^HostKey" /etc/ssh/sshd_config; then
        sed -i '/^HostKey/d' /etc/ssh/sshd_config
        echo "[Info] Removed old HostKey entries"
    fi

    # Add new HostKey entries
    for _HostKey in "${_HostKeys[@]}"; do
        # Display the HostKey after the last /
        _displayName=${_HostKey##*/}
        if grep -q "^${_HostKey}" /etc/ssh/sshd_config; then
            echo "[Info] HostKey ${_displayName} already exists"
        else
            echo "${_HostKey}" >>/etc/ssh/sshd_config
            echo "[Info] Added HostKey ${_HostKey} to /etc/ssh/sshd_config"
        fi
    done

    restart_sshd
else
    die "[Error] The sshd_config file does not exist" 1
fi




