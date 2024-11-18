
<#
.SYNOPSIS
    Get the current status of the specified windows firewall profile. If none is specified it will check all of them.
.DESCRIPTION
    Get the current status of the specified windows firewall profile. If none is specified it will check all of them. 
    An exit code of 1 indicates that one or more profiles are currently disabled and 2 indicates some sort of error. 
    It will also output a status message.
.EXAMPLE
    (No Parameters)
    WARNING: The Private Firewall Profile is disabled!
    The Domain Firewall Profile is enabled!
    The Public Firewall Profile is enabled!

PARAMETER: -Name "Domain,Private"
    This will accept a string or array of strings representing the firewall profile names you want to check.
.EXAMPLE
    -Name "Domain,Private"
    WARNING: The Private Firewall Profile is disabled!
    The Domain Firewall Profile is enabled!
.EXAMPLE
    -Name "Domain"
    The Domain Firewall Profile is enabled!

.OUTPUTS
    None
.NOTES
    General Notes
    Minimum OS Architecture Supported: Windows 10, Windows Server 2012 R2
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Name = "All"
)
begin {
    function Get-FirewallStatus () {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline)]
            [ValidateSet("All", "Domain", "Public", "Private")]
            [String]$Name
        )
        process {
            if ($Name -contains "All") {
                $Result = Get-NetFirewallProfile -All | Select-Object "Name", "Enabled", "DefaultInboundAction"
                
            }
            else {
                $Result = Get-NetFirewallProfile -Name $Name | Select-Object "Name", "Enabled", "DefaultInboundAction"
            }

            $Result | ForEach-Object {
                if (($_.Enabled -like $False) -or ($_.DefaultInboundAction -like "Allow")) {
                    Write-Warning "The $($_ | Select-Object Name -ExpandProperty Name) Firewall Profile is disabled or not set to block inbound connections!"
                }
                else {
                    Write-Host "The $($_ | Select-Object Name -ExpandProperty Name) Firewall Profile is enabled and blocking inbound connections!"
                }
            }
            
            $Result
        }
    }

    $Names = New-Object -TypeName "System.Collections.ArrayList"
    if ($env:publicProfile -or $env:privateProfile -or $env:domainProfile -or $env:allProfiles) {
        if ($env:publicProfile -and $env:publicProfile -notlike "false") { $Names.add("Public") | Out-Null }
        if ($env:privateProfile -and $env:privateProfile -notlike "false") { $Names.Add("Private") | Out-Null }
        if ($env:domainProfile -and $env:DomainProfile -notlike "false") { $Names.Add("Domain") | Out-Null }
        if ($env:allProfiles -and $env:allProfiles -notlike "false") { $Names.Add("All") | Out-Null }
    }
    else {
        $Name -split "," | ForEach-Object { $Names.add($_.trim()) | Out-Null }
    }
    
    if ($Names -contains "All") {
        $Names = "All"
    }

    $ExitCode = 0
}
process {
    try {
        $Result = $Names | Get-FirewallStatus -ErrorAction Stop 
    }
    catch {
        Write-Error "[Error] Invalid Input! The only valid profile names are Domain, Private, Public and All."
        exit 2
    }

    $Result | ForEach-Object {
        if($_.Enabled -like $False -or $_.DefaultInboundAction -like "Allow"){
            $ExitCode = 1
        }
    }

    exit $ExitCode
}
end {
    
    
    
}
