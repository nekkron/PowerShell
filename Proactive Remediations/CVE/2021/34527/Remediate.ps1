# https://github.com/JasonRBeer/PublicPowerShellScripts/blob/master/Remediate-PrintNightmare.ps1
<#
.SYNOPSIS
  Sets the registry value for "Allow Print Spooler to accept client connections" group policy.
.DESCRIPTION
  Sets the registry value for "Allow Print Spooler to accept client connections" group policy. This is Microsoft's recommendation for the zero day (CVE-2021-34527 - https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-34527).
.PARAMETER ScriptLogLocation
    The directory in which you would like the log file
.PARAMETER LogFileName
    The name (with extension) you would like for the log file
.PARAMETER RegPath
    The path to the registry key that will contain this value.
.PARAMETER ValueName
    The name of the registry value being added or changed.
.PARAMETER ValueType
    The type of registry value being added or changed.
.PARAMETER Value
    The enrollment token that was generated in the Google Admin portal.
.PARAMETER RestartSpooler
    Restart the spooler service after adding the registry key?
.INPUTS
  None
.OUTPUTS
  Log file stored in C:\IT\ScriptLogs\Remediate-PrintNightmare\Remediate-PrintNightmare.log
.NOTES
  Version:        1.0
  Author:         Jason Beer
  Creation Date:  7/6/2021
  Purpose/Change: Initial script development
.EXAMPLE
  Remediate-PrintNightmare -ScriptLogLocation "C:\ExampleFolder\Remediate-PrintNightmare" -RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers" -ValueName "RegisterSpoolerRemoteRpcEndPoint" -ValueType "DWord" -Value "2" -RestartSpooler $True
#>

# Parameters
Param (
    [string]$ScriptLogLocation = "C:\support\CVE-2021-34527",
    [string]$LogFileName = "Remediate-PrintNightmare.log",
    [string]$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers",
    [string]$ValueName = "RegisterSpoolerRemoteRpcEndPoint",
    [string]$ValueType = "DWord",
    [string]$Value = "2",
    [bool]$RestartSpooler = $True
)

# Start Logging (path will be created if it doesn't already)
Start-Transcript -Path (Join-Path $ScriptLogLocation $LogFileName) -Append

# Check if the registry key exists
$KeyTest = Test-Path $RegPath

if($KeyTest){
    # Update the create/update the value
    New-ItemProperty -Path $RegPath -Name $ValueName -Value $Value -PropertyType $ValueType -Force
}
else{
    # Add the registry key
    New-Item -Path $RegPath -Force
    # Update the create/update the value
    New-ItemProperty -Path $RegPath -Name $ValueName -Value $Value -PropertyType $ValueType -Force
}

# Restart the spooler service
If($RestartSpooler){
    Restart-Service -Name Spooler -Force
}

# Stop Logging
Stop-Transcript
