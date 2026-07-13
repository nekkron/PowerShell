cd "C:\Program Files\Dell\Dell Display and Peripheral Manager\Plugins\Subagent"

echo "get -app=DiagnosticsReport" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -app=DiagnosticsReport 
value=C:\Users\%USERNAME%\Documents\ddpmdiag.log  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/get -Display=FWVersion" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=FWVersion  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/get -Display=MonitorCount" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=MonitorCount  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/get -Display=ActiveHours" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=ActiveHours  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/get -Display=BrightnessLevel" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=BrightnessLevel  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/get -Display=ContrastLevel" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=ContrastLevel  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/get -Display=ColorPreset" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=ColorPreset  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/get -Display=AutoColorPreset" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=AutoColorPreset  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/get -Display=ActiveInputSource" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=ActiveInputSource  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/set -Display=BrightnessLevel -value=50" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=BrightnessLevel -value=50  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/set -Display=ContrastLevel -value=50" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=ContrastLevel -value=50  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/set -Display=ColorPreset -value=Game" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=ColorPreset -value=Game  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/set -Display=ActiveInputSource -value=HDMI" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=ActiveInputSource -value=HDMI  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/set -Display=AutoColorPreset -value=on" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoColorPreset -value=on  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/set -Display=AutoColorPreset -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoColorPreset -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 5 
echo "/set -Display=PxP -value=pbp-2h-fill" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PxP -value=pbp-2h-fill  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 20 
echo "/set -Display=SwapVideo" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SwapVideo  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 20 
echo "/set -Display=PxP -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PxP -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 20 
echo "/set -Display=PxP -value=pip-large" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PxP -value=pip-large  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 20 
echo "/set -Display=SubInput -value=DP" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SubInput -value=DP  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 20 
echo "/set -Display=SwapVideo" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SwapVideo  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 20 
echo "/set -Display=PxP -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PxP -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 20 
echo "/set -RestoreFactoryDefaults" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent set -Display=RestoreFactoryDefaults  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=RestoreLevelDefaults" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=RestoreLevelDefaults  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=RestoreColorDefaults" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=RestoreColorDefaults  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=RestoreColorDefaults" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=RestoreColorDefaults  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=OSDLanguage -value=Russian" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=OSDLanguage -value=Russian  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=OSDLanguage" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=OSDLanguage  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=OSDLanguage -value=English" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=OSDLanguage -value=English  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=OSDAccess -value=osddisable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=OSDAccess -value=osddisable  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=OSDAccess" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=OSDAccess  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=OSDAccess -value=osdenable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=OSDAccess -value=osdenable  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=OSDAccess" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=OSDAccess  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=PowerNap -value=sleep" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PowerNap -value=sleep  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=PowerNap" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=PowerNap  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=PowerNap -value=reducebrightness" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PowerNap -value=reducebrightness  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=PowerNap -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PowerNap -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=AutoBrightness -value=on" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoBrightness -value=on  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=AutoBrightness" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=AutoBrightness  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=AutoBrightness -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoBrightness -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=AutoBrightnessRangeLevel -value=low" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoBrightnessRangeLevel -value=low  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=AutoBrightnessRangeLevel" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=AutoBrightnessRangeLevel  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=AutoBrightnessRangeLevel -value=mid" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoBrightnessRangeLevel -value=mid  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=AutoBrightnessRangeLevel -value=high" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoBrightnessRangeLevel -value=high  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=AutoColorTemp -value=on" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoColorTemp -value=on  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=AutoColorTemp" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=AutoColorTemp  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=AutoColorTemp -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=AutoColorTemp -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=PrimaryMonitorSync -value=on" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PrimaryMonitorSync -value=on  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=PrimaryMonitorSync" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=PrimaryMonitorSync  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=PrimaryMonitorSync -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PrimaryMonitorSync -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=USBCPrioritization -value=highdataspeed" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=USBCPrioritization -value=highdataspeed  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=USBCPrioritization" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=USBCPrioritization  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=USBCPrioritization -value=highresolution" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=USBCPrioritization -value=highresolution >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=ColorManagement -value=bymonitor" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=ColorManagement -value=bymonitor  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=ColorManagement" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=ColorManagement  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=ColorManagement -value=byhost" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=ColorManagement -value=byhost  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=ColorManagement -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=ColorManagement -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=EasyArrangeLayout -value=enable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=EasyArrangeLayout -value=enable  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=EasyArrangeLayout" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=EasyArrangeLayout  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=EasyArrangeLayout -value=disable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=EasyArrangeLayout -value=disable  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=EasyArrangeLayout" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=EasyArrangeLayout  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
timeout /t 10 
echo "/set -Display=EasyArrangeLayout -value=enable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=EasyArrangeLayout -value=enable  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=AllResolutionRefreshRate " >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=AllResolutionRefreshRate  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=ResolutionRefreshRate -value=< Resolution@RR, 
eg.2560x1440@60>" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=ResolutionRefreshRate 
value=1920x1080@60  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=CurrentResolutionRefreshRate " >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=CurrentResolutionRefreshRate  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=Orientation -value=portrait" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=Orientation -value=portrait  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log
timeout /t 10 
echo "/get -Display=Orientation" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=Orientation  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=Orientation -value=landscape_flipped" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=Orientation -value=landscape_flipped  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=Orientation -value=portrait_flipped" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=Orientation -value=landscapeportrait_flipped  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=Orientation -value=landscape" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=Orientation -value=landscape  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=Resolution -value=800x600>" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=Resolution -value=800x600  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=RefreshRate -value=50>" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=RefreshRate -value=50>  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerMicrophone -value=OSDlock" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerMicrophone -value=OSDlock >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerMicrophone -value=OSDDisable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerMicrophone -value=OSDDisable >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerMicrophone -value=OSDlock" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerMicrophone -value=OSDlock >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerMicrophone -value=OSDEnable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerMicrophone -value=OSDEnable >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerMicrophone -value=OSDUnlock" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerMicrophone -value=OSDUnlock >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerMicrophone -value=OSDDisable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerMicrophone -value=OSDDisable >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerMicrophone -value=OSDEnable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerMicrophone -value=OSDEnable >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -app=DeviceData" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -app=DeviceData >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -Display=SpeakerMicrophone" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=SpeakerMicrophone  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerVolume -value=OSDdisable" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerVolume -value=OSDdisable  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -Display=SpeakerVolume" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=SpeakerVolume  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -app=DeviceData" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
 
echo "get -Display=SpeakerVolume" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=SpeakerVolume  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -app=DeviceData" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -app=DeviceData >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerVolume -value=OSDdisable -Index=1" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerVolume -value=OSDdisable -Index=1  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -Display=SpeakerVolume -Index=1" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=SpeakerVolume -Index=1 >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -app=DeviceData" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -app=DeviceData >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "set -Display=SpeakerVolume -value=OSDenablee -Index=2" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=SpeakerVolume -value=OSDenable -Index=2 >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -Display=SpeakerVolume -Index=2" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=SpeakerVolume -Index=2 >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "get -app=DeviceData" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -app=DeviceData >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
echo "/set -Display=PowerSetting -value=standby" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PowerSetting -value=standby  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=PowerSetting" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=PowerSetting  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=PowerSetting -value=on" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PowerSetting -value=on  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=PowerSetting" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=PowerSetting  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/set -Display=PowerSetting -value=off" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /set -Display=PowerSetting -value=off  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
echo "/get -Display=PowerSetting" >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
CLI.Subagent /get -Display=PowerSetting  >>C:\Users\%USERNAME%\Documents\DisplayCLI.log 
timeout /t 10 
