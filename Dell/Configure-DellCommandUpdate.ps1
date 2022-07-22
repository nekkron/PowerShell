<#	
	.NOTES
	===========================================================================
	 Created with: 	Windows PowerShell ISE x64
	 Created on:   	2022-06-20
	 Created by:   	James Kasparek
	 Organization: 	United Service Organizations
	 Filename:     	Configure-DellCommandUpdate.ps1
         URL:           https://github.com/nekkron/PowerShell/blob/main/Configure-DellCommandUpdate.ps1
	===========================================================================
	.DESCRIPTION
	   Automatically configures Dell Command Update, scans for updates and applies updates without a reboot
	   Dell Command Update | Command Line Interface error codes: https://www.dell.com/support/manuals/en-us/command-update/dellcommandupdate_rg/command-line-interface-error-codes?guid=guid-fbb96b06-4603-423a-baec-cbf5963d8948&lang=en-us
#>

# Variables
$DCUcli = 'C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe'

if(!(Test-Path -Path $DCUcli)) {
    Write-Warning "Dell Command Update is not installed on this machine!"
    Write-Error -Message "DCU CLI is not installed on this device!"
    Exit
    }
Write-Host "Dell Command Update | Command Line Interface is installed on this device!" -ForegroundColor Green
Write-Host "Configuring Dell Command Update"
cmd /c $DCUcli /configure -silent -autoSuspendBitLocker=enable -userConsent=disable
Write-Host "Scanning for Dell updates"
cmd /c $DCUcli /scan -outputLog=C:\ProgramData\Dell\logs\dcu-cli.log
Write-Host "Applying Dell updates, reboot disabled."
cmd /c $DCUcli /applyUpdates -reboot=disable -outputLog=C:\ProgramData\Dell\logs\dcu-cli.log
