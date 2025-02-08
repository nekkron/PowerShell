<#
.SYNOPSIS
    This script reads a .reg file and generates ADMX/ADML files for GPO settings.

.DESCRIPTION
    This script accepts 3 parameters:
        1) Reg File to convert
        2) Default Language (i.e.: en-US or sp-AR, po-BR)
        3) (optional) Display Name to show in the GPO

    The output file will be named after the .REG file (if the input is myfile.REG, the output will be myfile.ADMX and myfile.ADML).
    The ADMX output file will be saved in the same folder the input .REG file is located.
    The ADML output file will be saved in a subfolder of the one the .REG file is located. The subfolder will be named after the Language specified.
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$RegFileName,

    [Parameter(Mandatory=$true)]
    [string]$Lang,

    [string]$RootDisplay = "REG_2_ADMXL Generated Policy"
)

# Function to generate a GUID
function Generate-GUID {
    return [guid]::NewGuid().ToString().Replace("{", "").Replace("}", "").Replace("-", "_")
}

# Function to get the name of the current key based on the full path
function Get-Name {
    param (
        [string]$Path
    )
    $iLast = $Path.LastIndexOf("\")
    if ($iLast -gt 0) {
        return $Path.Substring($iLast + 1)
    }
    return $Path
}

# Function to get the parent GUID based on the path structure
function Get-ParentGUID {
    param (
        [string]$Path,
        [string]$Name,
        [array]$Categories
    )
    $Find = $Path.Replace("\$Name", "")
    foreach ($Category in $Categories) {
        if ($Category.Path -eq $Find) {
            return $Category.GUID
        }
    }
    return "XML_2_ADMXL"
}

# Function to get the class of the key
function Get-Class {
    param (
        [string]$Key
    )
    switch -regex ($Key) {
        "^HKEY_CURRENT_USER" { return "User" }
        "^HKCU" { return "User" }
        "^HKEY_LOCAL_MACHINE" { return "Machine" }
        "^HKLM" { return "Machine" }
        "^HKEY_CLASSES_ROOT" { return "Both" }
        "^HKCR" { return "Both" }
        "^HKEY_CURRENT_CONFIG" { return "Machine" }
        "^HKCC" { return "Machine" }
        "^HKEY_USERS" { return "Both" }
        "^HKU" { return "Both" }
        default { return "Both" }
    }
}

# Function to import the registry file
function Import-RegFile {
    param (
        [string]$RegFileName
    )
    $Categories = @()
    $Policies = @()
    $CurrentCategory = $null

    Get-Content -Path $RegFileName | ForEach-Object {
        $Line = $_.Trim()
        if ($Line -match "^\[.*\]$") {
            $Subkey = $Line.TrimStart("[").TrimEnd("]")
            $Category = [PSCustomObject]@{
                Name = Get-Name -Path $Subkey
                Path = $Subkey
                GUID = Generate-GUID
                ParentGUID = Get-ParentGUID -Path $Subkey -Name (Get-Name -Path $Subkey) -Categories $Categories
            }
            $Categories += $Category
            $CurrentCategory = $Category
        } elseif ($Line -match "^\".*\"=") {
            $Parts = $Line.Split("=", 2)
            $ValueName = $Parts[0].Trim('"')
            $ValueData = $Parts[1].Trim()
            $ValueType = "string"
            if ($ValueData -match "^dword:") {
                $ValueType = "dword"
                $ValueData = $ValueData.Substring(6)
            } elseif ($ValueData -match "^hex:") {
                $ValueType = "hex"
                $ValueData = $ValueData.Substring(4).Replace(",", "")
            }
            $Policy = [PSCustomObject]@{
                Caption = $ValueName
                GUID = Generate-GUID
                ParentGUID = $CurrentCategory.GUID
                ValueName = $ValueName
                ValueType = $ValueType
                ValueData = $ValueData
                Path = $CurrentCategory.Path
                Class = Get-Class -Key $CurrentCategory.Path
            }
            $Policies += $Policy
        }
    }
    return [PSCustomObject]@{
        Categories = $Categories
        Policies = $Policies
    }
}

# Function to create the ADMX file
function Create-ADMX {
    param (
        [string]$Lang,
        [array]$Categories,
        [array]$Policies
    )
    $ADMXDoc = New-Object System.Xml.XmlDocument
    $Root = $ADMXDoc.CreateElement("policyDefinitions")
    $Root.SetAttribute("revision", "1.0")
    $Root.SetAttribute("schemaVersion", "1.0")
    $Root.SetAttribute("xmlns:xsd", "http://www.w3.org/2001/XMLSchema")
    $Root.SetAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
    $ADMXDoc.AppendChild($Root)

    $PolicyNamespaces = $ADMXDoc.CreateElement("policyNamespaces")
    $Root.AppendChild($PolicyNamespaces)

    $Target = $ADMXDoc.CreateElement("target")
    $Target.SetAttribute("prefix", "Call4cloud")
    $Target.SetAttribute("namespace", "MSC.Policies." + (Generate-GUID))
    $PolicyNamespaces.AppendChild($Target)

    $Using = $ADMXDoc.CreateElement("using")
    $Using.SetAttribute("prefix", "windows")
    $Using.SetAttribute("namespace", "Microsoft.Policies.Windows")
    $PolicyNamespaces.AppendChild($Using)

    $CategoriesNode = $ADMXDoc.CreateElement("categories")
    $Root.AppendChild($CategoriesNode)

    foreach ($Category in $Categories) {
        $CategoryNode = $ADMXDoc.CreateElement("category")
        $CategoryNode.SetAttribute("name", "CAT_" + $Category.GUID)
        $CategoryNode.SetAttribute("displayName", "$(string.CAT_" + $Category.GUID + ")")
        $CategoryNode.SetAttribute("explainText", "$(string.CAT_" + $Category.GUID + "_HELP)")
        if ($Category.ParentGUID -ne "XML_2_ADMXL") {
            $ParentCategory = $ADMXDoc.CreateElement("parentCategory")
            $ParentCategory.SetAttribute("ref", "CAT_" + $Category.ParentGUID)
            $CategoryNode.AppendChild($ParentCategory)
        }
        $CategoriesNode.AppendChild($CategoryNode)
    }

    $PoliciesNode = $ADMXDoc.CreateElement("policies")
    $Root.AppendChild($PoliciesNode)

    foreach ($Policy in $Policies) {
        $PolicyNode = $ADMXDoc.CreateElement("policy")
        $PolicyNode.SetAttribute("name", "POL_" + $Policy.GUID)
        $PolicyNode.SetAttribute("displayName", "$(string.POL_" + $Policy.GUID + ")")
        $PolicyNode.SetAttribute("explainText", "$(string.POL_" + $Policy.GUID + "_HELP)")
        $PolicyNode.SetAttribute("key", $Policy.Path)
        $PolicyNode.SetAttribute("class", $Policy.Class)

        $ParentCategory = $ADMXDoc.CreateElement("parentCategory")
        $ParentCategory.SetAttribute("ref", "CAT_" + $Policy.ParentGUID)
        $PolicyNode.AppendChild($ParentCategory)

        $SupportedOn = $ADMXDoc.CreateElement("supportedOn")
        $SupportedOn.SetAttribute("ref", "windows:SUPPORTED_WindowsVista")
        $PolicyNode.AppendChild($SupportedOn)

        $Elements = $ADMXDoc.CreateElement("elements")
        $PolicyNode.AppendChild($Elements)

        if ($Policy.ValueType -eq "string") {
            $Text = $ADMXDoc.CreateElement("text")
            $Text.SetAttribute("id", "TXT_" + $Policy.GUID)
            $Text.SetAttribute("valueName", $Policy.ValueName)
            $Elements.AppendChild($Text)
        } elseif ($Policy.ValueType -eq "dword") {
            $Decimal = $ADMXDoc.CreateElement("decimal")
            $Decimal.SetAttribute("id", "DXT_" + $Policy.GUID)
            $Decimal.SetAttribute("valueName", $Policy.ValueName)
            $Elements.AppendChild($Decimal)
        } elseif ($Policy.ValueType -eq "hex") {
            $Text = $ADMXDoc.CreateElement("text")
            $Text.SetAttribute("id", "HXT_" + $Policy.GUID)
            $Text.SetAttribute("valueName", $Policy.ValueName)
            $Elements.AppendChild($Text)
        }

        $PoliciesNode.AppendChild($PolicyNode)
    }

    return $ADMXDoc
}

# Function to create the ADML file
function Create-ADML {
    param (
        [string]$Lang,
        [array]$Categories,
        [array]$Policies
    )
    $ADMLDoc = New-Object System.Xml.XmlDocument
    $Root = $ADMLDoc.CreateElement("policyDefinitionResources")
    $Root.SetAttribute("revision", "1.0")
    $Root.SetAttribute("schemaVersion", "1.0")
    $Root.SetAttribute("xmlns:xsd", "http://www.w3.org/2001/XMLSchema")
    $Root.SetAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
    $ADMLDoc.AppendChild($Root)

    $DisplayName = $ADMLDoc.CreateElement("displayName")
    $DisplayName.InnerText = "REG_2_ADMXL"
    $Root.AppendChild($DisplayName)

    $Description = $ADMLDoc.CreateElement("description")
    $Description.InnerText = "This policy file was generated by the REG_2_ADMXL tool`nSource File: $RegFileName`n`nPlease change this part to match the description"
    $Root.AppendChild($Description)

    $Resources = $ADMLDoc.CreateElement("resources")
    $Root.AppendChild($Resources)

    $StringTable = $ADMLDoc.CreateElement("stringTable")
    $Resources.AppendChild($StringTable)

    foreach ($Category in $Categories) {
        $String = $ADMLDoc.CreateElement("string")
        $String.SetAttribute("id", "CAT_" + $Category.GUID)
        $String.InnerText = $Category.Name
        $StringTable.AppendChild($String)

        $StringHelp = $ADMLDoc.CreateElement("string")
        $StringHelp.SetAttribute("id", "CAT_" + $Category.GUID + "_HELP")
        $StringHelp.InnerText = "This Category configures the Values located under the [$($Category.Path)] Key.`n`nThis policy file was generated by the REG_2_ADMXL tool`nPlease change this part to define the description"
        $StringTable.AppendChild($StringHelp)
    }

    foreach ($Policy in $Policies) {
        $String = $ADMLDoc.CreateElement("string")
        $String.SetAttribute("id", "POL_" + $Policy.GUID)
        $String.InnerText = $Policy.Caption
        $StringTable.AppendChild($String)

        $StringHelp = $ADMLDoc.CreateElement("string")
        $StringHelp.SetAttribute("id", "POL_" + $Policy.GUID + "_HELP")
        $StringHelp.InnerText = "This Policy configures the Value [$($Policy.ValueName)] located under the [$($Policy.Path)] Key.`n`nIn the .REG file, this setting was defined as [$($Policy.ValueType)] and had the value [$($Policy.ValueData)] assigned.`n`nThis policy file was generated by the REG_2_ADMXL tool`nPlease change this part to match your own awesome slogan"
        $StringTable.AppendChild($StringHelp)
    }

    $PresentationTable = $ADMLDoc.CreateElement("presentationTable")
    $Resources.AppendChild($PresentationTable)

    foreach ($Policy in $Policies) {
        $Presentation = $ADMLDoc.CreateElement("presentation")
        $Presentation.SetAttribute("id", "POL_" + $Policy.GUID)
        $PresentationTable.AppendChild($Presentation)

        if ($Policy.ValueType -eq "string") {
            $TextBox = $ADMLDoc.CreateElement("textBox")
            $TextBox.SetAttribute("refId", "TXT_" + $Policy.GUID)
            $Presentation.AppendChild($TextBox)

            $Label = $ADMLDoc.CreateElement("label")
            $Label.InnerText = $Policy.Caption
            $TextBox.AppendChild($Label)

            $DefaultValue = $ADMLDoc.CreateElement("defaultValue")
            $DefaultValue.InnerText = $Policy.ValueData
            $TextBox.AppendChild($DefaultValue)
        } elseif ($Policy.ValueType -eq "dword") {
            $DecimalTextBox = $ADMLDoc.CreateElement("decimalTextBox")
            $DecimalTextBox.SetAttribute("refId", "DXT_" + $Policy.GUID)
            $Presentation.AppendChild($DecimalTextBox)
        } elseif ($Policy.ValueType -eq "hex") {
            $TextBox = $ADMLDoc.CreateElement("textBox")
            $TextBox.SetAttribute("refId", "HXT_" + $Policy.GUID)
            $Presentation.AppendChild($TextBox)
        }
    }

    return $ADMLDoc
}

# Function to save the XML files
function Save-XML {
    param (
        [xml]$ADMXDoc,
        [xml]$ADMLDoc,
        [string]$RegFileName,
        [string]$Lang
    )
    $ADMXName = $RegFileName.ToLower().Replace(".reg", ".admx")
    $ADMLName = $RegFileName.ToLower().Replace(".reg", ".adml")
    $ADMLPath = Join-Path -Path (Split-Path -Path $ADMLName -Parent) -ChildPath $Lang
    $ADMLName = Join-Path -Path $ADMLPath -ChildPath (Split-Path -Path $ADMLName -Leaf)

    $ADMXDoc.Save($ADMXName)
    if (-not (Test-Path -Path $ADMLPath)) {
        New-Item -ItemType Directory -Path $ADMLPath
    }
    $ADMLDoc.Save($ADMLName)
}

# Main script execution
$Data = Import-RegFile -RegFileName $RegFileName
$ADMXDoc = Create-ADMX -Lang $Lang -Categories $Data.Categories -Policies $Data.Policies
$ADMLDoc = Create-ADML -Lang $Lang -Categories $Data.Categories -Policies $Data.Policies
Save-XML -ADMXDoc $ADMXDoc -ADMLDoc $ADMLDoc -RegFileName $RegFileName -Lang $Lang