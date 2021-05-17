# Variables
$driverDownloadPath = "https://dl.konicaminolta.eu/en/?tx_kmanacondaimport_downloadproxy[fileId]=73a7023c221c5196187099a44491c2df&tx_kmanacondaimport_downloadproxy[documentId]=5674&tx_kmanacondaimport_downloadproxy[system]=KonicaMinolta&tx_kmanacondaimport_downloadproxy[language]=EN&type=1558521685"
$portName = "IP_192.168.10.10"
$portAddress = "192.168.10.10" # Printer IP
$printerName = "Guest Printer" # This is the name the user will see when searching for printers
$driverName = "KONICA MINOLTA C658SeriesPCL" # Must be exact. Install driver on your computer and copy its name and paste here
# Do not modify these variables
$driverDownloaded = "C:\support\PrinterDriver.zip"
$extractPath = "C:\support\PrinterDriver"
$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $printerName -ErrorAction SilentlyContinue
$rebootExists = "C:\Program Files (x86)\Shield\shdcmd.exe"

# Disable Reboot Restore RX Pro
if ( -not $rebootExists) {
  "C:\Program Files (x86)\Shield\shdcmd.exe /protect disable /u Administrator /p 'U$O4tr00ps'"
  Start-Sleep -s 300
}

# Create local storage folder
New-Item -ItemType Directory -Force -Path C:\support
# Download Konica driver
Invoke-WebRequest $driverDownloadPath -OutFile $driverDownloaded
# Extract Konica driver
Expand-Archive -Path $driverDownloaded -DestinationPath $extractPath -Force
# Add to Windows Driver Store
Get-ChildItem $extractPath -Recurse -Filter "*.inf" -Force | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install }
# Add Driver
Add-PrinterDriver -Name $driverName
# Add Printer Port
if (-not $portExists) {
  Add-PrinterPort -Name $portName -PrinterHostAddress $portAddress
}
# Install Printer
if (-not $printerExists) {
Add-Printer -Name $printerName -PortName $portName -DriverName $driverName
}
# Set Default Color to Grey Scale
Set-PrintConfiguration -PrinterName $printerName -Color $false
# Set as default printer
(Get-WmiObject -ClassName Win32_Printer | Where-Object -Property Name -EQ $printerName).SetDefaultPrinter()
# Delete downloaded files
 Remove-Item -Path $driverDownloaded -Force
# Remove-Item -Path $extractPath -Force -Recurse
# Enable Reboot Restore RX Pro
if ( -not $rebootExists) {
  "C:\Program Files (x86)\Shield\shdcmd.exe /protect enable /u Administrator /p 'U$O4tr00ps'"
}
