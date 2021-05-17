# This script will import your Outlook signatures from OneDrive
Copy-Item -Path "$env:OneDrive\Outlook Signatures\*" -Destination "$env:APPDATA\Microsoft\Signatures" -Recurse
