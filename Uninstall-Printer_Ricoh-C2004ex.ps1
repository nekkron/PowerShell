# Variables
$printerName = "RICOH MP C2004ex PCL 6" # This is the name the user will see when searching for printers
$driverName = "Gestetner MP C2004ex PCL 6" # Must be exact. Install driver on your computer and copy its name and paste here

# Remove Printer
if ($printerExists) {
Remove-Printer -Name $printerName
}
