# Variables
$OfficedriverDownloadPath = "https://support.ricoh.com/bb/pub_e/dr_ut_e/0001311/0001311155/V1400/z91957L16.exe"
$OfficeportName = "IP_192.168.10.10"
$OfficeportAddress = "192.168.10.10" # Printer IP
$OfficeprinterName = "Office (C306Z PCL 6)" # This is the name the user will see when searching for printers
$OfficedriverName = "Gestetner MP C306Z PCL 6" # Must be exact. Install driver on your computer and copy its name and paste here
$CenterportName = "IP_192.168.10.11"
$CenterportAddress = "192.168.10.11" # Printer IP
$CenterprinterName = "Lounge (C305+ PCL 6)" # This is the name the user will see when searching for printers
$CenterdriverName = "Gestetner MP 305+ PCL 6" # Must be exact. Install driver on your computer and copy its name and paste here
# Do not modify these variables
$driverDownloaded = "C:\support\PrinterDriver.zip"
$extractPath = "C:\support\PrinterDriver"
$driverPath = "C:\support\PrinterDriver\disk1"
$portExists = Get-Printerport -Name $Centerportname -ErrorAction SilentlyContinue
$portExists = Get-Printerport -Name $Officeportname -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $CenterprinterName -ErrorAction SilentlyContinue
$printerExists = Get-Printer -Name $OfficeprinterName -ErrorAction SilentlyContinue

# Remove Printer
Remove-Printer -Name $CenterprinterName
Remove-Printer -Name $OfficeprinterName
