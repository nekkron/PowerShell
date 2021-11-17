#The purpose of this script is to download an image, or series of images, from the Internet and install them into the Teams Backgrounds folder for the signed-in user.
#  20200423 - James Kasparek - Senior Regional IT Support Technician
#

#Image location on the Internet. Ensure file extension matches the deployed extension!
#$url00 = "https://www.google.com/images/branding/googlelogo/1x/googlelogo_light_color_272x92dp.png"
$url01 = "https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg"
$url02 = "https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Microsoft_logo_%282012%29_modified.svg/2560px-Microsoft_logo_%282012%29_modified.svg.png"
$url03 = "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Vmware.svg/1200px-Vmware.svg.png"
$url04 = "https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Dell_Logo.svg/2048px-Dell_Logo.svg.png"
$url05 = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/HP_logo_2012.svg/1024px-HP_logo_2012.svg.png"
$url06 = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Lenovo_logo_2015.svg/2560px-Lenovo_logo_2015.svg.png"
$url07 = "https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Logitech_logo.svg/2560px-Logitech_logo.svg.png"
$url08 = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Disney_wordmark.svg/1280px-Disney_wordmark.svg.png"
$url09 = "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Intel_logo_%282006-2020%29.svg/1005px-Intel_logo_%282006-2020%29.svg.png"
$url10 = "http://wiki.innovaphone.com/img_auth.php/a/a1/Yealink_Logo.png"

#Path for where file is being downloaded to
$TeamsBackgounds = "$Env:APPDATA\Microsoft\Teams\Backgrounds\Uploads"
#$ZoomBackgrounds = ""

#Where the real work happens. Ensure Output file extension is the same as website file extension!
#Invoke-WebRequest $url00 -OutFile $TeamsBackgounds\file00.png
Invoke-WebRequest $url01 -OutFile $TeamsBackgounds\file01.jpg
Invoke-WebRequest $url02 -OutFile $TeamsBackgounds\file02.jpg
Invoke-WebRequest $url03 -OutFile $TeamsBackgounds\file03.jpg
Invoke-WebRequest $url04 -OutFile $TeamsBackgounds\file04.jpg
Invoke-WebRequest $url05 -OutFile $TeamsBackgounds\file05.jpg
Invoke-WebRequest $url06 -OutFile $TeamsBackgounds\file06.jpg
Invoke-WebRequest $url07 -OutFile $TeamsBackgounds\file07.jpg
Invoke-WebRequest $url08 -OutFile $TeamsBackgounds\file08.jpg
Invoke-WebRequest $url09 -OutFile $TeamsBackgounds\file09.jpg
Invoke-WebRequest $url10 -OutFile $TeamsBackgounds\file10.jpg
