#=============================================================================================================================
#
# Script Name:     Detect_BMCClintManagementServiceState.ps1
# Description:     Purpose of this script is to start a stopped service or restart a running service.
# Notes:           No variable substitution should be necessary
#
#=============================================================================================================================

# Define Variables
$curSvcStat,$svcCTRSvc,$errMsg = "","",""

# Main script
   
   
If (-not (Test-Path -Path 'C:\Program Files\BMC Software\Client Management\Client\bin\mtxagent.exe')){
    Write-Host "BMC Client Management Agent is not present on this machine"
	exit 1
} 

Try{        
    $svcCTRSvc = Get-Service "BMC Client Management Agent"
    $curSvcStat = $svcCTRSvc.Status
    Write-Output "BMC Client Management Agent service is currently... $curSvcStat"
}

Catch{    
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}

If ($curSvcStat -eq "Running"){
    Restart-Service -Name "BMC Client Management Agent" -Force
    Write-Output "BMC Client Management Agent service is currently... $curSvcStat"
    exit 0                        
}
Else{
    If($curSvcStat -eq "Stopped"){
        Write-Output "BMC Client Management Agent service is currently... $curSvcStat. Now starting the service."
        Start-Service -Name "BMC Client Management Agent"
        exit 0
    }
    Else{
        Write-Error "Error: " + $errMsg
        exit 1
    }
}
