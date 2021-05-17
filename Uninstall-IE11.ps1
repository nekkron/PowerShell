# https://www.windowscentral.com/how-remove-internet-explorer-11-windows-10
# This script will remove Internet Explorer from the computer

Disable-WindowsOptionalFeature -FeatureName Internet-Explorer-Optional-amd64 –Online -NoRestart
