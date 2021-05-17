# Variables
$driverDownloadPath = "https://support.ricoh.com/bb/pub_e/dr_ut_e/0001311/0001311155/V1400/z91957L16.exe"
$portName = "IP_192.168.10.10"
$portAddress = "192.168.10.10" # Printer IP
$printerName = "Office (C306Z PCL 6)" # This is the name the user will see when searching for printers
$driverName = "Gestetner MP C306Z PCL 6" # Must be exact. Install driver on your computer and copy its name and paste here
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
