# Variables
$driverDownloadPath = "https://support.ricoh.com/bb/pub_e/dr_ut_e/0001318/0001318756/V11000/z90523L16.exe"
$portName = "IP_169.254.100.100"
$portAddress = "169.254.100.100" # Printer IP
$printerName = "Guest Printer" # This is the name the user will see when searching for printers
$driverName = "Gestetner MP C2003 PCL 6" # Must be exact. Install driver on your computer and copy its name and paste here
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
