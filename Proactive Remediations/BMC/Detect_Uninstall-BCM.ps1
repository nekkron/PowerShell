#=============================================================================================================================
#
# Script Name:     Detect_Uninstall-BCM.ps1
# Description:     Script detects if the executable for BMC Client Management Agent is installed on the device after performing uninstallation
# Notes:           No variable substitution should be necessary
#
#=============================================================================================================================

# Define Variables
$curSvcStat,$svcCTRSvc,$errMsg = "","",""

# Main script
   
   
If (-not (Test-Path -Path 'C:\Program Files\BMC Software\Client Management\Client\bin\mtxagent.exe')){
    Write-Host "BMC Client Management Agent is not present on this machine"
	exit 0   
} Else {
    If(Test-Path -Path 'C:\Program Files\BMC Software\Client Management\Client\bin\mtxagent.exe'){
    Write-Host "BMC Client Management Agent is still present on this machine!"
	exit 1
    }
    Else{
        Write-Error "Error: " + $errMsg
        exit 1
    }
}
