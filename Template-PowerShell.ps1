<#
.SYNOPSIS
    Script to write specified text to a file.

.DESCRIPTION
    This script writes a given text to a specified file, creating the directory if it doesn't exist.

.PARAMETER TextToWriteToFile
    The text to write to the file.

.PARAMETER FilePath
    The file path to write the text to.

.EXAMPLE
    .\Script.ps1 -TextToWriteToFile "Sample Text" -FilePath "C:\Temp\Test.txt"

.NOTES
    Ensure that you have the necessary permissions to write to the specified file path.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = 'The text to write to the file.')]
    [string] $TextToWriteToFile = 'Hello, World!',

    [Parameter(Mandatory = $false, HelpMessage = 'The file path to write the text to.')]
    [string] $FilePath = "$PSScriptRoot\Test.txt"
)

begin {
    # Start the log file as early as possible.
    $logFilePath = "$PSCommandPath.LastRun.csv"
    Add-Content -Path $logFilePath -Value "TimeStamp;ErrorType;ErrorMessage"

    function Write-Log {
        param (
            [string]$ErrorType,
            [string]$ErrorMessage
        )        $timeStamp = (Get-Date).ToString('u')
        $logEntry = "$timeStamp;$ErrorType;$ErrorMessage"
        Add-Content -Path $logFilePath -Value $logEntry
    }

    function Log-Information {
        param (
            [string]$Message
        )
        Write-Log -ErrorType "Information" -ErrorMessage $Message
    }

    function Log-Warning {
        param (
            [string]$Message
        )
        Write-Log -ErrorType "Warning" -ErrorMessage $Message
    }

    function Log-Error {
        param (
            [string]$Message
        )
        Write-Log -ErrorType "Error" -ErrorMessage $Message
    }

    function Ensure-DirectoryExists {
        param (
            [string] $directoryPath
        )
        if (-not (Test-Path -Path $directoryPath -PathType Container)) {
            Log-Information -Message "Creating directory '$directoryPath'."
            New-Item -Path $directoryPath -ItemType Directory -Force > $null
        }
    }

    function Write-TextToFile {
        param (
            [string] $text,
            [string] $filePath
        )
        if (Test-Path -Path $filePath -PathType Leaf) {
            Log-Warning -Message "File '$filePath' already exists. Overwriting it."
        }
        Set-Content -Path $filePath -Value $text -Force
    }

    $InformationPreference = 'Continue'

    # Display the time that this script started running.
    [DateTime] $startTime = Get-Date
    Log-Information -Message "Starting script at '$($startTime.ToString('u'))'."
}

process {
    try {
        Ensure-DirectoryExists -directoryPath (Split-Path -Path $FilePath -Parent)
        Log-Information -Message "Writing the text '$TextToWriteToFile' to the file '$FilePath'."
        Write-TextToFile -text $TextToWriteToFile -filePath $FilePath
    }
    catch {
        Log-Error -Message $_.Exception.Message
    }
}

end {
    # Display the time that this script finished running, and how long it took to run.
    [DateTime] $finishTime = Get-Date
    [TimeSpan] $elapsedTime = $finishTime - $startTime
    Log-Information -Message "Finished script at '$($finishTime.ToString('u'))'. Took '$elapsedTime' to run."
}