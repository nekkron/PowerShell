# Uninstall the Intel Driver and Support Assistant software
# https://community.intel.com/t5/Intel-Desktop-Boards/Silent-Install-Options-for-DSA-Uninstaller/td-p/1195679

cd (Get-ChildItem -Path 'C:\ProgramData\Package Cache' -Filter Intel-Driver-and-Support-Assistant-Installer.exe -Recurse).Directory; .\Intel-Driver-and-Support-Assistant-Installer.exe /uninstall /quiet
