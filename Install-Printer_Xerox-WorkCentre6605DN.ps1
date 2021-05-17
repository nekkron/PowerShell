# Variables
$driverDownloadPath = "https://www.dropbox.com/s/tcd3v7c7x4kzsle/XeroxPhaser6600_6605_6.159.8.5_PCL6_x64.zip?dl=1"
$portName = "IP_192.168.10.10"
$portAddress = "192.168.10.10" # Printer IP
$printerName = "Xerox WorkCentre 6605DN V4 PCL6" # This is the name the user will see when searching for printers
$driverName = "Xerox WorkCentre 6605DN V4 PCL6" # Must be exact. Install driver on your computer and copy its name and paste here
# Do not modify these variables
$driverDownloaded = "C:\support\PrinterDriver.zip"
$extractPath = "C:\support\PrinterDriver"
$driverPath = "C:\support\PrinterDriver\disk1"
$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $printerName -ErrorAction SilentlyContinue

# Create local storage folder
New-Item -ItemType Directory -Force -Path C:\support

# Download Konica driver
Invoke-WebRequest $driverDownloadPath -OutFile $driverDownloaded

# Extract print driver
Expand-Archive $driverDownloaded -DestinationPath $extractPath -Force

# Add to Windows Driver Store
Get-ChildItem $driverPath -Recurse -Filter "*.inf" -Force | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install }

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
 Remove-Item -Path $extractPath -Force -Recurse
