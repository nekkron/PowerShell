# Variables
$driverDownloadPath = "https://support.ricoh.com/bb/pub_e/dr_ut_e/0001316/0001316044/V1300/z92111L16.exe"
$portName = "IP_169.254.100.100"
$portAddress = "169.254.100.100" # Printer IP
$printerName = "RICOH MP C2004ex PCL 6" # This is the name the user will see when searching for printers
$driverName = "Gestetner MP C2004ex PCL 6" # Must be exact. Install driver on your computer and copy its name and paste here
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
