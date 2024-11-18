#!/usr/bin/env bash

# Description: Exits with a 1 if any crash files were created in the last 180 days. Be it .ips, .panic, or .crash under /Library/Logs/DiagnosticReports.
#
# Release Notes: Initial Release

if [[ "${testForAppCrashes}" == "true" ]]; then
    ipsFiles=($(find "/Library/Logs/DiagnosticReports" -type f -name "*.ips" -mtime -180))
    for item in "${ipsFiles[@]}"; do
        echo "[Warn] Found ${item} ips file!"
    done
fi

panicFiles=($(find "/Library/Logs/DiagnosticReports" -type f -name "*.panic" -not -name "*.contents.panic" -mtime -180))
crashFiles=($(find "/Library/Logs/DiagnosticReports" -type f -name "*.crash" -mtime -180))

for item in "${panicFiles[@]}"; do
    echo "[Error] Found ${item} panic file!"
done

for item in "${crashFiles[@]}"; do
    echo "[Error] Found ${item} crash file!"
done

if [ ${#ipsFiles[@]} -gt 0 ] || [ ${#panicFiles[@]} -gt 0 ] || [ ${#crashFiles[@]} -gt 0 ]; then
    exit 1
else
    echo "No crash files found."
    exit 0
fi





