Start-Transcript $env:ProgramData\Create-Shortcut.log                                  # Create local log file

# Variables
$IconLocationLocal = "$env:Windir\icon.ico"                                            # Local path to icon
$IconLocationRemote = "url to .ico"                                                    # Remote path to icon
$HelpShortcut = "$env:Public\Desktop\Shortcut.lnk"                                     # Shortcut location and name
$ShortcutDescription = "Click here to open the application"                            # Hover over description text
$ShortcutFile = "URL shortcut or application"                                          # Program to execute
$ShortcutHotkey = "CTRL+SHIFT+H"                                                       # Keyboard shortcut
$ShortcutWindowStyle = 1                                                               # Window size [1=Normal] [3=Maximized] [7=Minimized]
$UserDir = Get-ChildItem "C:\Users" -Directory

# Creating the shortcut
Write-Host "Downloading the icon"
    Invoke-WebRequest -Uri $IconLocationRemote -OutFile $IconLocationLocal
Write-Host "Creating USO Help shortcut"
    $WScriptShell = New-Object -ComObject WScript.Shell         # Call Wscript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($HelpShortcut)     # Create shortcut
    $Shortcut.TargetPath = $ShortcutFile                        # Add target path
    $Shortcut.IconLocation =  $IconLocationLocal                # Select icon
    $Shortcut.WindowStyle = $ShortcutWindowStyle                # Minimized windows
    $Shortcut.Hotkey = $ShortcutHotkey                          # Keyboard shortcut
    $Shortcut.Description = $ShortcutDescription                # Hover over description
    $Shortcut.Save()                                            # Save shortcut

Write-Host "Copying newly created desktop shortcut to start menu"
    Copy-Item $HelpShortcut "$env:ProgramData\Microsoft\Windows\Start Menu\Programs" -Force
Stop-Transcript
