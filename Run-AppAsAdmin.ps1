<# 
    .ROLE
	===========================================================================
	 Created by:   	James Kasparek
	 Created on:   	2024/04/12
	 Filename:     	Run-AppAsAdmin.ps1
	===========================================================================
    .DESCRIPTION
    This script creates a local administrator account and creates a desktop shortcut icon that runs
    as the $localUser account.
    .NOTES 
    - This works best when deployed manually on specific machines.
    - After the script executes successfully, run the newly created shortcut and enter the chosen password
        to the $localUser account. The password is then saved in Credential Manager of the signed-in user.
    .LINK
    - https://www.thewindowsclub.com/allow-standard-users-to-run-a-program-with-admin-rights
#>

Start-Transcript -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Run-ViPlex-As-Admin.log"
# Variables - User Account
$localUser = "AppUser"
$localDescription = "Local Admin account for App"
$localGroup = "Administrators"
$securePassword = Read-Host "Enter a strong password." -AsSecureString
# Variables - Shortcut
$oldShortcut = "$env:PUBLIC\Desktop\OriginalApp.lnk"
$newShortcut = "$env:ProgramData\App_Shortcut.lnk"
$shortcutDescription = "Shortcut Description"
$shortcutFile = "$env:WinDir\system32\runas.exe" # DO NOT CHANGE
$shortcutArguments = "/user:$localUser /savecred `"C:\Path\To\Application.exe`""
$shortcutIcon = "C:\Path\To\Application.ico"
$shortcutWindowStyle = 1     # Window size [1=Normal] [3=Maximized] [7=Minimized]
# Waving the magic wand
$ErrorOccurred = $false
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module Microsoft.Powershell.LocalAccounts -SkipEditionCheck -Force
}
if (!(Get-LocalUser -Name $localUser -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "Creating the '$localUser' account"
        New-LocalUser -Name $localUser -Password $securePassword -ErrorAction SilentlyContinue
    } 
    catch {
        Write-Host "An error occurred:" -BackgroundColor Red -ForegroundColor Black
        Write-Host "Please create the local account '$localUser' manually. Once completed, close Local Users and Groups manager."
        Start-Process lusrmgr.msc -Wait
}
}
Write-Host "Configuring the '$localUser' account"
Set-LocalUser -Name $localUser -Password $securePassword -Description $localDescription -AccountNeverExpires -PasswordNeverExpires $true -ErrorAction SilentlyContinue
Write-Host "Verifying $localUser was created."
if (!(Get-LocalUser -Name $localUser -ErrorAction SilentlyContinue)) {
    Write-Error "'$localUser' was not created! Exiting as this script cannot continue!"
    Stop-Transcript
    Pause
    Invoke-Item "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Run-ViPlex-As-Admin.log"
    exit 1
}
Write-Host "Adding '$localUser' to the '$localGroup' group."
Add-LocalGroupMember -Group $localGroup -Member $localUser -ErrorAction SilentlyContinue
Write-Host "Creating the shortcut."
try {
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($NewShortcut)
    $Shortcut.TargetPath = $ShortcutFile
    $Shortcut.Arguments = $ShortcutArguments
    $Shortcut.IconLocation = $shortcutIcon
    $Shortcut.Description = $ShortcutDescription
    $Shortcut.WindowStyle = $ShortcutWindowStyle
    $Shortcut.Save()
}
catch {
    $ErrorOccurred = $true
    Write-Host "An error occurred:" -BackgroundColor Red -ForegroundColor Black
    Write-Error $_
}
Copy-Item $NewShortcut $env:PUBLIC\Desktop -Force
if (Test-Path $newShortcut, $oldShortcut -ErrorAction SilentlyContinue) {
    Write-Host "Deleting the original shortcut."
    Remove-Item -Path $oldShortcut -Force
} else {
    $ErrorOccurred = $true
    Write-Host "An error occurred:" -BackgroundColor Red -ForegroundColor Black
    Write-Host $_
}
Stop-Transcript

if($ErrorOccurred) {
    Write-Output $_
    exit 1
} else {
    Write-Output "Success!"
    exit 0
}
