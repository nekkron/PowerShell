WorkFlow Install-Patches {
    param ($computers)
    ForEach -parallel ($computer in $computers) {
        "Running patching job for $($computer.name)"
         Install-WindowsUpdate -ComputerName $computer.name -ForceReboot
    }
}

Import-Module windowsupdate -force
Install-Patches -computers (Get-ADComputer -filter {name -like "EUR-"})
Install-Patches -computers (Get-ADComputer -filter {name -like "PAC-"})
Install-Patches -computers (Get-ADComputer -filter {name -like "USA-"})