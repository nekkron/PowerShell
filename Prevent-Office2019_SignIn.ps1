<# 
Reference Article: https://docs.microsoft.com/en-us/answers/questions/166141/prevent-automatic-sign-in-to-office-desktop-applic.html
[HKEY_CURRENT_USER\software\policies\microsoft\office\16.0\common]
Value Name = autoorgidgetkey
Value Type = REG_DWORD
Value = 0

Reference Article: https://admx.help/?Category=Office2016&Policy=office16.Office.Microsoft.Policies.Windows::L_OrgIdEDUEnabledCentennial
Registry Hive	HKEY_LOCAL_MACHINE
Registry Path	software\policies\microsoft\office\16.0\common\licensing
Value Name	orgideduenabledcentennial
Value Type	REG_DWORD
Enabled Value	1
Disabled Value	0
#>

# Start Logging (path will be created if it doesn't already)
Start-Transcript -Path (Join-Path C:\support $LogFileName) -Append

# Check if the registry key exists
$KeyTest = Test-Path HKCU:\Software\Microsoft\Office\16.0\Common

if($KeyTest){
    # Update the create/update the value
    New-ItemProperty -Path HKCU:\Software\Microsoft\Office\16.0\Common -Name autoorgidgetkey -Value 0 -PropertyType Dword -Force
}
else{
    # Add the registry key
    New-Item -Path HKCU:\Software\Microsoft\Office\16.0\Common -Force
    # Update the create/update the value
    New-ItemProperty -Path HKCU:\Software\Microsoft\Office\16.0\Common -Name autoorgidgetkey -Value 0 -PropertyType Dword -Force
}

# Stop Logging
Stop-Transcript
