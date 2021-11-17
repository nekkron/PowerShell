# Variables
$driverDownloadPath = "https://www.dropbox.com/s/w5g8dczuj5jbahj/Printer.zip?dl=1"
$portAddress = "169.254.100.100" # Printer IP
$printerName = "Samsung MultiXpress X7400LX" # This is the name the user will see when searching for printers
$driverName = "Samsung X7600 Series" # Must be exact. Install driver on your computer and copy its name and paste here

# Do not modify these variables
$driverDownloaded = "C:\support\PrinterDriver.zip"
$extractPath = "C:\support\PrinterDriver"
$portName = "IP_$portAddress"
$portExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $printerName -ErrorAction SilentlyContinue

# Remove old printer
#Remove-Printer -Name "KONICA MINOLTA bizhub C3851" 

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
# Remove-Item -Path $driverDownloadPath -Force
# Remove-Item -Path $extractPath -Force -Recurse
