# This script will export your Outlook signatures to OneDrive
New-Item -Path "$env:OneDrive" -Name "Outlook Signatures" -ItemType Directory -ErrorAction SilentlyContinue
Copy-Item -Path "$env:APPDATA\Microsoft\Signatures\*" -Destination "$env:OneDrive\Outlook Signatures" -Recurse -Force
