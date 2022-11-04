# Variables
$driverDownloadPath = "https://dl.konicaminolta.eu/en/?tx_kmanacondaimport_downloadproxy[fileId]=8ac5b73cd33080c385004fa88f2e6533&tx_kmanacondaimport_downloadproxy[documentId]=123284&tx_kmanacondaimport_downloadproxy[system]=KonicaMinolta&tx_kmanacondaimport_downloadproxy[language]=EN&type=1558521685"
$portName = "IP_192.168.10.10" # Printer port name
$portAddress = "192.168.10.10" # Printer IP
$printerName = "KONICA MINOLTA C4050i PCL6" # Printer display name
$driverName = "KONICA MINOLTA C4050iSeriesPCL" # Must be exact! Install driver on your computer and copy its name and paste here!
# Do not modify these variables
$driverDownloaded = "C:\support\PrinterDriver.zip"
$extractPath = "C:\support\PrinterDriver"
$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
#####################
# Waving magic wand #
#####################
New-Item -ItemType Directory -Force -Path C:\support # Create local storage folder
Invoke-WebRequest $driverDownloadPath -OutFile $driverDownloaded # Download Konica driver
Expand-Archive -Path $driverDownloaded -DestinationPath $extractPath -Force # Extract Konica driver
Get-ChildItem $extractPath -Recurse -Filter "*.inf" -Force | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install } # Add to Windows Driver Store
Add-PrinterDriver -Name $driverName # Add Driver
# Add Printer Port
if (-not $portExists) {
  Add-PrinterPort -Name $portName -PrinterHostAddress $portAddress
}
# Install Printer
if (-not $printerExists) {
Add-Printer -Name $printerName -PortName $portName -DriverName $driverName
}
Set-PrintConfiguration -PrinterName $printerName -Color $false # Set Default Color to Grey Scale
(Get-WmiObject -ClassName Win32_Printer | Where-Object -Property Name -EQ $printerName).SetDefaultPrinter() # Set as default printer
# Cleanup
Remove-Item -Path $driverDownloaded -Force
Remove-Item -Path $extractPath -Force -Recurse
