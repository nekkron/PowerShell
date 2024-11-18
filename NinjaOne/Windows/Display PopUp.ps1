<#
.SYNOPSIS
    Displays a popup on the end user's screen. The script needs to be run as the 'Current Logged In User'. Use "Restart Reminder" to display a request to the end user to restart their computer.
.DESCRIPTION
    Displays a popup on the end user's screen. The script needs to be run as the 'Current Logged In User'. Use "Restart Reminder" to display a request to the end user to restart their computer. 
    See the comment block in this script's code for extra options such as changing the logo or the window title.
    Uses Windows Presentation Framework to accommodate different DPIs and image scaling. On Windows 7 and Server 2008, the script will use the older Windows Form UI.

    You can also convert an image to base64 and replace either lines 164 or 168 if you'd prefer to not have to download an image to a machine. 
.EXAMPLE
    (No Parameters on Windows 11)

    Result: Success

PARAMETER: -RestartReminder
    Displays a generic prompt requesting the user restart their machine. 
    This parameter is equivalent to the below options.
    -Text "Your IT Administrator is requesting that you restart your computer. Click 'Restart Now' after saving your work."
    -ButtonLText "Restart Now"
    -ButtonLaction "shutdown.exe /r /t 30"
    -ButtonRText "Ignore"
    -ButtonRcountdown 900
    -ButtonRDefault
.EXAMPLE
    -RestartReminder (Server 2008)
    
    WARNING: PowerShell 2 cannot import the presentation framework switching to winform...
    Ignore (895) Button Clicked!

PARAMETER: -ApplicationID "ReplaceWithWindowTitle/ApplicationID"
    This will replace the window title and it will also change the taskbar overlay icon and logo/image used in the popup 
    with the Notification Icon used by that Application ID  if it exists and is not overridden by another parameter. 
    This is the same application ID used by the Send-UserPrompt and the built-in Windows notification system.
.EXAMPLE
    -ApplicationID "Contoso Inc"
    
    Application ID with Icon found! Checking if the icon and logo were supplied elsewhere...
    The icon was not specified elsewhere in the script switching from the default icon to the Applications Notification Icon.
    The logo/image was not specified elsewhere in the script switching from the default image to the Applications Notification Icon.
    You can also switch the default Application ID on line 128

PARAMETER: -LogoPath "C:\Replace\This\Path.png"
    The location of an image you would like to use in the large image window.
    This script is running as the end-user so their account will need permission to this path.
    Can be given a URL. Just keep in mind that Ninja doesn't support these special characters: &|;$><`!.
    Can be given any size image however the script will center it and then scale it into a 250px x 125px rectangle. 
    The image will always be centered and a square 1:1 ratio will work.
    Scaling is not done on Server 2008 and Windows 7 (The image is simply centered and you may see it cut off the image if the image is too large).
    
    Supported image formats: .png, .jpg, .ico, .gif (GIFs will be static and not animated.)
    
    You can also convert an image to base64 and replace either lines 165 or 169 if you'd prefer to not have to download an image and give the script a path to it. 

PARAMETER: -IconPath "C:\Replace\This\Path.png"
    The location of an icon you would like to use for the taskbar overlay and window title bar. 
    This script is running as the end-user so their account will need permission to this path.
    Can be given a URL. Just keep in mind that Ninja doesn't support these special characters: &|;$><`!.
    Can be given any icon size however the script will convert it to 64px x 64px so it is recommended to keep to the 1:1 ratio so that the image is not squished.
    
    Supported image formats: .png, .jpg, .ico, .gif (GIFs will be static and not animated.)
    
    You can also convert an image to base64 and replace either lines 164 or 168 if you'd prefer to not have to download an image and give the script a path to it.

PARAMETER: -Text "ReplaceMeWithTextYouWantInsideThePopUp"
    The text you would like displayed inside the popup. 
    If too much text is written, a scrollbar will automatically appear, allowing the end-user to view all the text.

PARAMETER: -AllowResize
    By default, resizing the popup is not allowed. Use -AllowResize to allow resizing the window.

PARAMETER: -ButtonR
    Add a button to the bottom right (can only be specified once).

PARAMETER: -ButtonRdefault
    Set the right button as the default button. This will allow end-users to simply hit the enter key when the window is in focus to perform a click.

PARAMETER: -ButtonRtext "TextYouWouldLikeInsideTheButton"
    Change the text from 'Right Button' to whatever you put encased in quotes.
.EXAMPLE
    -ButtonRtext "Later"

    Later Button Clicked!

PARAMETER: -ButtonRaction "ReplaceWithAnyCMDcommand"
    This will set the action the right button performs when clicked. Can be given any command that will work in cmd.exe as well as parameters. ex. logoff.exe 

PARAMETER: -ButtonRcountdown "160"
    This will add a countdown to the right button with your input in seconds. When the countdown reaches 0 it'll click the button for the end user.
    The left and right button countdown cannot be used at the same time.

PARAMETER: -ButtonL
    Add a button to the bottom left (can only be specified once).

PARAMETER: -ButtonLdefault
    Set the left button as the default button. This will allow end-users to simply hit the enter key when the window is in focus to perform a click.

PARAMETER: -ButtonLtext "TextYouWouldLikeInsideTheButton"
    Change the text from 'Left Button' to whatever you put encased in quotes.
.EXAMPLE
    -ButtonLtext "Later"

    Later Button Clicked!

PARAMETER: -ButtonLaction "ReplaceWithAnyCMDcommand"
    This will set the action the left button performs when clicked. Can be given any command that will work in cmd.exe as well as parameters. ex. logoff.exe 

PARAMETER: -ButtonLcountdown
    This will add a countdown to the left button with your input in seconds. When the countdown reaches 0 it'll click the button for the end user.
    The left and right button countdown cannot be used at the same time.

PARAMETER: -Verbose
    More verbose output (useful for troubleshooting).
.OUTPUTS
  None
.NOTES
  Minimum OS Architecture Supported: Windows 7+, Server 2008+
  Release Notes: Updated calculated name
#>

[CmdletBinding()]
param (
    [Parameter()]
    [Switch]$AllowResize = [System.Convert]::ToBoolean($env:allowEnduserToResizeWindow),
    # You can set line 127 to [String]$ApplicationID = "$env:NINJA_COMPANY_NAME" to automatically use your company name.
    [Parameter()]
    [String]$ApplicationID = "NinjaOne RMM",
    [Parameter()]
    [Switch]$ButtonR,
    [Parameter()]
    [Switch]$ButtonRdefault,
    [Parameter()]
    [String]$ButtonRtext,
    [Parameter()]
    [String]$ButtonRaction,
    [Parameter()]
    [int]$ButtonRcountdown,
    [Parameter()]
    [Switch]$ButtonL,
    [Parameter()]
    [Switch]$ButtonLDefault,
    [Parameter()]
    [String]$ButtonLtext,
    [Parameter()]
    [String]$ButtonLaction,
    [Parameter()]
    [int]$ButtonLcountdown,
    [Parameter()]
    [String]$IconPath,
    [Parameter()]
    [String]$LogoPath,
    [Parameter()]
    [String]$Text,
    [Parameter()]
    [Switch]$winForm,
    [Parameter()]
    [Switch]$RestartReminder = [System.Convert]::ToBoolean($env:restartReminder)
)

begin {

    # You can replace the below line with $IconBase64 = "ReplaceThisWithYourBase64encodedimageEncasedInQuotes" and the script will decode the image and use it 
    # for the taskbar overlay icon and title bar icon.
    $IconBase64 = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAAAJFBMVEUARF0Apc0AmL8ApM0Aos0Aps7///8Am8ia1ug9rtLd8/jw+/2tMDHwAAAABXRSTlMBrBTIcce4nvwAAAIeSURBVHic7dvrcoMgEAXgiOAivv/7Fm+JBpCLwk7bsz86rcNkPw+Y0Gl5vd4lGtbLKSG7vmF18mwQnWpe3YcghP2Z1svU8OtbIOihm8op25M2gWBov9UqYJj/vSRzAGsEkhMglxngWINbdbxLAAAAAAAAAAAAAKAI8Oz2KRtApPWThEyAbT8NZwDZGpeav6sLIKXNMBwAtuGotTGTvTpMRms9qkxEBsDe/dz+A7B3rufeS/utrCKPkAywzfYmK8BeOHY+lBkzBImALfwDgA4XnNLphCTA4e43AKmL9vNMJD8pCQAna20nP5D+SfkQgJyp1qS9PYsEKQDnpVP627WYJCgBmGj+GRmUAFIraSXWBAwDcwJJk1AXMIzcgHgElQHxCGoDohHcBsybgIvPpei70S2A0csuaNkTBRBTbA7uAOb271E0+gWxOSgHfG87yD+wGsCz7fGONNf9iwGTb89DnlkwkUVQCPD2t1sXz9A6gMDT5YsgsggKARljI/vTMkDo7cU3B1USCL+oOwdVAMGF5RlcAxB+tBoBwq/JDlDcAPYEAGgDuPiNBwkgASSABJAAEkACSAAJIAEkgASQABL4JwlcA9w/9N4GTOZcl1OQMTgRoEannhv9O/+PCAAAAAAAAAAAAACAPwhgP+7HeOCR1jOfjBHI9dBrz9W/34/d9jyHLvvPweP2GdCx/3zyvLlAfZ8+l13LktJzAJ+nfgAP50EVLvPsRgAAAABJRU5ErkJggg=="
    
    # You can replace the below line with $LogoBase64 = "ReplaceThisWithYourBase64encodedimageEncasedInQuotes" and the script will decode the image and use it 
    # for the main large image / logo
    $LogoBase64 = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAAAJFBMVEUARF0Apc0AmL8ApM0Aos0Aps7///8Am8ia1ug9rtLd8/jw+/2tMDHwAAAABXRSTlMBrBTIcce4nvwAAAIeSURBVHic7dvrcoMgEAXgiOAivv/7Fm+JBpCLwk7bsz86rcNkPw+Y0Gl5vd4lGtbLKSG7vmF18mwQnWpe3YcghP2Z1svU8OtbIOihm8op25M2gWBov9UqYJj/vSRzAGsEkhMglxngWINbdbxLAAAAAAAAAAAAAKAI8Oz2KRtApPWThEyAbT8NZwDZGpeav6sLIKXNMBwAtuGotTGTvTpMRms9qkxEBsDe/dz+A7B3rufeS/utrCKPkAywzfYmK8BeOHY+lBkzBImALfwDgA4XnNLphCTA4e43AKmL9vNMJD8pCQAna20nP5D+SfkQgJyp1qS9PYsEKQDnpVP627WYJCgBmGj+GRmUAFIraSXWBAwDcwJJk1AXMIzcgHgElQHxCGoDohHcBsybgIvPpei70S2A0csuaNkTBRBTbA7uAOb271E0+gWxOSgHfG87yD+wGsCz7fGONNf9iwGTb89DnlkwkUVQCPD2t1sXz9A6gMDT5YsgsggKARljI/vTMkDo7cU3B1USCL+oOwdVAMGF5RlcAxB+tBoBwq/JDlDcAPYEAGgDuPiNBwkgASSABJAAEkACSAAJIAEkgASQABL4JwlcA9w/9N4GTOZcl1OQMTgRoEannhv9O/+PCAAAAAAAAAAAAACAPwhgP+7HeOCR1jOfjBHI9dBrz9W/34/d9jyHLvvPweP2GdCx/3zyvLlAfZ8+l13LktJzAJ+nfgAP50EVLvPsRgAAAABJRU5ErkJggg=="

    # If script form is used replace the parameters
    if ($env:applicationId -and $env:applicationId -notlike "null") { $ApplicationID = $env:applicationId }
    if ($env:logoPath -and $env:logoPath -notlike "null") { $LogoPath = $env:logoPath }
    if ($env:iconPath -and $env:iconPath -notlike "null") { $IconPath = $env:iconPath }
    if ($env:popupMessage -and $env:popupMessage -notlike "null") { $Text = $env:popupMessage }
    if ($env:rightButtonText -and $env:rightButtonText -notlike "null") { $ButtonRtext = $env:rightButtonText }
    if ($env:rightButtonAction -and $env:rightButtonAction -notlike "null") { $ButtonRaction = $env:rightButtonAction }
    if ($env:rightButtonCountdown -and $env:rightButtonCountdown -notlike "null") { $ButtonRcountdown = $env:rightButtonCountdown }
    if ($env:leftButtonText -and $env:leftButtonText -notlike "null") { $ButtonLText = $env:leftButtonText }
    if ($env:leftButtonAction -and $env:leftButtonAction -notlike "null") { $ButtonLaction = $env:leftButtonAction }
    if ($env:leftButtonCountdown -and $env:leftButtonCountdown -notlike "null") { $ButtonLcountdown = $env:leftButtonCountdown }
    if ($env:defaultButton -and $env:defaultButton -notlike "null") {
        if ($env:defaultButton -eq "Right Button") { $ButtonRdefault = $True }
        if ($env:defaultButton -eq "Left Button") { $ButtonLdefault = $True }
    }

    # Sets the parameters for a generic restart prompt
    if ($RestartReminder) {
        if (-not $ButtonLtext) { $ButtonLtext = "Restart Now" }
        if (-not $ButtonLaction) {
            if (([System.Environment]::OSVersion.Version).Major -ge 10) {
                $ButtonLaction = "shutdown.exe /r /soft /t 30"
            }
            else {
                $ButtonLaction = "shutdown.exe /r /t 30"
            } 
        }
        if (-not $ButtonRtext) { $ButtonRtext = "Ignore" }
        if (-not $ButtonRcountdown) { $ButtonRcountdown = 900 }
        if (-not $Text) { $Text = "Your IT Administrator is requesting that you restart your computer. Click 'Restart Now' after saving your work." }
    }

    # These Assemblies are needed to prepare the images for the form
    Write-Verbose "Adding required assemblies..."
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Check if the script was run as the default System User
    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    function Test-PSVersion {
        return ($PSVersionTable.PSVersion.Major)
    }

    function ConvertFrom-Base64 {
        param(
            $Base64,
            $Path
        )
        $bytes = [Convert]::FromBase64String($Base64)

        # This section of code will error out when ran multiple times in the same session. This is from wpf holding onto the file after closing. 
        # The file is unlocked when the powershell session is closed.
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        [IO.File]::WriteAllBytes($Path, $bytes)
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    }

    # There's a lot of ways to create icon files the below method creates a png and then creates an ico file in binary form by creating the header and adding the png's binary at the bottom.
    # Once this has been done we can simply write all the bytes to our new file.
    function ConvertFrom-Image {
        param(
            $ImagePath,
            $Path
        )

        # Grab an instance of the image and blank bitmap
        $image = [Drawing.Image]::FromFile($ImagePath)

        # Resize the image to 255px by 255px while maintaining quality.
        # If you want transparency you'll need an Alpha channel in the pixel format
        $bitmap = New-Object System.Drawing.Bitmap (64, 64, [system.drawing.imaging.PixelFormat]::Format32bppArgb)
        $bitmap.SetResolution(64, 64)

        # Create a graphics object which will be used to resize the image to 255px by 255px
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

        # Set some quality settings for the resize operation
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        # Draw the image onto the bitmap
        $graphics.DrawImage($Image, 0, 0, 64, 64)
        
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
            64, 64, # icon size
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
        # This section of code will error out when ran multiple times in the same session. This is from wpf holding onto the file after closing. 
        # The file is unlocked when the powershell session is closed.
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        if (Test-Path $Path -ErrorAction SilentlyContinue) { Remove-Item $Path -Force }
        [System.IO.File]::WriteAllBytes($Path, $iconData)

        if (Test-Path $png -ErrorAction SilentlyContinue) { Remove-Item $png -Force }
        $bitmap.Dispose()
        $image.Dispose()
        $graphics.Dispose()
        [System.GC]::Collect()

        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    }

    function Invoke-Download {
        param(
            [Parameter()]
            [String]$URL,
            [Parameter()]
            [String]$BaseName,
            [Parameter()]
            [Switch]$SkipSleep
        )
        Write-Host "URL Given, Downloading the file..."

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
        While ($i -lt 4) {
            if (-not ($SkipSleep)) {
                $SleepTime = Get-Random -Minimum 3 -Maximum 30
                Start-Sleep -Seconds $SleepTime
            }

            Write-Host "Download Attempt $i"

            try {
                $WebClient = New-Object System.Net.WebClient
                $Response = $WebClient.OpenRead($Url)
                $MimeType = $WebClient.ResponseHeaders["Content-Type"]
                $DesiredExtension = switch -regex ($MimeType) {
                    "image/jpeg|image/jpg" { "jpg" }
                    "image/png" { "png" }
                    "image/gif" { "gif" }
                    "image/bmp|image/x-windows-bmp|image/x-bmp" { "bmp" }
                    "image/x-icon" { "ico" }
                    default { 
                        Write-Error "The URL you provided does not provide a supported image type. Image Types Supported: jpg, jpeg, ico, bmp, png and gif. Image Type detected: $MimeType"
                        Exit 1 
                    }
                }
                $Path = "$BaseName.$DesiredExtension"
                $WebClient.DownloadFile($URL, $Path)
                $File = Test-Path -Path $Path -ErrorAction SilentlyContinue
                $Response.Close()
            }
            catch {
                if ($Response) { $Response.Close() }
                Write-Warning "An error has occured while downloading!"
                Write-Warning $_.Exception.Message
            }

            if ($File) {
                $i = 4
            }
            else {
                $i++
            }
        }

        if (-not (Test-Path $Path)) {
            Write-Error "Failed to download file!"
            Exit 1
        }

        $Path
    }

    function Build-WPFform {
        # This is xml I created using visual studio community edition https://visualstudio.microsoft.com/downloads/ I removed some of the lines in "Window" so PowerShell could load it.
        [XML]$form = @"
<Window
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
Width="350" WindowStartupLocation="CenterScreen" SizeToContent="Height" ResizeMode="CanMinimize" Topmost="True"
>
    <Window.TaskbarItemInfo>
        <TaskbarItemInfo/>
    </Window.TaskbarItemInfo>
    <Grid>
        <Grid x:Name="ImageGrid" Margin="25,25,25,0" Height="125" MinWidth="250" VerticalAlignment="Top">
        <Image x:Name="Logo" HorizontalAlignment="Center" />
        </Grid>
        <Grid x:Name="ContentGrid" Margin="25,188,25,25">
            <Grid.RowDefinitions>
                <RowDefinition MinHeight="65" />
                <RowDefinition Height="30" />
            </Grid.RowDefinitions>
            <ScrollViewer x:Name="ScrollBox" VerticalScrollBarVisibility="Auto" Grid.RowSpan="1" MaxHeight="100" >
                <TextBlock x:Name="TextBlock" TextWrapping="Wrap" FontFamily="Microsoft Sans Serif" FontSize="14" />
            </ScrollViewer>
            <Button x:Name="ButtonR" FontFamily="Lucida Sans Unicode" FontSize="12" Content="Accept" Margin="0,0,0,0" Height="30" Width="114" HorizontalAlignment="Right" VerticalAlignment="Bottom" Grid.RowSpan="2" Visibility="Hidden" />
            <Button x:Name="ButtonL" FontFamily="Lucida Sans Unicode" FontSize="12" Content="Close" Margin="0,0,0,0" Height="30" Width="114" HorizontalAlignment="Left" VerticalAlignment="Bottom" Grid.RowSpan="2" Visibility="Hidden" />
        </Grid>
    </Grid>
</Window>
"@

        $NR = (New-Object System.Xml.XmlNodeReader $form)
        # Informs powershell that this xml is actually Xaml (Presentation Framework is needed to load it)
        $Window = [Windows.Markup.XamlReader]::Load($NR)

        # Set's the details of the form (How many buttons? Is One Default? All the options set by parameters)
        if ($ApplicationID) {
            Write-Verbose "Setting window title to $ApplicationID"
            $Window.Title = $ApplicationID
        }

        if ($AllowResize) {
            Write-Verbose "Allowing ReSizing of window..."
            $Window.ResizeMode = "CanResize"
        }

        if ($LogoPath) {
            Write-Verbose "Adding Logo..."
            $Logo = $window.FindName("Logo")
            $Logo.Source = $LogoPath
        }

        if ($IconPath) {
            Write-Verbose "Overlaying tasbar icon and setting icon for window..."
            $Window.Icon = $IconPath
            $Window.TaskbarItemInfo.Overlay = $IconPath
        }

        if ($Text) {
            Write-Verbose "Adding Text Block..."
            $TextBlock = $window.FindName("TextBlock")
            $TextBlock.Text = $Text
        }

        if ($ButtonR -or $ButtonRtext) {
            Write-Verbose "Adding Right Button..."
            $RightButton = $window.FindName("ButtonR")

            if ($ButtonRtext) { 
                Write-Verbose "Setting Right Button Text..."
                $RightButton.Content = $ButtonRtext 
            }
            else {
                Write-Warning "It looks like you forgot to enter in button text using -ButtonRtext 'replaceMeWithText' "
            }

            # To set the timer we'll need to create a timer but on the $Script level 
            if ($ButtonRcountdown) {
                Write-Verbose "Adding a countdown..."
                $ButtonText = $RightButton.Content
                $Script:Timer = New-Object System.Windows.Forms.Timer
                $Timer.Interval = 1000

                Function Timer_Tick() {
                    # Add text with countdown value in the button
                    $RightButton.Content = "$ButtonText ($Script:CountDown)"
                    --$Script:CountDown
                    If ($Script:CountDown -lt 0) {
                        $Script:Timer.Stop()
                        # Once the timer is complete we'll send a click event
                        $RightButton.RaiseEvent((New-Object -TypeName System.Windows.RoutedEventArgs -ArgumentList $([System.Windows.Controls.Button]::ClickEvent)))
                        $Script:Timer.Dispose() 
                    }
                }
                $Script:CountDown = $ButtonRcountdown
                $Script:Timer.Add_Tick({ Timer_Tick })
                $Script:Timer.Start()	
            }

            if ($ButtonRdefault) { $RightButton.IsDefault = $True }

            $RightButton.Visibility = "Visible"

            $RightButton.add_click(
                {
                    # I figured the actual button text would be more informative when looking back
                    Write-Host "$($RightButton.Content) Button Clicked!"
                    if ($buttonRaction) { Start-Process cmd.exe -ArgumentList "/c $buttonRaction" -NoNewWindow }
                    $window.Close()
                }
            )
        }

        if ($ButtonL -or $ButtonLtext) {
            Write-Verbose "Adding Left Button..."

            $LeftButton = $window.FindName("ButtonL")

            if ($ButtonLtext) { 
                Write-Verbose "Adding Left Button Text..."
                $LeftButton.Content = $ButtonLtext 
            }
            else {
                Write-Warning "It looks like you forgot to enter in button text using -ButtonLtext 'replaceMeWithText' "
            }

            if ($ButtonLcountdown) {
                Write-Verbose "Adding Countdown..."
                $ButtonText = $LeftButton.Content
                $Script:Timer = New-Object System.Windows.Forms.Timer
                $Timer.Interval = 1000

                Function Timer_Tick() {
                    # Add text with countdown value in the button
                    $LeftButton.Content = "$ButtonText ($Script:CountDown)"
                    --$Script:CountDown
                    If ($Script:CountDown -lt 0) {
                        $Script:Timer.Stop()
                        $LeftButton.RaiseEvent((New-Object -TypeName System.Windows.RoutedEventArgs -ArgumentList $([System.Windows.Controls.Button]::ClickEvent)))
                        $Script:Timer.Dispose()
                    }
                }
                $Script:CountDown = $ButtonLcountdown
                $Script:Timer.Add_Tick({ Timer_Tick })
                $Script:Timer.Start()	
            }

            if ($ButtonLdefault) { $LeftButton.IsDefault = $True }
            $LeftButton.Visibility = "Visible"

            $LeftButton.add_click(
                {
                    Write-Host "$($LeftButton.Content) Button Clicked!"
                    if ($buttonLaction) { Start-Process cmd.exe -ArgumentList "/c $buttonLaction" -NoNewWindow }
                    $window.Close()
                }
            )
        }

        # Actually displays the form here
        $window.ShowDialog() | Out-Null
    }

    function Build-WinForm {
        # Legacy Windows Form UI. It doesn't scale but looks similar to the one I built with WPF
        Write-Verbose "Legacy System Detected switching to windows forms..."
        Write-Verbose "Building initial window..."
        $form = New-Object System.Windows.Forms.Form
        $form.Height = 360
        $form.Width = 350
        $form.AutoSize = $false
        $form.MaximizeBox = $False
        $form.StartPosition = "CenterScreen"
        $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
        if ($ApplicationID) { $form.Text = $ApplicationID }
        if (-not $AllowResize) { $form.FormBorderStyle = "FixedDialog" }

        Write-Verbose "Setting window icon to $IconPath"
        if ($IconPath) {
            $form.Icon = New-Object System.Drawing.Icon $IconPath
        }
        
        Write-Verbose "Building Logo..."
        $Logo = New-Object System.Windows.Forms.PictureBox
        $Logo.Location = New-Object System.Drawing.Point(40, 25)
        $Logo.Height = 125
        $Logo.Width = 250
        $Logo.BackColor = [System.Drawing.Color]::Transparent
        $Logo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
        $Logo.ImageLocation = $LogoPath
        $form.Controls.Add($Logo)

        Write-Verbose "Adding TextBox..."
        $TextBox = New-Object System.Windows.Forms.RichTextBox
        $TextBox.Height = 75
        $TextBox.Width = 275
        $TextBox.Text = $Text
        $TextBox.Font = "Microsoft Sans Serif"
        $TextBox.ShowSelectionMargin = $False
        $TextBox.Tabstop = $False
        $TextBox.ReadOnly = $True
        $TextBox.Location = New-Object System.Drawing.Point(30, 175)
        $form.Controls.Add($TextBox)

        Write-Verbose "Adding Left Button..."
        $LeftFormButton = New-Object System.Windows.Forms.Button
        $LeftFormButton.Location = New-Object System.Drawing.Point(30, 275)
        $LeftFormButton.Height = 25
        $LeftFormButton.Width = 114
        $LeftFormButton.Font = "Lucida Sans Unicode"
        if (-not $ButtonLtext) { $LeftFormButton.Text = "Close" }else { $LeftFormButton.Text = $ButtonLtext }
        $LeftFormButton.Add_Click(
            {
                Write-Host "$($LeftFormButton.Text) Button Clicked!"
                if ($buttonLaction) { Start-Process cmd.exe -ArgumentList "/c $buttonLaction" -NoNewWindow }
                $form.Close()
            }
        )
        if ($ButtonLcountdown) {
            $ButtonText = $LeftFormButton.Text
            $Script:Timer = New-Object System.Windows.Forms.Timer
            $Timer.Interval = 1000

            Function Timer_Tick() {
                # Add text with countdown value in the button
                $LeftFormButton.Text = "$ButtonText ($Script:CountDown)"
                --$Script:CountDown
                If ($Script:CountDown -lt 0) {
                    $Script:Timer.Stop(); 
                    $LeftFormButton.PerformClick();
                    $Script:Timer.Dispose(); 
                }
            }
            $Script:CountDown = $ButtonLcountdown
            $Script:Timer.Add_Tick({ Timer_Tick })
            $Script:Timer.Start()	
        }
        if ($ButtonL) { $form.Controls.Add($LeftFormButton) }

        Write-Verbose "Adding Right Button..."
        $RightFormButton = New-Object System.Windows.Forms.Button
        $RightFormButton.Location = New-Object System.Drawing.Point(190, 275)
        $RightFormButton.Height = 25
        $RightFormButton.Width = 114
        $RightFormButton.Font = "Lucida Sans Unicode"
        if (-not $ButtonRtext) { $RightFormButton.Text = "Accept" }else { $RightFormButton.Text = $ButtonRtext }
        $RightFormButton.Add_Click(
            {
                Write-Host "$($RightFormButton.Text) Button Clicked!"
                if ($buttonRaction) { Start-Process cmd.exe -ArgumentList "/c $buttonRaction" -NoNewWindow }
                $form.Close()
            }
        )
        if ($ButtonRcountdown) {
            $ButtonText = $RightFormButton.Text
            $Script:Timer = New-Object System.Windows.Forms.Timer
            $Timer.Interval = 1000

            Function Timer_Tick() {
                # Add text with countdown value in the button
                $RightFormButton.Text = "$ButtonText ($Script:CountDown)"
                --$Script:CountDown
                If ($Script:CountDown -lt 0) {
                    $Script:Timer.Stop(); 
                    $RightFormButton.PerformClick();
                    $Script:Timer.Dispose(); 
                }
            }
            $Script:CountDown = $ButtonRcountdown
            $Script:Timer.Add_Tick({ Timer_Tick })
            $Script:Timer.Start()	
        }
        if ($ButtonR) { $form.Controls.Add($RightFormButton) }

        $form.Add_Load(
            {
                $form.Activate()
            }
        )

        Write-Verbose "Displaying PopUp..."
        $form.ShowDialog() | Out-Null
        $form.Dispose()
    }

    # If it was we'll error out and enform the technician they should run it as the "Current Logged on User"
    if (Test-IsSystem) {
        Write-Error "This script does not work when ran as system. Use Run As: 'Current Logged on User'."
        exit 1
    }

    # Windows Presentation Framework cannot be imported by PowerShell 2.0.
    if ((Test-PSVersion) -lt 3) {
        Write-Warning "PowerShell 2 cannot import the presentation framework switching to winform..."
        $winForm = $True
    }

    # Inform the technician that having two simultaneous countdowns isn't really a good idea (it would technically work but doesn't really make sense)
    if ($ButtonLcountdown -and $ButtonRcountdown) {
        Write-Error "[Error] -ButtonLcountdown and -ButtonRcountdown cannot be used at the same time!"
        exit 1
    }

    # Informing the technician that this doesn't make sense but I will allow it.
    if ($ButtonRdefault -and $ButtonLdefault) {
        Write-Warning "Looks like you've made both buttons the default?"
    }

    # If the technician forgot to set a button we'll set one.
    if (-not $ButtonL -and ($ButtonLtext -or $ButtonLaction -or $ButtonLDefault -or $ButtonLcountdown)) { $ButtonL = $True }
    if (-not $ButtonR -and ($ButtonRtext -or $ButtonRaction -or $ButtonRDefault -or $ButtonRcountdown)) { $ButtonR = $True }
    
    # If no default button was selected I'll pick for you.
    if (-not $ButtonRDefault -and -not $ButtonLDefault) {
        if ($ButtonL -and $ButtonR) { $ButtonRDefault = $True }
        if ($ButtonL -and -not $ButtonR) { $ButtonLDefault = $True }
        if ($ButtonR -and -not $ButtonL) { $ButtonRDefault = $True }
    }

    # This is where Send-UserPrompt (and the default notification system) store's the icon's path
    $iconUri = Get-ItemProperty "HKLM:\SOFTWARE\Classes\AppUserModelId\$($ApplicationId -replace '\s+','.')" -ErrorAction SilentlyContinue | Select-Object IconUri -ExpandProperty IconUri -ErrorAction SilentlyContinue
    
    # The base64 we set by default. If someone manually entered in their own base64 we'll prefer it over the application ID.
    $defaultImg = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAAAJFBMVEUARF0Apc0AmL8ApM0Aos0Aps7///8Am8ia1ug9rtLd8/jw+/2tMDHwAAAABXRSTlMBrBTIcce4nvwAAAIeSURBVHic7dvrcoMgEAXgiOAivv/7Fm+JBpCLwk7bsz86rcNkPw+Y0Gl5vd4lGtbLKSG7vmF18mwQnWpe3YcghP2Z1svU8OtbIOihm8op25M2gWBov9UqYJj/vSRzAGsEkhMglxngWINbdbxLAAAAAAAAAAAAAKAI8Oz2KRtApPWThEyAbT8NZwDZGpeav6sLIKXNMBwAtuGotTGTvTpMRms9qkxEBsDe/dz+A7B3rufeS/utrCKPkAywzfYmK8BeOHY+lBkzBImALfwDgA4XnNLphCTA4e43AKmL9vNMJD8pCQAna20nP5D+SfkQgJyp1qS9PYsEKQDnpVP627WYJCgBmGj+GRmUAFIraSXWBAwDcwJJk1AXMIzcgHgElQHxCGoDohHcBsybgIvPpei70S2A0csuaNkTBRBTbA7uAOb271E0+gWxOSgHfG87yD+wGsCz7fGONNf9iwGTb89DnlkwkUVQCPD2t1sXz9A6gMDT5YsgsggKARljI/vTMkDo7cU3B1USCL+oOwdVAMGF5RlcAxB+tBoBwq/JDlDcAPYEAGgDuPiNBwkgASSABJAAEkACSAAJIAEkgASQABL4JwlcA9w/9N4GTOZcl1OQMTgRoEannhv9O/+PCAAAAAAAAAAAAACAPwhgP+7HeOCR1jOfjBHI9dBrz9W/34/d9jyHLvvPweP2GdCx/3zyvLlAfZ8+l13LktJzAJ+nfgAP50EVLvPsRgAAAABJRU5ErkJggg=="
    if ($iconUri) {
        Write-Host "Application ID with Icon found! Checking if the icon and logo were supplied elsewhere..."

        if (-not $IconPath -and $IconBase64 -eq $defaultImg) {
            Write-Host "The icon was not specified elsewhere in the script switching from the default icon to the Applications Notification Icon."
            $IconPath = $iconUri
        }
        else {
            Write-Warning "The icon was already specified either by script parameters or by replacing the default base64. Using that instead." 
        }

        if (-not $LogoPath -and $LogoBase64 -eq $defaultImg) {
            Write-Host "The logo/image was not specified elsewhere in the script switching from the default image to the Applications Notification Icon."
            $LogoPath = $iconUri
        }
        else {
            Write-Warning "The Logo/image was already specified either by script parameters or by replacing the default base64. Using that instead."
        }
    }

    # An actual path to an image is prefered over the base64 encoding
    if ($LogoBase64 -and -not $LogoPath) {
        $LogoPath = "$env:TEMP\ninjarmm-popup-logo.png"
        Write-Verbose "Converting Logo base64 to image and saving to $LogoPath"
        ConvertFrom-Base64 -Base64 $LogoBase64 -Path $LogoPath
    }

    # Windows Forms and Wpf will follow a url for the logo but not the taskbar icon. We'll download it and then set the path for the rest of the script here.
    if ($IconPath -match "^http(.?)://(.*)") {
        $IconPath = Invoke-Download -URL $IconPath -BaseName "$env:TEMP\ninjarmm-popup-icon"
    }

    # This will convert the base64 into an image and save it to the temp folder
    if ($IconBase64 -and -not $IconPath) {
        $IconPath = "$env:TEMP\ninjarmm-popup-icon.png"
        Write-Verbose "Converting Icon base64 to original image and saving to $IconPath..."
        ConvertFrom-Base64 -Base64 $IconBase64 -Path $IconPath
    }

    # An IconPath should now exist whether or not base64 was used or not. This will convert the image to a bitmap image and then into a usable icon
    if ($IconPath) {
        Write-Verbose "Converting image to icon and saving to $env:TEMP\ninjarmm-popup-icon.ico ..."
        ConvertFrom-Image -ImagePath $IconPath -Path "$env:TEMP\ninjarmm-popup-icon.ico"
        $IconPath = "$env:TEMP\ninjarmm-popup-icon.ico"
    }
}
process {
    # The -winForm parameter is both for testing purposes and for older os's
    if (-not $winForm) {

        # Time to start creating the form
        Add-Type -AssemblyName PresentationFramework

        # This section of code will error out when ran multiple times in the same session.
        # This is because you can only enable dpi awareness prior to creating gui objects (DPI awareness should be preserved from the previous running).
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        
        [System.Windows.Forms.Application]::EnableVisualStyles()
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($True)

        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
        
        Write-Verbose "WPF imported successfully using WPF to display PopUp."
        
        Build-WPFform
    }
    else {
        Build-WinForm
    }

    # To prevent the timer from sticking around after the script is done we'll stop it, dispose it and then set it as $null
    Write-Verbose "Cleaning up timer..."
    if ($ButtonRcountdown -or $ButtonLcountdown) {
        $Script:Timer.Stop(); 
        $Script:Timer.Dispose();
        $Script:Timer = $null
        $Script:CountDown = $null
    }
}
end {
    
    
    
}
