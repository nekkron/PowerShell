#!/usr/bin/env bash
# Description: This will search under /Applications/* and under each user's Applications folder for the app you speficy to remove and will only remove the first found app.
#
# Release Notes: Initial Release
#
# Usage:
#  <ApplicationName.app>
# Accepts only one application
# Specify the exact name of the application.
# Applications with space(s) in the name will need double quotes surrounding it. Example: "Google Chrome.app"
# As macOS's file system is typically case sensitive, matching the case is important.
#
# EXAMPLE
#  If we have /Applications/Docker.app installed.
#  Then our argument would be:
#    Docker.app
# EXAMPLE
#  If we have /Applications/Google Chrome.app installed.
#  Then our argument would be:
#    "Google Chrome.app"

if [[ -n $application ]]; then
    APP=$application
else
    APP=$1
fi

# Get a list of all installed app's, filter to only have /Applications and /User/<username>/Applications, filter the requested app, select the first found app
mdfind kMDItemContentTypeTree=com.apple.application-bundle -onlyin >/dev/null
APP_TO_UNINSTALL=$(system_profiler SPApplicationsDataType 2>/dev/null | sed -n 's/^ *Location: \(.*\)/\1/p' | grep -E '^\/Applications.*|\/Users\/.+\/Applications.*' | grep "${APP}" | head -n 1)

if [[ -z "${APP_TO_UNINSTALL}" ]]; then
    echo "Could not find application: $APP"
    exit 1
fi

echo "Found ${APP_TO_UNINSTALL}"
echo "Removing ${APP_TO_UNINSTALL}"
# Remove app
rm -rf "${APP_TO_UNINSTALL}"
status=$?
# Output result
if [ $status -eq 0 ]; then
    echo "Removed ${APP_TO_UNINSTALL}"
else
    echo "Failed to remove ${APP_TO_UNINSTALL}"
fi
# Return status
exit $status





