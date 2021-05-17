#=============================================================================================================================
#
# Script Name:     Remediate-LocalUser_USOIT.ps1
# Description:     Remediates USOIT account issue if detected in Detect-LocalUser_USOIT.ps1
# Notes:           Changing the variable $securePassword changes the password of the USOIT account
#
#=============================================================================================================================

# Variables
$securePassword=ConvertTo-SecureString password -AsPlainText -Force

# Reset password to admin account
New-LocalUser -Name USOIT -Password $securePassword -AccountNeverExpires -Description "IT Administrator Account" -PasswordNeverExpires  -ErrorAction SilentlyContinue
Set-LocalUser -Name USOIT -AccountNeverExpires -Description "IT Administrator Account" -Password $securePassword -PasswordNeverExpires $true

# Add to administrators group
Get-LocalGroupMember -Group Administrators -Member USOIT -ErrorAction SilentlyContinue
