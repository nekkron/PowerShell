#Requires -Version 5.1

<#
.SYNOPSIS
    Adds a shared printer from a server on the network as an "All User Printer".
.DESCRIPTION
    Adds a shared printer from a server on the network as an "All User Printer".

.EXAMPLE
    -Server 'PrintServer.example.com' -Name 'LobbyPrinter'

    WARNING: Waiting for service 'Print Spooler (Spooler)' to start...
    Restarted print Spooler service.
    Adding printer complete.
    WARNING: A restart is required for this script to take immediate effect.

PARAMETER: -Server 'PrintServer.example.com'
    Server name that is hosting the shared printer.
    Required.
PARAMETER: -Name 'LobbyPrinter'
    Name of the printer that is being shared.
    Required.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Server,
    [Parameter()]
    [String]$Name,
    [Parameter()]
    [Switch]$Remove = [System.Convert]::ToBoolean($env:removePrinter),
    [Parameter()]
    [Switch]$Restart = [System.Convert]::ToBoolean($env:forceRestart)
)

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($env:server -and $env:server -notlike "null") { $Server = $env:server }
    if ($env:printerName -and $env:printerName -notlike "null") { $Name = $env:printerName }

    Write-Host ""

    if (-not $Server) {
        Write-Host "[Error] Please specify a Server."
        exit 1
    }
    if (-not $Name) {
        Write-Host "[Error] Please specify a Printer Name."
        exit 1
    }

    $ProcessTimeOut = 10
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    try {
        $StartTime = Get-Date
        $AddOrRemove = if($Remove){"/gd"}else{"/ga"}

        Add-Printer -Connection "\\$Server\$Name"

        $Printer = Get-Printer -ComputerName $Server -Name $Name
        $PrinterDriver = Get-PrinterDriver -Name $Printer.DriverName -ComputerName $Server

        # rundll32.exe printui.dll, PrintUIEntry /ga /n\\$Server\$Name
        $Process = Start-Process -FilePath "C:\WINDOWS\system32\rundll32.exe" -ArgumentList @(
                "printui.dll,", "PrintUIEntry", $AddOrRemove, "/n`"\\$Server\$Name`""
        ) -PassThru -NoNewWindow

        # Wait for process to exit
        while (-not $Process.HasExited) {
            if ($StartTime.AddMinutes($ProcessTimeOut) -lt $(Get-Date)) {
                Write-Error -Message "[Error] rundll32.exe printui.dll took longer than $ProcessTimeOut minutes to complete." -Category LimitsExceeded -Exception (New-Object System.TimeoutException)
                exit 1
                break
            }
            Start-Sleep -Milliseconds 100
        }

        Add-PrinterDriver -Name $PrinterDriver.Name

        Restart-Service -Name Spooler

        if ($(Get-Service -Name Spooler).Status -like "Running") {
            Write-Host "Restarted print Spooler service."
            Write-Host "Adding printer complete."
        }
        else {
            Write-Host "[Error] Failed to restart Spooler service."
            exit 1
        }

        if($Restart){
            Write-Warning "A restart was requested scheduling restart for 60 seconds from now."
            Start-Process shutdown.exe -ArgumentList "/r /t 60" -Wait -NoNewWindow
        }else{
            Write-Warning "A restart may be required for this script to take immediate effect."
        }
    }
    catch {
        Write-Error $_
        Write-Host "[Error] Failed to add network printer."
        exit 1
    }
    exit 0
}
end {
    
    
    
}
