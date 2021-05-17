<# 
.SYNOPSIS 

    This scripts gatehr the delegates and forwarding rules for all Exchange user mailboxes.

    Version 1.0, 20182019-04-26

    Author: Thomas Stensitzki 

    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE  
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

    Please send ideas, comments and suggestions to support@granikos.eu

    .LINK 
    http://scripts.granikos.eu

    .DESCRIPTION 

    This script connects either to Exchange Online or to a dedicated on-premises Exchange Server to
    export configures mailbox delegates and SMTP forwarding configurations. The SMTP forwarding 
    configurations are gathered from inbox rules and from mailbox forwarding settings.

    The gathered information is exported into three different CSV files for further analysis.

    .NOTES 
    
    Requirements 
    - Exchange Server 2016 or newer
    - Crednetials to logon to Exchange Online and Office 365 when querying EXO mailboxes
    - Utilizes GlobalFunctions PowerShell Module --> http://bit.ly/GlobalFunctions
    
    Revision History 
    -------------------------------------------------------------------------------- 
    1.0 Initial community release 

    The script is based on the O365-InvestigationTooling script DumpDelegatesandForwardingRules.ps1 by Brandon Koeller
    Find more Office 365 investigation tooling scripts at: https://github.com/OfficeDev/O365-InvestigationTooling 

    .PARAMETER ExchangeOnline
    Connect to Exchange Online instead of an on-premises Exchange organization

    .PARAMETER UseStoredCredentials
    Use encrypted credentials stored in a file. (Not implemented yet)

    .PARAMETER ExchangeHost
    Host name of the on-premises Exchange Server to connect to

    .PARAMETER CsvDelimiter
    Preferred delimiter character for the exported CSV file

    .EXAMPLE 
    Connect to the on-premises Exchange Server mx01.varunagroup.de and export delegation and SMTP forwarding information
    
    .\Get-DelegatesAndForwardingRules.ps1 -ExchangeHost mx01.varunagroup.de

    .EXAMPLE 
    Connect to the on-premises Exchange Server mx01.varunagroup.de, export delegation and SMTP forwarding information and get verbose information on the objects worked on
    
    .\Get-DelegatesAndForwardingRules.ps1 -ExchangeHost mx01.varunagroup.de -Verbose 

    .EXAMPLE 
    Connect to Exchange Online and export delegation and SMTP forwarding information
    
    .\Get-DelegatesAndForwardingRules.ps1 -ExchangeOnline
#> 
[cmdletbinding(SupportsShouldProcess)]
Param(
  [switch]$ExchangeOnline,
  [switch]$UseStoredCredentials,
  [string]$ExchangeHost = 'ex01.mcsmemail.de',
  [char]$CsvDelimiter = ';'
)

# Some base variables
$ScriptDir = Split-Path -Path $script:MyInvocation.MyCommand.Path
$ScriptName = $MyInvocation.MyCommand.Name

$ForwardingRulesFileName = "MailForwardingRulesToExternalDomains-$(Get-Date -UFormat %Y-%m-%d).csv"
$DelegatePermissionsFileName = "MailboxDelegatePermissions-$(Get-Date -UFormat %Y-%m-%d).csv"
$SmtpForwardingFileName = "MailboxSmtpforwarding-$(Get-Date -UFormat %Y-%m-%d).csv"

function Import-RequiredModules {

  # Import central logging functions 
  if($null -ne (Get-Module -Name GlobalFunctions -ListAvailable).Version) {
    Import-Module -Name GlobalFunctions
  }
  else {
    Write-Warning -Message 'Unable to load GlobalFunctions PowerShell module.'
    Write-Warning -Message 'Please check http://bit.ly/GlobalFunctions for further instructions'
    exit
  }

  if($ExchangeOnline) {
  # Import required PowerShell modules for Office 365
    if($null -ne (Get-Module -Name MSOnline -ListAvailable).Version) {
      Import-Module -Name MSOnline
    }
    else {
      Write-Warning -Message 'Unable to load MSOnline PowerShell module.'
      exit
    }
  }
}

function Get-UserDelegates {

  $UserInboxRules = @()
  $UserDelegates = @()

  $Logger.Write(('Checking inbox rules and delegates permissions for {0} user objects' -f ($AllUsers | Measure-Object).Count))

  foreach ($User in $AllUsers) {
    # Check inbox rule for alle users

    if(($User.UserPrincipalName -ne '')) { 
    
      Write-Verbose -Message ('Checking inbox rules and delegates for user: ({0}) [{1}]' -f $User.UserPrincipalName, $User.DisplayName)

      if($null -ne (Get-Mailbox -Identity $User.UserPrincipalName -ErrorAction SilentlyContinue)) {
    
        $UserInboxRules += (Get-InboxRule -Mailbox $User.UserPrincipalname -ErrorAction SilentlyContinue | Select-Object -Property Name, Description, Enabled, Priority, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage | Where-Object {($null -ne $_.ForwardTo) -or ($null -ne $_.ForwardAsAttachmentTo) -or ($null -ne $_.RedirectsTo)})

        $UserDelegates += Get-MailboxPermission -Identity $User.UserPrincipalName | Where-Object {($_.IsInherited -ne 'True') -and ($_.User -notlike '*SELF*')}

      }
      else {
        # Ooops, not mailbox found
        $logger.Write(('No mailbox found for user {0}' -f $User.UserPrincipalName))
      }
    }
    else {
      # Ooops, no UPN
      $Message = ('Object [{0}] does is lacking a UPN. What is going on in your AD' -f $User.DisplayName)
      $Logger.Write($Message)    
      Write-Verbose -Message $Message
    }
  }

  $UserInboxRules | Export-Csv -Path (Join-Path -Path $ScriptDir -ChildPath $ForwardingRulesFileName) -Encoding UTF8 -Delimiter $CsvDelimiter

  $UserDelegates | Export-Csv -Path (Join-Path -Path $ScriptDir -ChildPath $DelegatePermissionsFileName) -Encoding UTF8 -Delimiter $CsvDelimiter
}

function Get-SmtpForwarding {

  $SmtpForwarding = $null
  
  $SmtpForwarding = Get-Mailbox -ResultSize Unlimited | Select-Object -Property DisplayName,ForwardingAddress,ForwardingSMTPAddress,DeliverToMailboxandForward | Where-Object {$null -ne $_.ForwardingSMTPAddress} -ErrorAction SilentlyContinue

  if($null -ne $SmtpForwarding) {
    $Message = ('{0} mailboxes with ForwardingSMTPAddress found' -f ($SmtpForwarding | Measure-Object).Count)
    $Logger.Write($Message)    
    Write-Verbose -Message $Message

    $SmtpForwarding | Export-Csv -Path (Join-Path -Path $ScriptDir -ChildPath $SmtpForwardingFileName) -Encoding UTF8 -Delimiter $CsvDelimiter

  }
  else {
    $Message = 'No mailboxes with ForwardingSMTPAddress found'
    $Logger.Write($Message)    
    Write-Verbose -Message $Message
  }  
}

# MAIN ##############################################

if($ExchangeOnline) {
  Write-Verbose -Message 'Checking delegate information and forwarding rules from Exchange Online'
}
else {
  Write-Verbose -Message 'Checking delegate information and forwarding rules from Exchange On-Premises'
}

Import-RequiredModules

# Create a new logger and purge existing logs
$logger = New-Logger -ScriptRoot $ScriptDir -ScriptName $ScriptName -LogFileRetention 14
$logger.Purge() # Purge files based on file retention setting
$logger.Write('Script started')

$ExSession = $null

if($ExchangeOnline) {
  # Fetch user credentials and log on to Exchange Online

  $OnlineCredentials = $null

  if($UseStoredCredentials) {
    # fetch user credentials from encrypted file for automation
    # Open issue #1
    Write-Warning -Message 'The UseStoredCredentials parameter is not supported yet.'
  }
  else {
    $OnlineCredentials = Get-Credential -Message 'Enter user credentials for '

    # Connect to MSOL
    Connect-MsolService -Credential $OnlineCredentials

    # Connect to Exchange Online
    $logger.Write('Connecting to Exchange Online')

    $ExSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri 'https://outlook.office365.com/powershell-liveid/' -Credential $OnlineCredentials -Authentication Basic -AllowRedirection -ErrorAction SilentlyContinue

    Import-PSSession -Session $ExSession

    # Update file names for EXO
    $ForwardingRulesFileName = ('EXO-{0}' -f $ForwardingRulesFileName)
    $DelegatePermissionsFileName = ('EXO-{0}' -f $DelegatePermissionsFileName)
    $SmtpForwardingFileName = ('EXO-{0}' -f $SmtpForwardingFileName)

    # Fetch all internal enabled users from Azure Active Directory 
    $AllUsers = @()
    $AllUsers = Get-MsolUser -All -EnabledFilter EnabledOnly | Select-Object -Property ObjectID, UserPrincipalName, FirstName, LastName, StrongAuthenticationRequirements, StsRefreshTokensValidFrom, StrongPasswordRequired, LastPasswordChangeTimestamp, DisplayName | Where-Object {($_.UserPrincipalName -notlike '*#EXT#*')} | Sort-Object -Property DisplayName
    
    $AllUsersCount = ($AllUsers | Measure-Object).Count

    $logger.Write(('{0} user objects fetched from Azure AD' -f $AllUsersCount))

    Get-UserDelegates

    Get-SmtpForwarding

  }

}
else {
  # Connect to Exchange On-Premises

  # Build connection Uri
  $ConnectionUri = ('http://{0}/PowerShell/?serializationLevel=Full' -f ($ExchangeHost))

  $logger.Write(('Connecting to Exchange On-Premises: {0}' -f $ConnectionUri))

  # Connect to Exchange with some session options
  $SessionOption = New-PSSessionOption -SkipRevocationCheck -SkipCNCheck
  $ExSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri ('http://{0}/PowerShell/?serializationLevel=Full' -f ($ExchangeHost)) -Authentication Kerberos -SessionOption $SessionOption

  # Import connected PS Session
  Import-PSSession -Session $ExSession

  # Set focus to entire forest
  Set-ADServerSettings -ViewEntireForest $true

  # Fetch all mailbox user objects
  $AllUsers = Get-Mailbox -ResultSize Unlimited | Sort-Object -Property DisplayName

  $AllUsersCount = ($AllUsers | Measure-Object).Count
  $logger.Write(('{0} mailbox user objects fetched from AD' -f $AllUsersCount))

  Get-UserDelegates

  Get-SmtpForwarding

}

if($null -ne $ExSession) {Remove-PSSession $ExSession}

$logger.Write('Script finished')