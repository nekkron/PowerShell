<#
.SYNOPSIS
	Delete obsolete/stale device objects from Microsoft Intune/Azure AD

.DESCRIPTION
	Based on input parameters ('management agent', 'compliance state' and 'management state', 'Days last synced') the script is used to perform "housekeeping" to keep your Microsoft Intune/Azure AD clean and tidy of obsolete/stale device objects.
	The script deletes device objects based on their device state, device compliance state, management channel and the number of days devices hasn't synced/connected to Microsoft Intune.

.AUTHORS 
	Name: Ronny de Jong
	Contact: ronny.de.jong@outlook.com
	Version: 1.0
	
	Contributers:
	Dave Falkus (Microsoft) – Thanks for the inspiration provided on GitHub https://github.com/microsoftgraph/powershell-intune-samples
	Dennis van den Akker (InSpark) – A highly valued colleague and a great PowerShell hero
	
.NOTES
	This posting is provided "AS IS" with no warranties, and confers no rights. Misuse can have great impact and lead to (unintential) removal of all device objects.

.LINK
	https://www.ronnydejong.com

.WARNING 
	Using incorrect parameters can result in deleting all device objects in your tenant! For safety reason I have commented the invoke & delete actions.
#>


#Provide input parameters
[CmdletBinding()]
param (
	[Parameter (Mandatory=$True)]
		[string]$DaysLastSyncDate,
	[Parameter (Mandatory=$False)]
		[ValidateSet('eas', 'mdm', 'easMdm', 'configurationManagerClientMdm', ignorecase=$True)]
		[string]$managementAgent,
	[Parameter (Mandatory=$False)]
		[ValidateSet('compliant', 'noncompliant', 'unknown', 'configManager', ignorecase=$True)]
		[string]$complianceState,
	[Parameter (Mandatory=$False)]
		[ValidateSet('managed', 'wipePending', 'retireIssued', 'retirePending', ignorecase=$True)]
		[string]$managementState
)

#Retrieve Microsoft Intune tenant information
$intuneAutomationCredential = Get-AutomationPSCredential -Name IntuneAutomation
$intuneAutomationAppId = Get-AutomationVariable -Name IntuneClientId
$tenant = Get-AutomationVariable -Name AzureADTenantId

#Import Azure AD PowerShell for Graph (GA)
$AadModule = Import-Module -Name AzureAD -ErrorAction Stop -PassThru

#Filter for the minimum number of days where the device hasn't checked in
$days = $DaysLastSyncDate
$daysago = "{0:s}" -f (get-date).AddDays(-$days) + "Z"
$CurrentTime = [System.DateTimeOffset]::Now

#Authenticate with the Graph API REST interface
$adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
$adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
$resourceAppIdURI = "https://graph.microsoft.com&quot;
$authority = "https://login.microsoftonline.com/$tenant&quot;

try {
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority 
    # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
	# Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($intuneAutomationCredential.Username, "OptionalDisplayableId")   
    $userCredentials = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserPasswordCredential -ArgumentList $intuneAutomationCredential.Username, $intuneAutomationCredential.Password
    $authResult = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContextIntegratedAuthExtensions]::AcquireTokenAsync($authContext, $resourceAppIdURI, $intuneAutomationAppId, $userCredentials);

    if ($authResult.Result.AccessToken) {
        $authHeader = @{
            'Content-Type'  = 'application/json'
            'Authorization' = "Bearer " + $authResult.Result.AccessToken
            'ExpiresOn'     = $authResult.Result.ExpiresOn
        }
    }
    elseif ($authResult.Exception) {
        throw "An error occured getting access token: $($authResult.Exception.InnerException)"
    }
}
catch { 
    throw $_.Exception.Message 
}		

$Filters = "";
# Days Last sync
if (![System.String]::IsNullOrEmpty($DaysLastSyncDate)) {
	if ($Filters.Length -gt 0) {
		$Filters = "$($Filters) and (lastSyncDateTime le '$($daysago)')";
	} else {
		$Filters = "lastSyncDateTime le $($daysago)";
	}
}
# Management agent
if (![System.String]::IsNullOrEmpty($managementAgent)) {
	if ($Filters.Length -gt 0) {
		$Filters = "$($Filters) and (managementAgent eq '$($managementAgent)')";
	} else {
		$Filters = "(managementAgent eq '$($managementAgent)')";
	}
}
# Compliance state
if (![System.String]::IsNullOrEmpty($complianceState)) {
	if ($Filters.Length -gt 0) {
		$Filters = "$($Filters) and (complianceState eq '$($complianceState)')";
	} else {
		$Filters = "(complianceState eq '$($complianceState)')";
	}
}
# Management state
if (![System.String]::IsNullOrEmpty($managementState)) {
	if ($Filters.Length -gt 0) {
		$Filters = "$($Filters) and (managementState eq '$($managementState)')";
	} else {
		$Filters = "(managementState eq '$($managementState)')";
	}
}

$Url = "https://graph.microsoft.com/beta/deviceManagement/managedDevices&quot;;
if ($Filters.Length -gt 0) {
	$Url += "?`$filter=$($Filters)";
}
#Write-Output $url
$Results = (Invoke-RestMethod -Headers $authHeader -Method Get -Uri $Url).value;

if ($Filters.Length -eq 0) {
	Write-Output "Found $($Results.Count) devices";
} else {
	Write-Output "Found $($Results.Count) devices with the following filters";
	"";
	Write-Output "  Days last synced: $($daysago)";
	Write-Output "  Management agent: $($managementAgent)";
	Write-Output "  Compliance state: $($complianceState)";
	Write-Output "  Management state: $($managementState)";
}

if ($Null -ne $Results) {
    ""
	Write-Output "Loading Azure AD module";
    #try {
		# Refresh the credentials as the password is probably empty https://github.com/Azure/azure-docs-powershell-azuread/issues/169
        $intuneAutomationCredential = Get-AutomationPSCredential -Name IntuneAutomation
		$AadModule = Import-Module -Name AzureAD
        Connect-AzureAd -Credential $intuneAutomationCredential
    #}
    #catch {
    #    throw 'AzureAD PowerShell module is not installed!'
    #}
	""
    Write-Output "Azure AD module loaded";

	#$Results | Select userPrincipalName,lastSyncDateTime,managementagent,managementstate,complianceState,deviceName,operatingSystem,deviceType,deviceEnrollmentType | Format-Table -AutoSize;
	#$Response = Read-Host -Prompt "Remove the device(s) (y/n)?";
    $Response = "y";
	if ($Null -ne $Response -and $Response.Length -gt 0 -and $Response -eq 'y') {
		$ResultsGrid = @();
		"";
		#Write-Output "Removing $($Results.Count) device objects from Microsoft Intune/Azure AD:";
		foreach ($Item in $Results) {
			$GVResults = New-Object -TypeName PSObject;
			#$GVResults | Add-Member NoteProperty "userPrincipalName" -Value $Item.userPrincipalName;
			$GVResults | Add-Member NoteProperty "lastSyncDateTime" -Value $Item.lastSyncDateTime;
			$GVResults | Add-Member NoteProperty "managementagent" -Value $Item.managementagent;
			$GVResults | Add-Member NoteProperty "managementstate" -Value $Item.managementstate;
			$GVResults | Add-Member NoteProperty "complianceState" -Value $Item.complianceState;
			#$GVResults | Add-Member NoteProperty "deviceName" -Value $Item.deviceName;
			#$GVResults | Add-Member NoteProperty "operatingSystem" -Value $Item.operatingSystem;
			$GVResults | Add-Member NoteProperty "deviceType" -Value $Item.deviceType;
			$GVResults | Add-Member NoteProperty "deviceEnrollmentType" -Value $Item.deviceEnrollmentType;
			#Write-Output "$($Item.userPrincipalName)";
			#Invoke-RestMethod -Headers $authHeader -Method Post -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($Item.id)/retire&quot; | Out-Null;
			#Invoke-RestMethod -Headers $authHeader -Method Delete -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$($Item.id)&#39;)" | Out-Null;
			try {
				if (($aadDevice = Get-AzureADDevice -SearchString $Item.deviceName | Where-Object -FilterScript {$_.DeviceId -eq $Item.azureADDeviceId}) -ne $null) {
					#Write-Output "Found AAD device '$($aadDevice.DisplayName)' with device id: $($aadDevice.DeviceId)";
					$GVResults | Add-Member NoteProperty "DisplayName" -Value $aadDevice.DisplayName;
					#Remove-AzureADDevice -ObjectId $aadDevice.ObjectId
					#Write-Output "=> deleted AAD device '$($aadDevice.DisplayName)'";
				} else {
					$GVResults | Add-Member NoteProperty "DisplayName" -Value "";
					Write-Output "No corresponding Azure AD Device object(s) found with DisplayName '$($Item.deviceName)' and DeviceId '$($Item.azureADDeviceId)'";
				}
			}
			catch { 
				throw $_.Exception.Message 
			}
			$ResultsGrid += $GVResults;
		}
		"";
        Write-Output "Removing $($Results.Count) device objects from Microsoft Intune/Azure AD:";
        $ResultsGrid | Format-Table;
	} else {
		Write-Output "Device(s) will not be removed";
	}
} else {
	Write-Output "No device(s) selected";
}
