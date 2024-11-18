#!/usr/bin/env bash

# Description: Get the details of a Proxmox Node Storage and save it to a multiline and/or WYSIWYG custom field
#
# Release Notes: Fixed 10% width bug.

# Command line arguments, swap the numbers if you want the multiline custom field to be the second argument
multiline_custom_field=$1 # First argument is the multiline custom field name
wysiwyg_custom_field=$2   # Second argument is the WYSIWYG custom field name

# Check if the multilineCustomField and wysiwygCustomField are set
if [[ -n "${multilineCustomField}" && "${multilineCustomField}" != "null" ]]; then
    multiline_custom_field=$multilineCustomField
fi
if [[ -n "${wysiwygCustomField}" && "${wysiwygCustomField}" != "null" ]]; then
    wysiwyg_custom_field=$wysiwygCustomField
fi

# Check if the multiline_custom_field and wysiwyg_custom_field are the same
if [[ -n "${multiline_custom_field}" && "${multiline_custom_field}" == "${wysiwyg_custom_field}" ]]; then
    echo "[Error] multilineCustomField and wysiwygCustomField cannot be the same custom field."
    exit 1
fi

# Check if the multiline_custom_field and wysiwyg_custom_field are set
if [[ -z "${multiline_custom_field}" ]]; then
    echo "[Info] multilineCustomField is not set."
fi
if [[ -z "${wysiwyg_custom_field}" ]]; then
    echo "[Info] wysiwygCustomField is not set."
fi

# Check that we have the required tools
if ! command -v pvesh &>/dev/null; then
    echo "[Error] The Proxmox VE API tool 'pvesh' is required."
    exit 1
fi

# Check that we are running as root
if [[ $EUID -ne 0 ]]; then
    echo "[Error] This script must be run as root."
    exit 1
fi

# Check if ninjarmm-cli command exists
ninjarmm_cli="/opt/NinjaRMMAgent/programdata/ninjarmm-cli"
if [[ -z $ninjarmm_cli ]]; then
    echo "[Error] The ninjarmm-cli command does not exist in the default path. Please ensure the NinjaRMM agent is installed before running this script."
    exit 1
else
    # ninjarmm-cli command exists in the default path
    echo -n
fi

function GetThisNodeName() {
    # Get the node name
    if ! node_name=$(pvesh get /cluster/status --noborder | awk '$6 == 1 {print $2}'); then
        echo "[Error] Failed to get the node name."
        echo "$node_name"
        exit 1
    fi
    echo "$node_name"
}

# Run the pvesh command to get the status information
if ! storages=$(pvesh get /storage --noborder | tail +2); then
    echo "[Error] Failed to get the list of storages."
    echo "$storages"
    exit 1
fi
# Example Output:
# local
# local-zfs
# storage-nas

function formatStorage() {
    echo ""
    echo "Storage Status:"
    # Loop though the storages and get the status of each
    for storage in $storages; do
        # Get the status of the storage
        if ! storage_status=$(pvesh get /storage/"$storage" --noborder); then
            echo "[Error] Failed to get the Storage Status of $storage."
            echo "$storage_status"
            exit 1
        fi
        storage_node=$(GetThisNodeName)
        # Get the storage name
        storage_name=$(echo "$storage_status" | grep -P 'storage\s+' | awk '{print $2}')
        # Get the free space
        # "$storage_name " is used to avoid matching "local-zfs" when searching for "local"
        storage_free_space=$(pvesh get "/nodes/$storage_node/storage" --noborder | grep -P "$storage_name " | awk '{print $5" "$6}')
        # Get the total space
        storage_total_space=$(pvesh get "/nodes/$storage_node/storage" --noborder | grep -P "$storage_name " | awk '{print $9" "$10}')
        echo -n
        echo ""
        echo "$storage"
        echo "-------------"
        # Take the output of $storage_status, skip the first line, then use a colon as a separator between the key and value
        echo "$storage_status" | tail +2 | awk '{print $1 ": " $2}'
        echo "Free: $storage_free_space"
        echo "Total: $storage_total_space"
    done
}
multiline_output=$(formatStorage)

# Create Storage Status label
storage_table="<h2>Storage Status</h2>"
# Create the Storage Status table
storage_table+="<table style='white-space:nowrap;'><tr><th>Storage Name</th><th>Type</th><th>Path/File System</th><th>Free Space</th><th>Total Space</th><th>Content</th></tr>"

# Loop though the storages and get the status of each
for storage in $storages; do
    if ! storage_status=$(pvesh get /storage/"$storage" --noborder); then
        echo "[Error] Failed to get the Storage Status of $storage."
        echo "$storage_status"
        exit 1
    fi
    # Example Output:
    # key     value
    # content images,rootdir
    # digest  c14cb4c9bbcf9a062fa8a82b10afe01cb1ed5b8d
    # pool    rpool/data
    # sparse  1
    # storage local-zfs
    # type    zfspool
    storage_node=$(GetThisNodeName)
    # Get the storage name
    storage_name=$(echo "$storage_status" | grep -P 'storage\s+' | awk '{print $2}')
    # Get the storage type
    storage_type=$(echo "$storage_status" | grep -P 'type\s+' | awk '{print $2}')
    # Get the storage pool/path
    storage_pool=$(echo "$storage_status" | grep -P 'pool\s+' | awk '{print $2}')
    if [[ -z "${storage_pool}" ]]; then
        storage_pool=$(echo "$storage_status" | grep -P 'path\s+' | awk '{print $2}')
    fi
    # Get the storage content
    storage_content=$(echo "$storage_status" | grep -P 'content\s+' | awk '{print $2}')
    # Get the free space
    # "$storage_name " is used to avoid matching "local-zfs" when searching for "local"
    storage_free_space=$(pvesh get "/nodes/$storage_node/storage" --noborder | grep -P "$storage_name " | awk '{print $5" "$6}')
    # Get the total space
    storage_total_space=$(pvesh get "/nodes/$storage_node/storage" --noborder | grep -P "$storage_name " | awk '{print $9" "$10}')

    # Add to the Storage Status table
    storage_table+="<tr><td>$storage_name</td><td>$storage_type</td><td>$storage_pool</td><td>$storage_free_space</td><td>$storage_total_space</td><td>$storage_content</td></tr>"
done

# Close the Storage Status table
storage_table+="</table>"

# Save the results
result_table="$storage_table"

_exit_code=0
# Save the result to the custom field
if [[ -n "$wysiwyg_custom_field" ]]; then
    if [[ -x "$ninjarmm_cli" ]]; then
        if hideOutput=$(echo "$result_table" | "$ninjarmm_cli" set --stdin "$wysiwyg_custom_field" 2>&1); then
            echo "[Info] Successfully set custom field: $wysiwyg_custom_field"
        else
            echo "[Error] Failed to set custom field: $wysiwyg_custom_field. Custom Field does not exit or does not have write permissions."
            _exit_code=1
        fi
    else
        echo "[Error] NinjaRMM CLI not found or not executable"
        _exit_code=1
    fi
fi

if [[ -n "$multiline_custom_field" ]]; then
    if [[ -x "$ninjarmm_cli" ]]; then
        if hideOutput=$(echo "$multiline_output" | "$ninjarmm_cli" set --stdin "$multiline_custom_field" 2>&1); then
            echo "[Info] Successfully set custom field: $multiline_custom_field"
        else
            echo "[Error] Failed to set custom field: $multiline_custom_field. Custom Field does not exit or does not have write permissions."
            _exit_code=1
        fi
    else
        echo "[Error] NinjaRMM CLI not found or not executable"
        _exit_code=1
    fi
fi

# Output the result if no custom fields are set
if [[ -z "${wysiwyg_custom_field}" ]] && [[ -z "${multiline_custom_field}" ]]; then
    # Output the result to the Activity Feed
    echo "${multiline_output}"
fi

if [[ $_exit_code -eq 1 ]]; then
    exit 1
fi





