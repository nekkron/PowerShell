#########################################################################
###                                                                   ###
###   The purpose of this script is to automate the renaming of       ###
###   computers and joining workgroups during the imaging process     ###
###                                                                   ###
###   This script was created by James Kasparek (jkasparek@uso.org)   ###
###   Last modified on: 20180329                                      ###
###                                                                   ###
#########################################################################

# Force Elevation of script
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))

{   
$arguments = "& '" + $myinvocation.mycommand.definition + "'"
Start-Process powershell -Verb runAs -ArgumentList $arguments
Break
}

#
Write-Host "The current computer name is $env:COMPUTERNAME"
$NewCompName = Read-Host -Prompt 'Enter a new computer name'
$NewCompName =$NewCompName.ToUpper()
Rename-Computer -NewName "$NewCompName"

if ($env:computerName.contains("EUR-")) {
    Add-Computer -WorkgroupName WKGP-EUROPE
}
if ($env:computerName.contains("PAC-")) {
    Add-Computer -WorkgroupName WKGP-PACIFIC
}
if ($env:computerName.contains("SWA-")) {
    Add-Computer -WorkgroupName WKGP-SWA
}
if ($env:computerName.contains("US-")) {
    Add-Computer -WorkgroupName WKGP-USA
}
if ($env:computerName.contains("HQ-")) {
    Add-Computer -WorkgroupName WKGP-HQ
}
