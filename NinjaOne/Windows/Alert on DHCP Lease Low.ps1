#Requires -Version 5.1

<#
.SYNOPSIS
    Checks the DHCP scopes for the number of leases used and alerts if the threshold is exceeded.
.DESCRIPTION
    Checks the DHCP scopes for the number of leases used and alerts if the threshold is exceeded.
    This script requires the DhcpServer module to be installed with the DHCP server feature installed.
    The script will output the number of leases used, free, and total for each scope.
    If the LeaseThreshold parameter is set, the script will alert if the number of free leases is less than the threshold.
    If the ExcludeScope parameter is set, the script will exclude the specified scope from the output.
    If the IncludeScope parameter is set, the script will only include the specified scope in the output.

.PARAMETER LeaseThreshold
    The number of free leases that will trigger an alert. If the number of free leases is less than the threshold, an alert will be triggered.
.PARAMETER ExcludeScope
    The name of the scope to exclude from the output.
.PARAMETER IncludeScope
    The name of the scope to include in the output.

.EXAMPLE
    (No Parameters)
    ## EXAMPLE OUTPUT WITHOUT PARAMS ##
    [Info] Scope: Test1 Leases Used(In Use/Total): 250/252
    [Info] Scope: Test2 Leases Used(In Use/Total): 220/252
    [Info] Scope: Test6 Leases Used(In Use/Total): 4954378/18446744073709551615

.EXAMPLE
    PARAMETER: -LeaseThreshold 10
    ## EXAMPLE OUTPUT WITH LEASETHRESHOLD ##
    [Alert] Scope: Test1 Leases Used(In Use/Free/Total): 220/2/252
    [Info] Scope: Test2 Leases Used(In Use/Free/Total): 150/102/252
    [Info] Scope: Test6 Leases Used(In Use/Free/Total): 0/18446744073709551615/18446744073709551615

.EXAMPLE
    PARAMETER: -ExcludeScope "Test1"
    ## EXAMPLE OUTPUT WITH EXCLUDESCOPE ##
    [Info] Scope: Test2 Leases Used(In Use/Free/Total): 220/2/252
    [Info] Scope: Test6 Leases Used(In Use/Free/Total): 0/18446744073709551615/18446744073709551615

.EXAMPLE
    PARAMETER: -IncludeScope "Test2"
    ## EXAMPLE OUTPUT WITH INCLUDESCOPE ##
    [Info] Scope: Test2 Leases Used(In Use/Free/Total): 220/2/252
.NOTES
    Minimum OS: Windows Server 2016
    Requires the DhcpServer module to be installed with the DHCP server feature installed.
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    $LeaseThreshold,
    [string[]]$ExcludeScope,
    [string[]]$IncludeScope
)

begin {
    function Test-IsElevated {
        # check if running under a Pester test case
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    try {
        if ($env:leaseThreshold -and $env:leaseThreshold -notlike "null") {
            [int]$LeaseThreshold = $env:leaseThreshold
        }
    }
    catch {
        Write-Host "[Error] LeaseThreshold must be a number"
        exit 2
    }
    
    if ($env:excludeScope -and $env:excludeScope -notlike "null") {
        $ExcludeScope = $env:excludeScope
    }
    if ($env:includeScope -and $env:includeScope -notlike "null") {
        $IncludeScope = $env:includeScope
    }

    # Split the ExcludeScope and IncludeScope parameters into an array
    if (-not [String]::IsNullOrWhiteSpace($ExcludeScope) -and $ExcludeScope -like '*,*') {
        $ExcludeScope = $ExcludeScope -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique
    }
    if (-not [String]::IsNullOrWhiteSpace($IncludeScope) -and $IncludeScope -like '*,*') {
        $IncludeScope = $IncludeScope -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique
    }

    # Check if $ExcludeScope and $IncludeScope contain similar items
    if (-not [String]::IsNullOrWhiteSpace($ExcludeScope) -and -not [String]::IsNullOrWhiteSpace($IncludeScope)) {
        $SimilarItems = $ExcludeScope | Where-Object { $IncludeScope -contains $_ }
        if ($SimilarItems) {
            Write-Host "[Error] The following scopes are in both ExcludeScope and IncludeScope: $($SimilarItems -join ', ')"
            exit 2
        }
    }

    $ShouldAlert = $false
}
process {
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges."
        exit 2
    }

    # Check if the DhcpServer module is installed
    if (-not (Get-Module -ListAvailable -Name DhcpServer -ErrorAction SilentlyContinue)) {
        Write-Host "[Error] The DhcpServer module is not installed. Please install the DHCP server feature and the DhcpServer module."
        exit 2
    }

    # Get all DHCP scopes
    $AllScopes = $(
        Get-DhcpServerv4Scope | Select-Object -ExpandProperty Name
        Get-DhcpServerv6Scope | Select-Object -ExpandProperty Name
    )

    # Output an error if the ExcludeScope or IncludeScope parameters contain invalid scope names
    $(
        if ($IncludeScope) { $IncludeScope }
        if ($ExcludeScope) { $ExcludeScope }
    ) | ForEach-Object {
        if ($_ -notin $AllScopes) {
            Write-Host "[Error] Scope: $_ does not exist in the DHCP server. Please check the scope name and try again."
        }
    }

    # IPv4
    # Get all DHCP scopes
    $v4scopes = Get-DhcpServerv4Scope | Where-Object { $_.State }

    # Iterate through each scope
    foreach ($scope in $v4scopes) {
        # Get statistics for the scope
        $Stats = Get-DhcpServerv4ScopeStatistics -ScopeId $scope.ScopeId

        # Get the name of the scope
        $Name = (Get-DhcpServerv4Scope -ScopeId $scope.ScopeId).Name

        # Check if the scope should be excluded
        if (-not [String]::IsNullOrWhiteSpace($ExcludeScope) -and $Name -in $ExcludeScope) {
            continue
        }

        # Check if the scope should be included
        if (-not [String]::IsNullOrWhiteSpace($IncludeScope) -and $Name -notin $IncludeScope) {
            continue
        }

        # Check if the number of free leases is less than the threshold
        if ($Stats.Free -lt $LeaseThreshold ) {
            if ($ShouldAlert -eq $false) {
                # Output once if this is the first scope to trigger an alert
                Write-Host "[Alert] Available DHCP Leases Low. You may want to make modifications to one of the below scopes."
            }
            Write-Host "[Alert] Scope: $Name Leases Used(In Use/Free/Total): $($Stats.InUse)/$($Stats.Free)/$($Stats.InUse+$Stats.Free)"
            $ShouldAlert = $true
        }
        else {
            Write-Host "[Info] Scope: $Name Leases Used(In Use/Free/Total): $($Stats.InUse)/$($Stats.Free)/$($Stats.InUse+$Stats.Free)"
        }
    }

    # IPv6
    # Get all DHCP scopes
    $v6Scopes = Get-DhcpServerv6Scope | Where-Object { $_.State }

    # Iterate through each scope
    foreach ($scope in $v6Scopes) {
        # Get statistics for the scope
        $Stats = Get-DhcpServerv6ScopeStatistics -Prefix $scope.Prefix

        # Get the name of the scope
        $Name = (Get-DhcpServerv6Scope -Prefix $scope.Prefix).Name

        # Check if the scope should be excluded
        if (-not [String]::IsNullOrWhiteSpace($ExcludeScope) -and $Name -in $ExcludeScope) {
            continue
        }

        # Check if the scope should be included
        if (-not [String]::IsNullOrWhiteSpace($IncludeScope) -and $Name -notin $IncludeScope) {
            continue
        }

        # Check if the number of free leases is less than the threshold
        if ($Stats.Free -lt $LeaseThreshold ) {
            if ($ShouldAlert -eq $false) {
                # Output once if this is the first scope to trigger an alert
                Write-Host "[Alert] Available DHCP Leases Low. You may want to make modifications to one of the below scopes."
            }
            Write-Host "[Alert] Scope: $Name Leases Used(In Use/Free/Total): $($Stats.InUse)/$($Stats.Free)/$($Stats.InUse+$Stats.Free)"
            $ShouldAlert = $true
        }
        else {
            Write-Host "[Info] Scope: $Name Leases Used(In Use/Free/Total): $($Stats.InUse)/$($Stats.Free)/$($Stats.InUse+$Stats.Free)"
        }
    }

    exit 0

}
end {
    
    
    
}
