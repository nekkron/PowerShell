#!/usr/bin/env bash
# Description: Fetches the install date and can store it in a custom field.
#
# Release Notes: Updated Calculated Name.
#
# Usage: [Custom Field]
# <> are required
# [] are optional
#
# Example: installdate
#  Saves the install date to the customfield named installdate
#



function GetInstallDate() {
    stat -f "%SB" /var/db/.AppleSetupDone
}

function SetCustomField() {
    /Applications/NinjaRMMAgent/programdata/ninjarmm-cli "$@"
}

# When run directly without testing, the "__()" function does nothing.
test || __() { :; }

__ begin __

# Parameters
CustomField=${installDateCustomFieldName:=$1}

InstallDate=$(GetInstallDate)

echo "${InstallDate}"

if [[ -n "${CustomField}" ]]; then
    SetCustomField set $CustomField $InstallDate
fi

__ end __





