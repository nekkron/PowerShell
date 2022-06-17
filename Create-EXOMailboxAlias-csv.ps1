# https://docs.microsoft.com/en-us/powershell/module/exchange/set-mailbox?view=exchange-ps#example-7
# https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps
$Aliases  = Import-Csv c:/usr/alias.csv
<#
# Prerequisites
    # https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps#prerequisites-for-the-exo-v2-module
#winrm quickconfig
# Enable BASIC Authentication
if(!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client')) {
    Write-Host "Creating WinRM registry path for BASIC authentication."
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowBasic' -Type DWord -Value '1' | Out-Null
        } Else {
    Write-Host "Modifying WinRM registry key to enable BASIC authentication"
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client' -Name 'AllowBasic' -Type DWord -Value '1' | Out-Null
        }
#>
# Installing/Updating ExchangeOnlineManagement module
if(Get-Module ExchangeOnlineManagement -ListAvailable){
    Write-Host "Exchange Online Management module is installed. Checking for updates."
    Update-Module -Name ExchangeOnlineManagement -ErrorAction Continue
        } ELSE {
    Write-Host "Installing the Exchange Online Management module for the current user"
    Install-Module -Name ExchangeOnlineManagement -MinimumVersion 2.0.5 -Scope CurrentUser -ErrorAction Stop # https://www.powershellgallery.com/packages/ExchangeOnlineManagement
    }
Import-Module ExchangeOnlineManagement -ErrorAction Stop
# Checks if EXO connection is present
if (!(Get-PSSession | Where-Object {$_.Name -match 'ExchangeOnline' -and $_.Availability -eq 'Available'})) { 
Write-Host "Connecting to Exchange Online"
Connect-ExchangeOnline -LogDirectoryPath C:\ProgramData\Powershell\ -LogLevel All -ShowBanner:$false } Else {
Write-Host "Already connected to Exchange Online" }
# Creating alias to mailbox
Write-Host "Creating asliases from .csv file."
foreach($Alias in $Aliases){
    if((Get-EXOMailbox $Alias.Name -ErrorAction 'SilentlyContinue') -eq $null){
        Write-Host -BackgroundColor Red -ForegroundColor White -Object "Mailbox does not exist! Create mailbox before adding aliases!"
    } 
    Set-Mailbox $Alias.Name -EmailAddresses @{Add=$Alias.Alias}
}
Write-Host "The script has completed."
Disconnect-ExchangeOnline
