#=============================================================================================================================
#
# Script Name:     Remediate-LocalUser_USOIT.ps1
# Description:     Remediates USOIT account issue if detected in Detect-LocalUser_USOIT.ps1
# Notes:           Changing the variable $securePassword changes the password of the USOIT account
#
#=============================================================================================================================

# Variables
$securePassword=ConvertTo-SecureString T3chn1c1@n! -AsPlainText -Force
#$localUSOExists = Get-LocalUser -Name USOIT -ErrorAction SilentlyContinue

# Reset password to USOIT account
New-LocalUser -Name USOIT -Password $securePassword -AccountNeverExpires -Description "USO IT Administrator Account" -PasswordNeverExpires  -ErrorAction SilentlyContinue
Set-LocalUser -Name USOIT -AccountNeverExpires -Description "USO IT Administrator Account" -Password $securePassword -PasswordNeverExpires $true

# Add USOIT to administrators group
Get-LocalGroupMember -Group Administrators -Member USOIT -ErrorAction SilentlyContinue
