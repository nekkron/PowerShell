
<#
.SYNOPSIS
    Clear's the DNS Cache the number of times you specify (defaults to 3).
.DESCRIPTION
    Clear's the DNS Cache the number of times you specify (defaults to 3).
.EXAMPLE
    (No Parameters)

    DNS Cache clearing attempt 1.
    DNS Cache cleared successfully!

    DNS Cache clearing attempt 2.
    DNS Cache cleared successfully!

    DNS Cache clearing attempt 3.
    DNS Cache cleared successfully!

PARAMETER: -Attempts "1"
    Replace 1 with the number of times you'd like to clear the dns cache.

.EXAMPLE
    -Attempts "1"
    
    DNS Cache clearing attempt 1.
    DNS Cache cleared successfully!

.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Renamed script and added Script Variable support
#>

[CmdletBinding()]
param (
    [Parameter()]
    [int]$Attempts = 3
)

begin {
    # If script form is used overwrite the parameter
    if ($env:numberOfTimesToClearCache -and $env:numberOfTimesToClearCache -notlike "null") { $Attempts = $env:numberOfTimesToClearCache }
}
process {

    try {
        # Settiing $i to 1 for readability purposes
        $i = 1

        # Adding 1 to attempts again for readability purposes
        if ($Attempts -ne 0) { $Attempts = $Attempts + 1 }

        # Loop through flush dns command
        For ($i; $i -lt $Attempts; $i++) {
            Start-Sleep -Seconds 1
            Write-Host "DNS Cache clearing attempt $i."
            if ((Get-Command Clear-DNSClientCache -ErrorAction SilentlyContinue)) {
                Clear-DnsClientCache -ErrorAction Stop
                Write-Host "DNS Cache cleared successfully!`n"
            }
            else {
                $dnsflush = ipconfig.exe /flushdns | Where-Object { $_ } | Out-String
                Write-Host "$dnsflush"

                if ($dnsflush -like "*Could not flush the DNS Resolver Cache*") {
                    throw "Could not flush the DNS Resolver Cache."
                }
            }
        }
    }
    catch {
        Write-Error "Failed to clear DNS Cache?"
        exit 1
    }

    # Write out the current dns cache
    Write-Host "### Current DNS Cache ###"
    
    # Get-DNSClientCache isn't a thing in PowerShell 2.0
    if ((Get-Command Get-DNSClientCache -ErrorAction SilentlyContinue)) {
        $currentcache = Get-DnsClientCache | Format-Table Entry, TimeToLive, Data | Out-String
    }
    else {
        $currentcache = ipconfig.exe /displaydns
        $currentcache = $currentcache -replace "Windows IP Configuration" | Where-Object { $_ } | Out-String
    }
    if (-not $currentcache -or $currentcache -like "*Could not display the DNS Resolver Cache.*") {
        Write-Warning "DNS Cache is currently empty."
    }
    else {
        Write-Host $currentcache
    }
}
end {
    
    
    
}
