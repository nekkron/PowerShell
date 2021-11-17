# Import Scheduled Task from .xml
#Register-ScheduledTask -Xml (Get-Content “\\Srv1\public\NewPsTask.xml” | out-string) -TaskName "NewPsTask"

# Create Scheduled Task
$Trigger = New-ScheduledTaskTrigger -At 10:00am -Daily
$User = "NT AUTHORITY\SYSTEM"
$Action = New-ScheduledTaskAction -Execute powershell.exe -Argument "Restart-Service -Name 'BMC Client Management Agent'" -WorkingDirectory C:\Windows\SysWOW64\WindowsPowerShell\v1.0\
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 10 -RestartInterval (New-TimeSpan -Minutes 60) -RunOnlyIfNetworkAvailable -StartWhenAvailable -WakeToRun
$Description = "This scheduled task automatically resets the BMC Client Management Agent daily to ensure proper communication with the remote server"

Register-ScheduledTask -TaskName "BCM Agent - Reset (Daily)" -Trigger $Trigger -User $User -Action $Action -Settings $Settings -Description $Description -RunLevel Highest -Force
