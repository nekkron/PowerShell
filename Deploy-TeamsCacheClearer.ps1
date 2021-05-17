# This script will place the Teams Cache Remover inside of the support folder on the local computer

# Create support folder
New-Item -ItemType Directory -Force -Path C:\support

# Where the real work happens. Ensure Output file extension is the same as website file extension!
Invoke-WebRequest "https://bit.ly/3lhJJ8e" -OutFile "C:\support\MicrosoftTeams-ClearCache.ps1"

Set-ExecutionPolicy RemoteSigned -Force
