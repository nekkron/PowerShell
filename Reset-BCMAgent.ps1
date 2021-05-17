# This script forces an immediate sync of the BMC Cliemt Management Agent

# Find if BMC Cliemt Management Agent is installed
If (-not (Test-Path -Path "C:\Program Files\BMC Software\Client Management\Client\bin\mtxagent.exe")){
    Write-Host "BMC Client Management Agent is not present on this machine"
    Write-Error -Message "BMC Client Management Agent is not present on this device." -ErrorId 1
exit 1   
} ELSE {
# At this point BMC Client Management is installed. Restarting service.
$svcCTRSvc = Get-Service "BMC Client Management Agent"
$curSvcStat = $svcCTRSvc.Status
Write-Host "Before restarting the service it is currently... $curSvcStat" -ForegroundColor Yellow
Restart-Service -Name "BMC Client Management Agent" -Force
Write-Host "The service is now... $curSvcStat" -ForegroundColor Cyan
exit 0
}
