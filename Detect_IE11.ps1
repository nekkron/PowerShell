# https://osddeployment.dk/2019/02/15/how-to-remove-internet-explorer-from-windows-10-with-intune/
# Check if Interner Explorer is installed
$check = Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -eq "Internet-Explorer-Optional-amd64"}
If ($check.State -ne "Disabled")
{
Write-Error 1
exit 1
}
exit 0
