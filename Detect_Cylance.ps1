#=============================================================================================================================
#
# Script Name:     Detect_Cylance.ps1
# Description:     Script detects if the executable for CylancePROTECT is installed on the device after performing uninstallation
# Notes:           No variable substitution should be necessary
#
#=============================================================================================================================

# Define Variables
$curSvcStat,$svcCTRSvc,$errMsg = "","",""

# Main script
   
   
If (Test-Path -Path '$env:ProgramFiles\Cylance\Desktop\CyProtect.exe'){
    Write-Host "CylancePROTECT is installed."
	exit 1
} Else {
    If (-not (Test-Path -Path '$env:ProgramFiles\Cylance\Desktop\CyProtect.exe')){
    Write-Host "CylancePROTECT is NOT on this machine!"
	exit 0
    }
}
