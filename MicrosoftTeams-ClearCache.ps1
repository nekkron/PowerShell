# This script requires "Set-ExecutionPolicy -RemoteSigned" at a minimum
# This will close Internet Explorer, Microsoft Edge (EdgeHTML), Microsoft Edge (Chromium), and Google Chrome. Make sure all work is saved prior to running this script.

Write-Host "Save all your work before running this program. All Internet browsers will close and any unsaved work will be lost." -ForegroundColor Red
$challenge = Read-Host "Are you sure you want to delete the Microsoft Teams Cache (Y/N)?"
$challenge = $challenge.ToUpper()
if ($challenge -eq "N"){
    Stop-Process -Id $PID
        }elseif ($challenge -eq "Y"){
            Write-Host "Stopping Teams Process" -ForegroundColor Yellow
            try{
                Get-Process -ProcessName Teams | Stop-Process -Force
                Start-Sleep -Seconds 3
                Write-Host "Teams Process Sucessfully Stopped" -ForegroundColor Green
            }catch{
                echo $_
            }
        Write-Host "Clearing Teams Disk Cache" -ForegroundColor Yellow
            try{
                Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\application cache\cache" | Remove-Item -Recurse -Confirm:$false
                Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\blob_storage" | Remove-Item -Recurse -Confirm:$false
                Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\cache" | Remove-Item -Recurse -Confirm:$false
                Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\databases" | Remove-Item -Recurse -Confirm:$false
                Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\gpucache" | Remove-Item -Recurse -Confirm:$false
                Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\Indexeddb" | Remove-Item -Recurse -Confirm:$false
                Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\Local Storage" | Remove-Item -Recurse -Confirm:$false
                Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\tmp" | Remove-Item -Recurse -Confirm:$false
                Write-Host "Teams Disk Cache Cleaned" -ForegroundColor Green
            }catch{
                echo $_
            }
        Write-Host "Stopping IE Process" -ForegroundColor Yellow
            try{
                Get-Process -ProcessName MicrosoftEdge | Stop-Process -Force -ErrorAction SilentlyContinue
                Get-Process -ProcessName IExplore | Stop-Process -Force -ErrorAction SilentlyContinue
                Write-Host "Internet Explorer and Edge Processes Sucessfully Stopped" -ForegroundColor Green
            }catch{
                echo $_
            }
        Write-Host "Clearing IE Cache" -ForegroundColor Yellow
            try{
                RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 8
                RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 2
                Write-Host "IE and Edge Cleaned" -ForegroundColor Green
            }catch{
                echo $_
            }
        Write-Host "Stopping Edge Process" -ForegroundColor Yellow
            try{
                Get-Process -ProcessName msedge| Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 3
                Write-Host "Edge Process Sucessfully Stopped" -ForegroundColor Green
            }catch{
                echo $_
            }
        Write-Host "Clearing Edge Cache" -ForegroundColor Yellow
            try{
                Get-ChildItem -Path $env:LOCALAPPDATA"\Microsoft\Edge\User Data\Default\Cache" | Remove-Item -Confirm:$false
                Get-ChildItem -Path $env:LOCALAPPDATA"\Microsoft\Edge\User Data\Default\Cookies" -File | Remove-Item -Confirm:$false
                Get-ChildItem -Path $env:LOCALAPPDATA"\Microsoft\Edge\User Data\Default\Web Data" -File | Remove-Item -Confirm:$false
                Write-Host "Edge Cleaned" -ForegroundColor Green
            }catch{
                echo $_
            }
        Write-Host "Stopping Chrome Process" -ForegroundColor Yellow
            try{
                Get-Process -ProcessName Chrome| Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 3
                Write-Host "Chrome Process Sucessfully Stopped" -ForegroundColor Green
            }catch{
                echo $_
            }
        Write-Host "Clearing Chrome Cache" -ForegroundColor Yellow
            try{
                Get-ChildItem -Path $env:LOCALAPPDATA"\Google\Chrome\User Data\Default\Cache" | Remove-Item -Confirm:$false
                Get-ChildItem -Path $env:LOCALAPPDATA"\Google\Chrome\User Data\Default\Cookies" -File | Remove-Item -Confirm:$false
                Get-ChildItem -Path $env:LOCALAPPDATA"\Google\Chrome\User Data\Default\Web Data" -File | Remove-Item -Confirm:$false
                Write-Host "Chrome Cleaned" -ForegroundColor Green
            }catch{
                echo $_
            }
        Write-Host "Cleanup Complete... Launching Teams" -ForegroundColor Green
        Start-Process -FilePath $env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe
        Stop-Process -Id $PID
        }else{
    Stop-Process -Id $PID
}
