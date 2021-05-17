# Change Windows time sync location and force time sync
# https://docs.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /update
