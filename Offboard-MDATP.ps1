# This script will download the .cmd file in order to offboard devices from the incorrect MDATP region
New-Item -ItemType Directory -Force -Path C:\support
Invoke-WebRequest "https://www.dropbox.com/s/dj7g8tuo4a694ju/WindowsDefenderATPOffboardingScript_valid_until_2021-01-03.cmd?dl=1" -OutFile "C:\support\MDATP_offboard.cmd"
cmd /c "C:\support\MDATP_offboard.cmd"
#Start-Process -Verb RunAs cmd.exe -Args '/c', "C:\support\MDATP_offboard.cmd"
