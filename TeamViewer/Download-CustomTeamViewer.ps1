# https://community.teamviewer.com/English/discussion/120192/automation-download-custom-teamviewer-with-powershell
# Download path
$downloadpath = "$env:ProgramData\TeamViewer"
# URL of your customized TeamViewer
$URL = "https://get.teamviewer.com/<yourcustomURL>"

# Function to create the browser object, navigate to the website, isolate the download url and download the TeamViewer QS
function Download_TeamViewer () {
    # Internet Explorer application to fool the website into thinking the connection is a client session (this is needed to return the result from javascript function that generates the downloadlink of your custom TeamViewer using the newest version of it)
    $iebrowser = New-Object -ComObject InternetExplorer.Application
    # navigates to the given Website/URL
    $iebrowser.Navigate($URL)
    # Pause for 3 seconds to creating the browser object as navigating to the website takes a little while depending on your system and internet connection
    Start-Sleep -Seconds 3
    # isolates the generated download URL of the custom TeamViewer
    $CustomTV_URL = $iebrowser.Document.getElementById('MasterBodyContent_btnRetry').href
    # Downloads the custom TeamViewer QS
    Start-BitsTransfer -source $CustomTV_URL -Destination $downloadpath\TeamViewer_Custom.exe       
}

# Try (creating path and) downloading and catch problem if this is not possible
try {
    Write-Host "Downloading custom TeamViewer..." -BackgroundColor Black -ForegroundColor Yellow
        # Creates the download path if not existent
        New-Item -Path $downloadpath -ItemType Directory | Out-Null
        # Calls the download function
        Download_TeamViewer
} catch {
    # Display error if one occurs
    $Error
    # Write information for user
    Write-Host "Download can not be started.`n`nReason: The security settings for `"Internet Zone`" in your Internet Explorer need following configuration:`n- Filedownloads need to be activated`n- Active Scripting needs to be activated" -ForegroundColor Yellow -BackgroundColor Black
    Start-Sleep -Seconds 10
    Exit 1
}
Exit 0
