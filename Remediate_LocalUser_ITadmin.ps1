#=============================================================================================================================
#
# Script Name:     Remediate-LocalUser_ITadmin.ps1
# Description:     Remediates USOIT account issue if detected in Detect-LocalUser_ITadmin.ps1
# Notes:           Changing the variable $securePassword changes the password of the USOIT account
#
#=============================================================================================================================

# Variables
$securePassword=ConvertTo-SecureString password1 -AsPlainText -Force

# Reset password to admin account
New-LocalUser -Name "IT Admin" -Password $securePassword -AccountNeverExpires -Description "IT Administrator Account" -PasswordNeverExpires  -ErrorAction SilentlyContinue
Set-LocalUser -Name "IT Admin" -AccountNeverExpires -Description "IT Administrator Account" -Password $securePassword -PasswordNeverExpires $true

# Add to administrators group
Get-LocalGroupMember -Group Administrators -Member "IT Admin" -ErrorAction SilentlyContinue
