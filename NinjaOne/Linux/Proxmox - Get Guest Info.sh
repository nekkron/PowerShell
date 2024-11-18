#!/usr/bin/env bash

# Description: This script gets the status and basic info of all Proxmox guests on a host and saves it to a WYSIWYG custom field.
#
# Release Notes: Initial Release
#
# Below are all the (case sensitive) valid parameters for this script.
# Only the custom field name is required!
# Preset Parameter: "Custom_Field_Name"
#   Custom_Field_Name: The name of the WYSIWYG custom field to save the VM info to.

Custom_Field_Name=$1

if [[ -n "${customFieldName}" ]]; then
    Custom_Field_Name="${customFieldName}"
fi

if [[ -z "${Custom_Field_Name}" || "${Custom_Field_Name}" == "null" ]]; then
    echo "The custom field name is required."
    echo " Example: guests"
    exit 1
fi

# Check that we have the required tools
if ! command -v pvesh &> /dev/null; then
    echo "The Proxmox VE API tool 'pvesh' is required."
    exit 1
fi
if ! command -v python3 &> /dev/null; then
    echo "The python3 is required. Should already be installed."
    exit 1
fi

# Check that we are running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

function SetCustomField() {
    /opt/NinjaRMMAgent/programdata/ninjarmm-cli "$@"
}

# Get the status and basic info of all Proxmox VMs on a host
qemu_guests=$(pvesh get /nodes/localhost/qemu --output-format=json)

# Create a table to store the VM info with the headers: Name, Status, Memory, CPUs, Disk Sizes
vm_table="<table><tr><th>Status</th><th>ID</th><th>Name</th><th>Memory</th><th>CPUs</th><th>Disk Sizes Combined</th></tr>"

# Loop through each VM and add the info to the table
qemu_table=$(echo "$qemu_guests" | python3 -c '
import sys, json

# Function to convert bytes to human readable format
def human_readable_size(size):
    for unit in ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB"]:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024

qemu_guests = json.load(sys.stdin)
vm_table = ""

for qemu in qemu_guests:
    qemu_id = qemu["vmid"]
    qemu_name = qemu["name"]
    qemu_status = qemu["status"]
    # Convert the memory from bytes to GB
    qemu_mem = human_readable_size(qemu["maxmem"])
    qemu_cpus = qemu["cpus"]
    # Convert the disk size from bytes to GB
    qemu_disk = human_readable_size(qemu["maxdisk"])

    # Add HTML blank space if values are empty
    qemu_id = qemu_id if qemu_id else "&nbsp;"
    qemu_name = qemu_name if qemu_name else "&nbsp;"
    qemu_mem = qemu_mem if qemu_mem else "&nbsp;"
    qemu_cpus = qemu_cpus if qemu_cpus else "&nbsp;"
    qemu_disk = qemu_disk if qemu_disk else "&nbsp;"

    if "running" in qemu_status:
        status_text = "<tr class='"'success'"'><td>Running</td>"
    elif "stopped" in qemu_status:
        status_text = "<tr class='"'danger'"'><td>Stopped</td>"
    else:
        status_text = "<tr class='"'other'"'><td>{}</td>".format(qemu_status)

    vm_table += "{}<td>{}</td><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>".format(
        status_text, qemu_id, qemu_name, qemu_mem, qemu_cpus, qemu_disk
    )

print(vm_table)
')
vm_table="$vm_table$qemu_table"

# Loop through each lxc and add the info to the table
lxc_guests=$(pvesh get /nodes/localhost/lxc --output-format=json)
# Loop through each lxc and add the info to the table
lxc_table=$(echo "$lxc_guests" | python3 -c '
import sys, json

# Function to convert bytes to human readable format
def human_readable_size(size):
    for unit in ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB"]:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024

lxc_guests = json.load(sys.stdin)
vm_table = ""

for lxc in lxc_guests:
    lxc_id = lxc["vmid"]
    lxc_name = lxc["name"]
    lxc_status = lxc["status"]
    # Convert the memory from bytes to GB
    lxc_mem = human_readable_size(lxc["maxmem"])
    lxc_cpus = lxc["cpus"]
    # Convert the disk size from bytes to GB
    lxc_disk = human_readable_size(lxc["maxdisk"])

    # Add HTML blank space if values are empty
    lxc_id = lxc_id if lxc_id else "&nbsp;"
    lxc_name = lxc_name if lxc_name else "&nbsp;"
    lxc_mem = lxc_mem if lxc_mem else "&nbsp;"
    lxc_cpus = lxc_cpus if lxc_cpus else "&nbsp;"
    lxc_disk = lxc_disk if lxc_disk else "&nbsp;"

    if "running" in lxc_status:
        status_text = "<tr class='"'success'"'><td>Running</td>"
    elif "stopped" in lxc_status:
        status_text = "<tr class='"'danger'"'><td>Stopped</td>"
    else:
        status_text = "<tr class='"'other'"'><td>{}</td>".format(lxc_status)

    vm_table += "{}<td>{}</td><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>".format(
        status_text, lxc_id, lxc_name, lxc_mem, lxc_cpus, lxc_disk
    )

print(vm_table)
')
vm_table="$vm_table$lxc_table"

# Close the table
vm_table="$vm_table</table>"

# Highlight the running and stopped VMs
vm_table=$(echo "$vm_table" | sed 's/<tr><td>running<\/td>/<tr class="success"><td>Running<\/td>/')
vm_table=$(echo "$vm_table" | sed 's/<tr><td>stopped<\/td>/<tr class="danger"><td>Stopped<\/td>/')

# Save the table to the custom field
if ! SetCustomField set "$Custom_Field_Name" "$vm_table"; then
    echo "Failed to save the Proxmox VM info to the custom field: $Custom_Field_Name"
    exit 1
fi
echo "The Proxmox VM info has been saved to the custom field: $Custom_Field_Name"





