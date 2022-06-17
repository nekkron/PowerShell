# https://docs.microsoft.com/en-us/powershell/module/exchange/set-mailbox?view=exchange-ps#example-7
$Alias  = import-csv c:/usr/alias.csv

foreach($Alias in $Alias){
    if((Get-Mailbox $Alias.Name -ErrorAction 'SilentlyContinue') -eq $null){
        Write-Host -BackgroundColor Red -ForegroundColor White -Object "Mailbox does not exist! Create mailbox before adding aliases!"
    }
    Set-Mailbox $Alias.Name -EmailAddresses @{Add=$Alias.Alias}
}
