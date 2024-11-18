
<#
.SYNOPSIS
    This script creates a desktop shortcut for an executable with specified options. It can create a shortcut for all users (including new ones) or for existing users only.
.DESCRIPTION
    This script creates a desktop shortcut for an executable with specified options. 
    It can create a shortcut for all users (including new ones) or for existing users only.

    You can also provide a base64 string on line 79 enclosed in quotes and an icon directory, and the script will use that instead.
.EXAMPLE
    This will create a shortcut that opens www.google.com in Firefox on JohnSmith's desktop. This is not limited to just browsers; you can specify any executable you would normally be able to via the "Create Shortcut" menu.
    
    -Name "ERP App" -EXEPath "C:\Program Files\Mozilla Firefox\firefox.exe" -StartIn "C:\Program Files\Mozilla Firefox" -IconPath "C:\ProgramData\ERPapp\customicon.ico" -Arguments "https://www.google.com" -User "JohnSmith"

    Creating Shortcut at C:\Users\JohnSmith\Desktop\ERP App.lnk

.PARAMETER NAME
    The name of the shortcut, e.g., "Login Portal".

.PARAMETER ExePath
    The target field in the shortcut, excluding arguments.

.PARAMETER Arguments
    The arguments for the executable inside the shortcut.

.PARAMETER StartIn
    Some executables require that they be opened in a specific directory.

.PARAMETER Icon
    The path to an image file to use for the shortcut. You could also place the base64 string on line 79 and specify an IconDirectory with the below parameter.

.PARAMETER IconDirectory
    Path to store the .ico file to use for the shortcut.

.PARAMETER IconURL
    A link to an image file you would like to use for the shortcut. You could also place the base64 string on line 79 and specify an IconDirectory using '-IconDirectory'.

.PARAMETER AllExistingUsers
    Creates the shortcut for all existing users but not for new users, e.g., C:\Users\*\Desktop\shortcut.lnk.

.PARAMETER AllUsers
    Creates the shortcut in C:\Users\Public\Desktop.

.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 7, Windows Server 2008
    Release Notes: Split the script into three separate scripts, added script variable support, and improved icon support.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Name,
    [Parameter()]
    [String]$ExePath,
    [Parameter()]
    [String]$Arguments,
    [Parameter()]
    [String]$StartIn,
    [Parameter()]
    [String]$Icon,
    [Parameter()]
    [String]$IconDirectory,
    [Parameter()]
    [String]$IconUrl,
    [Parameter()]
    [Switch]$AllExistingUsers,
    [Parameter()]
    [String]$ExcludeUsers,
    [Parameter()]
    [Switch]$AllUsers
)

begin {
    Add-Type -AssemblyName System.Drawing

    # If the line below is replaced with $IconBase64 = 'YourBase64EncodedImageInQuotes', the script will decode it and use it for the desktop shortcut. Be sure to provide an Icon Storage Directory.
    $IconBase64 = $null

    # Replace existing parameters with Form Variables if used.
    if ($env:shortcutName -and $env:shortcutName -notlike "null") { $Name = $env:shortcutName }
    if ($env:createTheShortcutFor -and $env:createTheShortcutFor -notlike "null") { 
        if ($env:createTheShortcutFor -eq "All Users") { $AllUsers = $True }
        if ($env:createTheShortcutFor -eq "All Existing Users") { $AllExistingUsers = $True }
    }
    if ($env:exePath -and $env:exePath -notlike "null") { $ExePath = $env:exePath }
    if ($env:exeArguments -and $env:exeArguments -notlike "null") { $Arguments = $env:exeArguments }
    if ($env:exeShouldStartIn -and $env:exeShouldStartIn -notlike "null") { $StartIn = $env:exeShouldStartIn }
    if ($env:linkToIconFile -and $env:linkToIconFile -notlike "null") { $IconUrl = $env:linkToIconFile }
    if ($env:iconStorageDirectory -and $env:iconStorageDirectory -notlike "null") { $IconDirectory = $env:iconStorageDirectory }

    # Ensure a user is specified for shortcut creation.
    if (-not $AllUsers -and -not $AllExistingUsers -and -not $User) {
        Write-Host "[Error] You must specify which desktop to create the shortcut on!"
        exit 1
    }

    $invalidFileNames = '[<>:"/\\|?*\x00-\x1F]|\.$|\s$'
    if ($Name -match $invalidFileNames) {
        Write-Host '[Error] The name you specified contains one of the following invalid characters or ends with a period. <>:"/\|?*'
        exit 1
    }

    $ExitCode = 0
    
    # Icons are secondary. If no information is given, continue without them, but notify the technician.
    if (($Icon -or $IconUrl) -and -not $IconDirectory) {
        Write-Warning "An icon was provided, but no storage location was specified. Use the Icon Storage Directory parameter to specify a directory to store it. (You may want this directory to be accessible by all users.)"
        Write-Warning "Ignoring supplied icon info."
        $ExitCode = 1
        $Icon = $null
        $IconUrl = $null
    }

    if ($Icon) {
        $FileName = Split-Path $Icon -Leaf

        # Check for valid icon formats. Only support .png, .jpg, .jpeg, .ico, and .gif.
        if ($FileName -notmatch '\.bmp$' -and $FileName -notmatch '\.png$' -and $FileName -notmatch '\.jpg$' -and $FileName -notmatch '\.jpeg$' -and $FileName -notmatch '.ico$' -and $FileName -notmatch '.gif$') {
            Write-Warning "Your icon is in an invalid format. Only .png, .jpg, .jpeg, .ico, and .gif formats are supported. Switching to the default icon. You can re-run the script to replace the icon."
            $Icon = $null
        }

        if (-not (Test-Path $Icon -ErrorAction SilentlyContinue)) {
            Write-Warning "It looks like your icon is missing. Skipping for now; re-run the script with a valid path to add the icon."
            $Icon = $null
        }
    }

    # Create the directory for the icon if it doesn't exist.
    if ($IconDirectory -and -not (Test-Path $IconDirectory -ErrorAction SilentlyContinue)) {
        New-Item -ItemType Directory -Path $IconDirectory | Out-Null
    }

    # For PowerShell 2.0 and 3.0 compatibility we're going to need to create a Get-FileHash function
    if ($PSVersionTable.PSVersion.Major -lt 4) {
        function Get-FileHash {
            param (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                [string[]]$Path,
                [Parameter(Mandatory = $false)]
                [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MD5")]
                [string]$Algorithm = "SHA256"
            )
            $Path | ForEach-Object {
                # Only hash files that exist
                $CurrentPath = $_
                if ($(Test-Path -Path $CurrentPath -ErrorAction SilentlyContinue)) {
                
                    $HashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
                    $Hash = [System.BitConverter]::ToString($hashAlgorithm.ComputeHash([System.IO.File]::ReadAllBytes($CurrentPath)))
                    @{
                        Algorithm = $Algorithm
                        Path      = $Path
                        Hash      = $Hash.Replace('-', '')
                    }
                }
            }
        }
    }

    # Convert a Base64 string to a file.
    function ConvertFrom-Base64 {
        param(
            $Base64,
            $Path
        )
        $bytes = [Convert]::FromBase64String($Base64)

        [IO.File]::WriteAllBytes($Path, $bytes)
    }

    # Utility function for downloading files.
    function Invoke-Download {
        param(
            [Parameter()]
            [String]$URL,
            [Parameter()]
            [String]$BaseName,
            [Parameter()]
            [int]$Attempts = 3,
            [Parameter()]
            [Switch]$SkipSleep
        )

        # In case 'https://' is omitted from the URL.
        if ($URL -notmatch "^http(s)?://") {
            Write-Warning "http(s):// is required to download the file. Adding https:// to your input...."
            $URL = "https://$URL"
            Write-Warning "New Url $URL."
        }
    
        Write-Host "Downloading using $URL"

        $SupportedTLSversions = [enum]::GetValues('Net.SecurityProtocolType')
        if ( ($SupportedTLSversions -contains 'Tls13') -and ($SupportedTLSversions -contains 'Tls12') ) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
        }
        elseif ( $SupportedTLSversions -contains 'Tls12' ) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        }
        else {
            # Not everything requires TLS 1.2, but we'll try anyways.
            Write-Warning "TLS 1.2 and or TLS 1.3 isn't supported on this system. This download may fail!"
            if ($PSVersionTable.PSVersion.Major -lt 3) {
                Write-Warning "PowerShell 2 / .NET 2.0 doesn't support TLS 1.2."
            }
        }

        $i = 1
        While ($i -le $Attempts) {
            # Some cloud services have rate-limiting
            if (-not ($SkipSleep)) {
                $SleepTime = Get-Random -Minimum 3 -Maximum 15
                Write-Host "Waiting for $SleepTime seconds."
                Start-Sleep -Seconds $SleepTime
            }
            if ($i -ne 1) { Write-Host "" }
            Write-Host "Download Attempt $i"

            try {
                # Invoke-WebRequest is preferred because it supports links that redirect, e.g., https://t.ly
                if ($PSVersionTable.PSVersion.Major -lt 4) {
                    # Figures out the type of file
                    $WebClient = New-Object System.Net.WebClient
                    $Response = $WebClient.OpenRead($Url)
                    $MimeType = $WebClient.ResponseHeaders["Content-Type"]
                    $DesiredExtension = switch -regex ($MimeType) {
                        "image/jpeg|image/jpg" { "jpg" }
                        "image/png" { "png" }
                        "image/gif" { "gif" }
                        "image/bmp|image/x-windows-bmp|image/x-bmp" { "bmp" }
                        "image/x-icon|image/vnd.microsoft.icon|application/ico" { "ico" }
                        default { 
                            throw "[Error] The URL you provided does not provide a supported image type. Image Types Supported: jpg, jpeg, ico, bmp, png and gif. Image Type detected: $MimeType"
                        }
                    }
                    # Downloads the file preserving the extension
                    $Path = "$BaseName.$DesiredExtension"
                    $WebClient.DownloadFile($URL, $Path)
                }
                else {
                    # Standard options
                    $WebRequestArgs = @{
                        Uri                = $URL
                        MaximumRedirection = 10
                        UseBasicParsing    = $true
                        Method             = "GET"
                    }

                    # Figures out the type of file
                    $Response = Invoke-WebRequest @WebRequestArgs
                    $MimeType = $Response.Headers.'Content-Type'
                    $DesiredExtension = switch -regex ($MimeType) {
                        "image/jpeg|image/jpg" { "jpg" }
                        "image/png" { "png" }
                        "image/gif" { "gif" }
                        "image/bmp|image/x-windows-bmp|image/x-bmp" { "bmp" }
                        "image/x-icon|image/vnd.microsoft.icon|application/ico" { "ico" }
                        default { 
                            throw "[Error] The URL you provided does not provide a supported image type. Image Types Supported: jpg, jpeg, ico, bmp, png and gif. Image Type detected: $MimeType"
                        }
                    }
                    # Define the path for saving the file
                    $Path = "$BaseName.$DesiredExtension"

                    # Save the content to the file
                    $Response.Content | Set-Content -Path $Path -Encoding Byte
                }

                $File = Test-Path -Path $Path -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "An error has occurred while downloading!"
                Write-Warning $_.Exception.Message
                $_

                if ($Path -and (Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
                    Remove-Item $Path -Force -Confirm:$false -ErrorAction SilentlyContinue
                }

                $File = $False
            }

            if ($File) {
                $i = $Attempts
            }
            else {
                Write-Warning "File failed to download. Check the link/URL and ensure it is correct, please note Ninja may have stripped out the following characters '&|;$><`!' from the link/URL."
                Write-Host ""
            }

            $i++
        }

        if ($Path -and -not (Test-Path $Path)) {
            Write-Warning "Failed to download file!"
        }
        else {
            return $Path
        }
    }

    # Convert an image to an icon file. This method creates a png and then forms an ico file by appending the png's binary.
    function ConvertFrom-Image {
        param(
            $ImagePath,
            $Path
        )

        # Grab an instance of the image and blank bitmap
        try {
            $image = [Drawing.Image]::FromFile($ImagePath)
        }
        catch [System.OutOfMemoryException] {
            Write-Host "[Error] Loading Image file is either an unsupported file, or to large to process."
            return
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            return
        }

        # Resize the image to 255px by 255px while maintaining quality.
        # If you want transparency, you'll need an Alpha channel in the pixel format.
        $bitmap = New-Object System.Drawing.Bitmap (255, 255, [system.drawing.imaging.PixelFormat]::Format32bppArgb)
        $bitmap.SetResolution(255, 255)

        # Create a graphics object which will be used to resize the image to 255px by 255px
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

        # Set some quality settings for the resize operation
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        # Draw the image onto the bitmap
        $graphics.DrawImage($Image, 0, 0, 255, 255)
        
        # Temporarily save the image as a png
        $RandomNumber = Get-Random -Maximum 1000000
        $bitmap.Save("$env:TEMP\image-$RandomNumber.png", [System.Drawing.Imaging.ImageFormat]::Png)
        $png = "$env:TEMP\image-$RandomNumber.png"

        # Build the ico file using the png binary.
        if ($PSVersionTable.PSVersion.Major -gt 5) {
            $pngBytes = Get-Content -Path $png -AsByteStream
        }
        elseif ($PSVersionTable.PSVersion.Major -gt 2) {
            $pngBytes = Get-Content -Path $png -Encoding Byte -Raw
        }
        else {
            $pngBytes = [System.IO.File]::ReadAllBytes($png)
        }
        $icoHeader = [byte[]] @(0, 0, 1, 0, 1, 0)
        $imageDataSize = $pngBytes.Length
        $icoDirectory = [byte[]] @(
            255, 255, # icon size
            0, 0, # color count
            0, 0, # reserved
            0, 0, # hotspot x, hotspot y
            ($imageDataSize -band 0xFF),
            ([Math]::Floor($imageDataSize / [Math]::Pow(2, 8)) -band 0xFF),
            ([Math]::Floor($imageDataSize / [Math]::Pow(2, 16)) -band 0xFF),
            ([Math]::Floor($imageDataSize / [Math]::Pow(2, 24)) -band 0xFF),
            22, 0, 0, 0  # offset to image data
        )
        $iconData = $icoHeader + $icoDirectory + $pngBytes

        # Save the completed icon file and clean up any temporary files.
        if (Test-Path $Path -ErrorAction SilentlyContinue) { Remove-Item $Path -Force }
        [System.IO.File]::WriteAllBytes($Path, $iconData)

        if (Test-Path $png -ErrorAction SilentlyContinue) { Remove-Item $png -Force }
        $bitmap.Dispose()
        $image.Dispose()
        $graphics.Dispose()
        [System.GC]::Collect()

        # Refresh the icon cache depending on the OS version.
        if ([System.Environment]::OSVersion.Version.Major -ge 10) {
            Invoke-Command { ie4uinit.exe -show }
        }
        else {
            Invoke-Command { ie4uinit.exe -ClearIconCache }
        }
    }

    # Verify if the script is being run with elevated privileges.
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Test-IsElevated)) {
        Write-Host -Object "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # Retrieve all registry paths for actual users (excluding system or network service accounts).
    function Get-UserHives {
        param (
            [Parameter()]
            [ValidateSet('AzureAD', 'DomainAndLocal', 'All')]
            [String]$Type = "All",
            [Parameter()]
            [String[]]$ExcludedUsers,
            [Parameter()]
            [switch]$IncludeDefault
        )

        # Different SID patterns for user account types: AzureAD, Domain, or Local.
        $Patterns = switch ($Type) {
            "AzureAD" { "S-1-12-1-(\d+-?){4}$" }
            "DomainAndLocal" { "S-1-5-21-(\d+-?){4}$" }
            "All" { "S-1-12-1-(\d+-?){4}$" ; "S-1-5-21-(\d+-?){4}$" } 
        }

        # Extract user profiles that match the SID patterns. 
        $UserProfiles = Foreach ($Pattern in $Patterns) { 
            Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
                Where-Object { $_.PSChildName -match $Pattern } | 
                Select-Object @{Name = "SID"; Expression = { $_.PSChildName } }, 
                @{Name = "UserHive"; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }, 
                @{Name = "UserName"; Expression = { "$($_.ProfileImagePath | Split-Path -Leaf)" } },
                @{Name = "Path"; Expression = { $_.ProfileImagePath } }
        }

        # Handle situations where information from the .Default user is required.
        switch ($IncludeDefault) {
            $True {
                $DefaultProfile = "" | Select-Object UserName, SID, UserHive, Path
                $DefaultProfile.UserName = "Default"
                $DefaultProfile.SID = "DefaultProfile"
                $DefaultProfile.Userhive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
                $DefaultProfile.Path = "C:\Users\Default"

                $DefaultProfile | Where-Object { $ExcludedUsers -notcontains $_.UserName }
            }
        }

        $UserProfiles | Where-Object { $ExcludedUsers -notcontains $_.UserName }
    }

    # The actual shortcut creation
    function New-Shortcut {
        [CmdletBinding()]
        param(
            [Parameter()]
            [String]$Arguments,
            [Parameter()]
            [String]$IconPath,
            [Parameter(ValueFromPipeline = $True)]
            [String]$Path,
            [Parameter()]
            [String]$Target,
            [Parameter()]
            [String]$WorkingDir
        )
        process {
            Write-Host "Creating Shortcut at $Path"
            $ShellObject = New-Object -ComObject ("WScript.Shell")
            $Shortcut = $ShellObject.CreateShortcut($Path)
            $Shortcut.TargetPath = $Target
            if ($WorkingDir) { $Shortcut.WorkingDirectory = $WorkingDir }
            if ($Arguments) { $ShortCut.Arguments = $Arguments }
            if ($IconPath) { $Shortcut.IconLocation = $IconPath }
            $Shortcut.Save()

            if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
                Write-Host "[Error] Unable to create Shortcut at $Path"
                exit 1
            }
        }
    }
}
process {
    $ShortcutPath = New-Object System.Collections.Generic.List[String]

    # Creating the filename's for the path
    if ($Url) { $File = "$Name.url"; $Target = $Url }
    if ($ExePath) { $File = "$Name.lnk"; $Target = $ExePath }
    if ($RDPTarget) { $File = "$Name.rdp" }

    # Grabing the excluded users
    if ($ExcludeUsers) { $ExcludedUsers = ($ExcludeUsers -split ",").trim() }

    # Building the path's and adding it to the ShortcutPath list
    if ($AllUsers) { $ShortcutPath.Add("$env:Public\Desktop\$File") }

    if ($AllExistingUsers) {
        $UserProfiles = Get-UserHives -ExcludedUsers $ExcludedUsers
        # Loop through each user profile
        $UserProfiles | ForEach-Object { $ShortcutPath.Add("$($_.Path)\Desktop\$File") }
    }

    if ($User) { 
        $UserProfile = Get-UserHives | Where-Object { $_.Username -like $User }
        $ShortcutPath.Add("$($UserProfile.Path)\Desktop\$File")
    }

    $ShortcutArguments = @{
        Target     = $Target
        WorkingDir = $StartIn
        Arguments  = $Arguments
    }

    # If we're given a url we'll want to download it
    if ($IconUrl) {
        $DownloadArguments = @{
            URL      = $IconUrl
            BaseName = "$IconDirectory\$Name"
        }
        if ($SkipSleep) { $DownloadArguments["SkipSleep"] = $True }

        $Icon = Invoke-Download @DownloadArguments
        if ($Icon -and -not (Test-Path $Icon -ErrorAction SilentlyContinue)) {
            $ExitCode = 1
            $Icon = $Null
            $IconUrl = $Null
        }
    }

    # This will convert the base64 into an image and save it to the temp folder
    if ($IconBase64 -and $IconDirectory -and -not $Icon -and -not $IconUrl) {
        Write-Verbose "Converting Icon base64 to original image and saving to $IconDirectory..."
        ConvertFrom-Base64 -Base64 $IconBase64 -Path "$IconDirectory\$Name.Png"
        $Icon = "$IconDirectory\$Name.Png"
    }

    if ($Icon -and (Get-Item -Path $Icon).Extension -notlike ".ico") {
        $FileHash = "$((Get-FileHash -Path $Icon -Algorithm MD5).Hash)"
        Write-Verbose "Converting image to icon and saving to $IconDirectory\$FileHash.ico ..."
        ConvertFrom-Image -ImagePath $Icon -Path "$IconDirectory\$FileHash.ico"
        Remove-Item -Path $Icon -Force
        $Icon = "$IconDirectory\$FileHash.ico"
    }
    elseif ($Icon -and (Test-Path $Icon -ErrorAction SilentlyContinue)) {
        $FileHash = "$((Get-FileHash -Path $Icon -Algorithm MD5).Hash)"
        Move-Item -Path $Icon -Destination "$IconDirectory\$FileHash.ico"
        $Icon = "$IconDirectory\$FileHash.ico"
    }

    if ($Icon -and (Test-Path $Icon -ErrorAction SilentlyContinue)) {
        $ShortcutArguments["IconPath"] = $Icon
    }
    elseif ($Icon) {
        $ExitCode = 1
    }

    $ShortcutPath | New-Shortcut @ShortcutArguments

    exit $ExitCode
}end {
    
    
    
}