if (Test-Path -Path "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" -PathType Leaf) {
     try {
         cmd.exe /c "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" assign --api-token <API TOKEN> --group "<GroupName>" --grant-easy-access --reassign
         Write-Host "The <GroupName> TeamViewer policies have been applied."
     }
     catch {
         throw $_.Exception.Message
     }
 }
# If TeamViewer isn't installed
 else {
     Write-Host "TeamViewer is not installed on this device!"
 }
