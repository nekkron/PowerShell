#!/usr/bin/env bash

# Description: Get the Proxmox Cluster Status and save it to a multiline and/or WYSIWYG custom field
#
# Release Notes: Fixed 10% width bug.

# Command line arguments, swap the numbers if you want the multiline custom field to be the second argument
multiline_custom_field=$1 # First argument is the multiline custom field name
wysiwyg_custom_field=$2   # Second argument is the WYSIWYG custom field name

if [[ -n "${multilineCustomField}" && "${multilineCustomField}" != "null" ]]; then
    multiline_custom_field=$multilineCustomField
fi
if [[ -n "${wysiwygCustomField}" && "${wysiwygCustomField}" != "null" ]]; then
    wysiwyg_custom_field=$wysiwygCustomField
fi

if [[ -n "${multiline_custom_field}" && "${multiline_custom_field}" == "${wysiwyg_custom_field}" ]]; then
    echo "[Error] multilineCustomField and wysiwygCustomField cannot be the same custom field."
    exit 1
fi

if [[ -z "${multiline_custom_field}" ]]; then
    echo "[Info] multilineCustomField is not set."
fi
if [[ -z "${wysiwyg_custom_field}" ]]; then
    echo "[Info] wysiwygCustomField is not set."
fi

# Check that we have the required tools
if ! command -v pvecm &>/dev/null; then
    echo "[Error] The Proxmox VE API tool 'pvecm' is required."
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

# Run the pvecm command to get the status information
if ! pvecm_status_output=$(pvecm status); then
    echo "[Error] Failed to get the Proxmox Cluster Status."
    echo "$pvecm_status_output"
    exit 1
fi
# Example Output:
# Cluster information
# -------------------
# Name:             cluster1
# Config Version:   4
# Transport:        knet
# Secure auth:      on
#
# Quorum information
# ------------------
# Date:             Mon Apr  8 10:33:16 2024
# Quorum provider:  corosync_votequorum
# Nodes:            4
# Node ID:          0x00000004
# Ring ID:          1.631
# Quorate:          Yes
#
# Votequorum information
# ----------------------
# Expected votes:   4
# Highest expected: 4
# Total votes:      4
# Quorum:           3
# Flags:            Quorate
#
# Membership information
# ----------------------
#     Nodeid      Votes Name
# 0x00000001          1 10.10.10.17
# 0x00000002          1 10.10.10.18
# 0x00000003          1 10.10.10.19
# 0x00000004          1 10.10.10.20 (local)

# Cluster Table
# Get the cluster name
cluster_name=$(echo "$pvecm_status_output" | grep -oP 'Name:\s+\K\w+' | head -n 1)
# Get the Config Version
config_version=$(echo "$pvecm_status_output" | grep -oP 'Config Version:\s+\K\d+' | head -n 1)
# Get the Transport
transport=$(echo "$pvecm_status_output" | grep -oP 'Transport:\s+\K\w+' | head -n 1)
# Get the Secure auth
secure_auth=$(echo "$pvecm_status_output" | grep -oP 'Secure auth:\s+\K\w+' | head -n 1)

# Create Cluster Status label
cluster_table="<h2>Cluster Status</h2>"
# Create the Cluster Status table
cluster_table+="<table style='white-space:nowrap;'><tr><th>Cluster Name</th><th>Config Version</th><th>Transport</th><th>Secure Auth</th></tr>"
cluster_table+="<tr><td>$cluster_name</td><td>$config_version</td><td>$transport</td><td>$secure_auth</td></tr></table>"

# Quorum Table
# Get the Quorum Date
quorum_date=$(echo "$pvecm_status_output" | grep -oP 'Date:\s+\K.*' | head -n 1)
# Get the Quorum provider
quorum_provider=$(echo "$pvecm_status_output" | grep -oP 'Quorum provider:\s+\K\w+' | head -n 1)
# Get the Nodes
nodes=$(echo "$pvecm_status_output" | grep -oP 'Nodes:\s+\K\d+' | head -n 1)
# Get the Node ID
node_id=$(echo "$pvecm_status_output" | grep -oP 'Node ID:\s+\K\w+' | head -n 1)
# Get the Ring ID
ring_id=$(echo "$pvecm_status_output" | grep -oP 'Ring ID:\s+\K[\d.]+')
# Get the Quorate
quorate=$(echo "$pvecm_status_output" | grep -oP 'Quorate:\s+\K\w+')

# Create Quorum Status label
quorum_table="<h2>Quorum Status</h2>"
# Create the Quorum Status table
quorum_table+="<table style='white-space:nowrap;'><tr><th>Quorum Date</th><th>Quorum Provider</th><th>Nodes</th><th>Node ID</th><th>Ring ID</th><th>Quorate</th></tr>"
quorum_table+="<tr><td>$quorum_date</td><td>$quorum_provider</td><td>$nodes</td><td>$node_id</td><td>$ring_id</td><td>$quorate</td></tr></table>"

# Votequorum Table
# Get the Expected votes
expected_votes=$(echo "$pvecm_status_output" | grep -oP 'Expected votes:\s+\K\d+')
# Get the Highest expected
highest_expected=$(echo "$pvecm_status_output" | grep -oP 'Highest expected:\s+\K\d+')
# Get the Total votes
total_votes=$(echo "$pvecm_status_output" | grep -oP 'Total votes:\s+\K\d+')
# Get the Quorum
quorum=$(echo "$pvecm_status_output" | grep -oP 'Quorum:\s+\K\d+')
# Get the Flags
flags=$(echo "$pvecm_status_output" | grep -oP 'Flags:\s+\K\w+')

# Create Votequorum Status label
votequorum_table="<h2>Votequorum Status</h2>"
# Create the Votequorum Status table
votequorum_table+="<table style='white-space:nowrap;'><tr><th>Expected Votes</th><th>Highest Expected</th><th>Total Votes</th><th>Quorum</th><th>Flags</th></tr>"
votequorum_table+="<tr><td>$expected_votes</td><td>$highest_expected</td><td>$total_votes</td><td>$quorum</td><td>$flags</td></tr></table>"

# Get the Membership information table
memberships=$(echo "$pvecm_status_output" | grep -oP '0x000000\d+\s+\d+\s+\d+\.\d+\.\d+\.\d+')
# Split memberships into an array
OLDIFS=$IFS
IFS=$'\n' read -r -d '' -a membership_array <<<"$memberships"
IFS=$OLDIFS

# Membership Table
# Create Membership Status label
membership_table="<h2>Membership Status</h2>"
# Create the Membership Status table
membership_table+="<table style='white-space:nowrap;'><tr><th>Node ID</th><th>Votes</th><th>Name</th></tr>"
for membership in "${membership_array[@]}"; do
    node_id=$(echo "$membership" | grep -oP '0x000000\d+')
    votes=$(echo "$membership" | grep -oP '\d+\s+(?=\d+\.\d+\.\d+\.\d+)')
    name=$(echo "$membership" | grep -oP '\d+\.\d+\.\d+\.\d+')
    membership_table+="<tr><td>$node_id</td><td>$votes</td><td>$name</td></tr>"
done
membership_table+="</table>"

# Combine all tables into one
result_table="$cluster_table</br>$quorum_table</br>$votequorum_table</br>$membership_table"

# Save the result to the custom field
_exit_code=0
if [[ -n "$multiline_custom_field" ]]; then
    if [[ -x "$ninjarmm_cli" ]]; then
        if hideOutput=$("$ninjarmm_cli" set "$multiline_custom_field" "$pvecm_status_output" 2>&1); then
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

if [[ -n "$wysiwyg_custom_field" ]]; then
    if [[ -x "$ninjarmm_cli" ]]; then
        if hideOutput=$("$ninjarmm_cli" set "$wysiwyg_custom_field" "$result_table" 2>&1); then
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

# Error out after checking both custom fields
if [[ $_exit_code -ne 0 ]]; then
    exit 1
fi

# Output the result if no custom fields are set
if [[ -z "${wysiwyg_custom_field}" ]] && [[ -z "${multiline_custom_field}" ]]; then
    echo "${pvecm_status_output}"
fi





