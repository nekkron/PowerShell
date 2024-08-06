@"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".pdf" ProgId="Acrobat.Document.DC" ApplicationName="Adobe Acrobat" />
</DefaultAssociations>
"@  | Out-File "$env:ProgramData\fileAssociations.xml" -Encoding utf8
if (Get-StartApps -Name "Adobe Acrobat"){
    Write-Output "Adobe Acrobat is installed on this device. Now forcing Acrobat to be the default .pdf application for new users."
    dism /online /Import-DefaultAppAssociations:"$env:ProgramData\fileAssociations.xml"
} else {
    Write-Output "Adobe Acrobat is not installed on this system!"
    Exit 1
}
Exit 0
