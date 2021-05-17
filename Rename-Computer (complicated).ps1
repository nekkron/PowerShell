Write-Host "Enter new computer name. Current is $env:COMPUTERNAME"
$NewCompName = Read-Host

$renamecomputer = $true
if ($NewCompName -eq "" -or $NewCompName -eq $env:COMPUTERNAME) {$NewCompName = $env:COMPUTERNAME; $renamecomputer = $false}

Write-Host "Please enter your desired location [1-4] [Default 1]:
1. USA
2. EUR
3. PAC
4. HQ"
$ou = Read-Host

$validou = $false
if ($ou -eq "" -or $ou -eq "1") {$ou = "OU=Computers,DC=USO,DC=org"; $validou =$true}
if ($ou -eq "2") {$ou = "OU=Computers,DC=USO,DC=org"; $validou =$true}
if ($ou -eq "3") {$ou = "OU=Computers,DC=USO,DC=org"; $validou =$true}
if ($ou -eq "4") {$ou = "OU=Computers,DC=USO,DC=org"; $validou =$true}

if($validou -eq $false) {Write-Host "Invalid input. Defaulting to 1"; $ou = "OU=Computers,DC=USO,DC=org"}

$creds = New-Object System.Mangement.Automation.PSCredential("example\administrator",(ConvertTo-SecureString "Password" -AsPlainText -Force))

Wire-Host "Adding $NewCompName to the domain."

Add-Computer -WorkgroupName 