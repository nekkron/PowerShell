 $Shared  = import-csv c:/temp/shared.csv
    
 foreach($Data in $Shared){
# If mailbox doesn't exist, create mailbox
    if((Get-Mailbox $data.Name -ErrorAction 'SilentlyContinue') -eq $null){
         New-Mailbox -Name $data.Name -DisplayName $data.DisplayName -Shared
     }
# Add Access Rights for each created mailbox
     Add-MailboxPermission -Identity $data.Name -User $data.User1 -AccessRights $data.AccessRights
     Add-MailboxPermission -Identity $data.Name -User $data.User2 -AccessRights $data.AccessRights
 }
