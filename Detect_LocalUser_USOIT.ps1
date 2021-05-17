#=============================================================================================================================
#
# Script Name:     Detect-LocalUser_USOIT.ps1
# Description:     Detect if USOIT account exists and if the password must be changed at next logon. Remediate-LocalUser_USOIT.ps1 resolves the issue, if detected
# Notes:           Don't change the variables!
#
#=============================================================================================================================

# Variables
 $results = @()
 $localUSOExists = Get-LocalUser -Name USOIT -ErrorAction SilentlyContinue
 $passwordExpires = Get-WmiObject -Class Win32_UserAccount -Filter  "Name='USOIT'" | Select PasswordExpires
 
 try
{
     if (-not $localUSOExists) {
      Write-Host "USOIT needs remediation"
      exit 1
    }
    $results = @(Get-WmiObject -Class Win32_UserAccount -Filter  "Name='USOIT'" | Select PasswordExpires)
        if (($results -like "*True*")){
        #Below necessary for Intune as of 10/2019 will only remediate Exit Code 1
        Write-Host "USOIT needs remediation"
        exit 1
    }
    else{
        #No matching certificates, do not remediate
        Write-Host "No issues with USOIT account"        
        exit 0
    }   
}
catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}
