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

# Remove Printer
if ($printerExists) {
Remove-Printer -Name $printerName
}
