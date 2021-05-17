# This script is for deploying BMC Client Management Agent on macOS
# https://docs.bmc.com/docs/bcm129/installing-bmc-client-management-on-macos-by-using-the-pull-method-929640970.html


Invoke-WebRequest "https://www.dropbox.com/s/b1q1hnxvo35663z/BCM_Agent?dl=1" -OutFile "/Applications/BCM_Agent"
# Invoke-WebRequest "www.web.site" -OutFile "/Applications/BCM_Agent"
chmod +x "/Applications/BCM_Agent"
sudo "/Applications/BCM_Agent"
