### Update Deployment Share ###

# Import MDT Toolkit

Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

# Get all exisiting boot images and remove them

Get-WdsBootImage | Remove-WdsBootImage

# Loop through all deployment shares in "D:\Deployment Shares\" and do the following...
# 1. Make a PS Drive for it
# 2. Update it
# 3. Import it to WDS
# 4. Remove the PS Drive

$DeploymentShares = Get-ChildItem -Path 'D:\Deployment Shares'

foreach ($DeploymentShare in $DeploymentShares) {
    $DSName = $($DeploymentShare.name)
    $DSPath = $($DeploymentShare.fullname)
    New-PSDrive -Name $DSName -PSProvider MDTProvider -Root $DSPath -Verbose
    update-MDTDeploymentShare -Path "$($DeploymentShare.name):" -Verbose
    Import-WdsBootImage -NewImageName $DSName -NewDescription $DSName -Path "$DSPath\Boot\LiteTouchPE_x64.wim" -Verbose
    Get-PSDrive -Name $DSName | Remove-PSDrive -Verbose
    }
