#!/usr/bin/env bash
# Description: Fetches the install date and can store it in a custom field. Based on stat / .
#
# Release Notes: Updated calculated name
#
# Usage: [Custom Field]
# <> are required
# [] are optional
#
# Example: installdate
#  Saves the install date to the customfield named installdate
#

function GetInstallDate() {
    stat /
}

function SetCustomField() {
    /opt/NinjaRMMAgent/programdata/ninjarmm-cli "$@"
}

# When run directly without testing, the "__()" function does nothing.
test || __() { :; }

__ begin __

# Parameters
CustomField=${installDateCustomFieldName:=$1}

ISO_8601='%Y-%m-%d %T %Z'
Date=$(GetInstallDate | sed 's/ Birth: //' | tail --lines=1)
InstallDate=$(date -d "${Date}" "+$ISO_8601")

echo "${InstallDate}"

if [[ -n "${CustomField}" ]]; then
    SetCustomField set "$CustomField" "$InstallDate"
fi

__ end __





