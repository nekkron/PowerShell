# This script is for deploying BMC Client Management Agent on macOS
#  20201115 - James Kasparek - Senior Regional IT Support Technician
# https://docs.bmc.com/docs/bcm129/installing-bmc-client-management-on-macos-by-using-the-pull-method-929640970.html


Invoke-WebRequest "https://www.dropbox.com/s/b1q1hnxvo35663z/BCM_Agent?dl=1" -OutFile "/Applications/BCM_Agent"
# Invoke-WebRequest "https://servicedesk.uso.org:1610/rolloutpackages/1052/BCM_Agent" -OutFile "/Applications/BCM_Agent"
chmod +x "/Applications/BCM_Agent"
sudo "/Applications/BCM_Agent"
