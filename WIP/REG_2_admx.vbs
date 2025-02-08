' The goal of this tools is to read a .reg file and generate a .admx that would allow us to set those settings thru GPO

' +-----------------------------------------------------------------------------+
' | App.Name :	REG_2_ADMXL.vbs							                        |
' | App.Description :	                                                        |
' |                     This tools reads a .reg file and generates a ADMX/ADML  |
' | pair of files that would allow us to set those settings thru GPO            |
' |                     This file accepts 3 parameters: 						|
' |	                        1) Reg File to convert								|
' |							2) Default Language (i.e.: en-US or sp-AR, po-BR)   |
' |							3) (optional) Display Name to show in the GPO													|
' |																				|
' |                     The output file will be named after the .REG file (if	|
' | the input is myfile.REG, the output will be myfile.ADMX and myfile.ADML)	|
' |	                    The ADMX output file will be saved in the same folder   |
' | the input .REG file is located												|
' |	                    The ADML output file will be saved in a subfolder of    |
' | the one the .REG file is located. The subfolder will be named after the 	|
' |	Language specified.															|
' |						So, if the reg file is C:\myapp\myfile.reg and the lang |
' | is en-US, then the ADMX file will be as in C:\myAPP\myfile.ADMX and the     |
' | ADML file will be saved as C:\myAPP\en-US\myfile.ADMX						|
' |																				|
' |																				|
' |																				|
' |	                    This file does a very simple assignment of input fields |
' |	If the data type is a dword a numeric textbox is used, otherwise a textbox  |
' | will be used.                               								|
' |	                    In my experience, this is good enought for 90% of the	|
' | cases. And if you would like fancier stuff (like comboboxes, listboxes,     |
' | date picker, etc.) you can still use this tool to generate the initial file |
' | and then add the stuff you need.                            				|
' |																				|
' |																				|
' |																				|
' | How to use it: 																|
' |	      cscript REG_2_ADMXL.vbs <Registry file> <Language> [<name>]           |
' |		Sample:																	|
' |	      cscript REG_2_ADMXL.vbs c:\myapp\myfile.reg en-US "MY APP Policies"   |
' |																				|
' +-----------------------------------------------------------------------------+


Const ForReading = 1

dim sRegFileName
dim sLang
dim sRootDisplay
dim objFSO
set objFSO = createobject("Scripting.FileSystemObject")


' check that we have the necesary arguments, if not display instructions and end.

if wscript.Arguments.Count < 2 then
    wscript.echo "Missing Parameters:" & vbcrlf & _
        "Usage:"  & vbcrlf & vbtab & _
            "cscript " & WScript.ScriptName & " <Registry file> <Language> [<name>]"  & vbcrlf  & _
        "  Sample:" & vbcrlf & vbtab  & _
            "cscript " & WScript.ScriptName & " c:\myapp\myfile.reg en-US MY_APP_Policies"
	wscript.quit
else
    sRegFileName=Wscript.Arguments.Item(0)
    sLang=Wscript.Arguments.Item(1)
end if



' Let's check that the input file really exists

    if not objFSO.FileExists(sRegFileName) then
            wscript.echo "File not found. Unable to open " & sRegFileName & "."
	wscript.quit
    end if


' OK, we have the necesary parameters, let's the games begin



' Let's check of they have specified a root node, otherwise I will use mine
    if wscript.Arguments.Count >= 3 then
        sRootDisplay=Wscript.Arguments.Item(2)
    else 
        sRootDisplay="REG_2_ADMXL Generated Policy"
    end if


' Define the Table that will hold the categories.
    dim lCategories()
    redim lCategories(4,0)
    ' First field is the name
    ' Second field is the data
    ' Third field is the GUID
    ' Fourth field is the GUID for the parent

	' Set Node 0 with the data of the Root node.
	' I must admit that is not really nice to be using node 0 this way, but it works.
	    lCategories(4,0) = ""
	    lCategories(1,0) = sRootDisplay
	    lCategories(2,0) = sRootDisplay
	    lCategories(3,0) = "XML_2_ADMXL"


' Define the table that will hold the value assignments (from now on "policies")
    dim lPolicies()
    redim lPolicies(8,0)
    ' First field is the caption
    ' Second field is the GUID
    ' Third field is the GUID for the parent
    ' Fourth field is the valueName
    ' Fifth field is the ValueType
    ' Sixth field is the ValueData
    ' Seventh field is the PATH
    ' Eight Field is the class (user Machine, both)


' Read and import the registry file.
    ImportRegFile(sRegFileName)


'Create the Basic ADMX/ADML files
    set ADMXDoc = CreateADMX
    set ADMLDoc = CreateADML

    'ListCategories
    'ListPolicies

'Generate the XML
    WriteCategories
    WritePolicies

' Write the XML files to disk
    SaveXML






' ------------------------------------------------------------------------------------------
' ALL FUNCTIONS START HERE
' ------------------------------------------------------------------------------------------

sub SaveXML()
	' This function Saves the XML files in the correct locations and with the correct name

    dim ADMXName, ADMLName, iLastBar
    ADMXName = replace(lcase(sRegFileName),".reg",".ADMX")
    ADMLName = replace(lcase(sRegFileName),".reg",".ADML")
    iLastBar = InStrRev(ADMLName,"\")
    if iLastBar=0 then
        ADMLName = sLang & "\" & ADMLName
        strFolder = sLang
    elseif iLastBar=1 then
        ADMLName = "\" & sLang &  ADMLName
        strFolder = "\" & sLang
    else
        strFolder = left(ADMLName,iLastBar) & sLang
        ADMLName = left(ADMLName,iLastBar) & sLang & "\" & right(ADMLName,len(ADMLName) - iLastBar)
    end if

    ADMXDoc.save ADMXName
    if not objFSO.FolderExists(strFolder) then
        objFSO.CreateFolder(strFolder)
    end if
    ADMLDoc.save ADMLName
end sub 


function CreateADMX ()

	' This function creates the a template ADMX
	' The ADMX file is the one that contains the policies, the ADML file(s) is the one that contains all the strings and tex, and is where all language/culture customization takes place.
	' In other words, if you want to have the same policy file in a diferent language, you copy the ADML to another folder and trasnlate each string (preserving the rest of the file)
	' All comments and settings are updated with the information from the .REG file
	' Most of this values were obtained from reading existing ADMX files, I'm unsure of the need for some of them, so I'm including them to be safe

    ' Create the xml Document
    Set xmlDoc = CreateObject("MSXML.DOMDocument")
 
    ' Create the root node for the document
    Set objRoot = xmlDoc.createElement("policyDefinitions")  
    xmlDoc.appendChild objRoot  
    
        ' Set the properties for the root node as required for the ADMX/L to work correctly
        Set xmlAttribute = xmlDoc.createAttribute("revision")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("1.0"))
    	objRoot.Attributes.setNamedItem(xmlAttribute)

        Set xmlAttribute = xmlDoc.createAttribute("schemaVersion")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("1.0"))
	    objRoot.Attributes.setNamedItem(xmlAttribute)

        Set xmlAttribute = xmlDoc.createAttribute("xmlns:xsd")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("http://www.w3.org/2001/XMLSchema"))
	    objRoot.Attributes.setNamedItem(xmlAttribute)

        Set xmlAttribute = xmlDoc.createAttribute("xmlns:xsi")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("http://www.w3.org/2001/XMLSchema-instance"))
	    objRoot.Attributes.setNamedItem(xmlAttribute)
	    
	'Set xmlAttribute = xmlDoc.createAttribute("xmlns")
	''Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("http://www.microsoft.com/GroupPolicy/PolicyDefinitions"))
	'Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("http://schemas.microsoft.com/GroupPolicy/2006/07/PolicyDefinitions"))
	'objRoot.Attributes.setNamedItem(xmlAttribute)


    'Create the policynamspaces node for future use
    Set objPolNS = xmlDoc.createElement("policyNamespaces")  
    objRoot.appendChild objPolNS
    
    'Create the Target node (Looks like we need a unique one for each app, so I'll be using a GUID to ensure this)
    Set tNode = xmlDoc.createElement("target")  
    objPolNS.appendChild tNode
        ' Set the properties for the target node    
        Set xmlAttribute = xmlDoc.createAttribute("prefix")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("Call4cloud"))
	    tNode.Attributes.setNamedItem(xmlAttribute)
	    
        Set xmlAttribute = xmlDoc.createAttribute("namespace")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("MSC.Policies." & GenerateGUID ))
	    tNode.Attributes.setNamedItem(xmlAttribute)

    
    'Create the using node (defines this a a GPO)
    Set tNode = xmlDoc.createElement("using")  
    objPolNS.appendChild tNode
        ' Set the properties for the target node    
        Set xmlAttribute = xmlDoc.createAttribute("prefix")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("windows"))
	    tNode.Attributes.setNamedItem(xmlAttribute)
        Set xmlAttribute = xmlDoc.createAttribute("namespace")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("Microsoft.Policies.Windows"))
	    tNode.Attributes.setNamedItem(xmlAttribute)

    'Create the supersededAdm node (not sure i need this, but maybe some one will use it if they find it on the output file)
    Set tNode = xmlDoc.createElement("supersededAdm")  
    objRoot.appendChild tNode
        ' Set the properties for the supersededAdm node    
        Set xmlAttribute = xmlDoc.createAttribute("fileName")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode(""))
	    tNode.Attributes.setNamedItem(xmlAttribute)

    'Create the resources node (not sure i need this)
    Set tNode = xmlDoc.createElement("resources")  
    objRoot.appendChild tNode
        ' Set the properties for the target node    
        Set xmlAttribute = xmlDoc.createAttribute("minRequiredRevision")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("1.0"))
	    tNode.Attributes.setNamedItem(xmlAttribute)
        Set xmlAttribute = xmlDoc.createAttribute("fallbackCulture")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode(sLang))
	    tNode.Attributes.setNamedItem(xmlAttribute)

'    ' Create the definitions node
'    Set tNode = xmlDoc.createElement("definitions")  
'    objRoot.appendChild tNode  


    ' Create the categories node, All categories will end up here
    Set tNode = xmlDoc.createElement("categories")  
    objRoot.appendChild tNode  

    ' Create the policies node, All Policies will end up here
    Set tNode = xmlDoc.createElement("policies")  
    objRoot.appendChild tNode  




'<?xml version="1.0" encoding="utf-8"?>
     
'   Set objIntro = xmlDoc.createProcessingInstruction ("xml","version='1.0'")  
'   xmlDoc.insertBefore objIntro,xmlDoc.childNodes(0)  



    set CreateADMX = xmlDoc
    
end function




function CreateADML ()

	' This function creates the a template ADML
	' The ADMX file is the one that contains the policies, the ADML file(s) is the one that contains all the strings and tex, and is where all language/culture customization takes place.
	' In other words, if you want to have the same policy file in a diferent language, you copy the ADML to another folder and trasnlate each string (preserving the rest of the file)
	' All comments and settings are updated with the information from the .REG file
	' Most of this values were obtained from reading existing ADMX/ADML files, I'm unsure of the need for some of them, so I'm including them to be safe


    ' Create the xml    
    Set xmlDoc = CreateObject("MSXML.DOMDocument")
           
    ' Create the root node
    Set objRoot = xmlDoc.createElement("policyDefinitionResources")  
    xmlDoc.appendChild objRoot  
    
        ' Set the properties for the root node    
        Set xmlAttribute = xmlDoc.createAttribute("revision")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("1.0"))
    	objRoot.Attributes.setNamedItem(xmlAttribute)
        Set xmlAttribute = xmlDoc.createAttribute("schemaVersion")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("1.0"))
	    objRoot.Attributes.setNamedItem(xmlAttribute)



        Set xmlAttribute = xmlDoc.createAttribute("xmlns:xsd")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("http://www.w3.org/2001/XMLSchema"))
	    objRoot.Attributes.setNamedItem(xmlAttribute)
        Set xmlAttribute = xmlDoc.createAttribute("xmlns:xsi")
        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("http://www.w3.org/2001/XMLSchema-instance"))
	    objRoot.Attributes.setNamedItem(xmlAttribute)
'        Set xmlAttribute = xmlDoc.createAttribute("xmlns")
'        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("http://www.microsoft.com/GroupPolicy/PolicyDefinitions"))
''        Set xmlText = xmlAttribute.appendChild(xmlDoc.createTextNode("http://schemas.microsoft.com/GroupPolicy/2006/07/PolicyDefinitions"))
'	    objRoot.Attributes.setNamedItem(xmlAttribute)



    'Create the displayName node
    Set objPolNS = xmlDoc.createElement("displayName")  
    objRoot.appendChild objPolNS
    objPolNS.text="REG_2_ADMXL"
    
    'Create the description node
    Set objPolNS = xmlDoc.createElement("description")  
    objRoot.appendChild objPolNS
    objPolNS.text="This policy file was generated by the REG_2_ADMXL tool" & vbcrlf & _
                    "Source File: " & sRegFileName & vbcrlf & vbcrlf & _
                    "Please change this part to match the description"
    
    'Create the resources node
    Set objPolNS = xmlDoc.createElement("resources")  
    objRoot.appendChild objPolNS
            
    'Create the stringTable node. This will hold all strings for the language/culture
    Set tNode = xmlDoc.createElement("stringTable")  
    objPolNS.appendChild tNode

    'Create the presentationTable node. this will hold the diferent ways in with we want the data show (texbox, combobox, listbox, calendar picker, etc)
    Set tNode = xmlDoc.createElement("presentationTable")  
    objPolNS.appendChild tNode

   Set objIntro = xmlDoc.createProcessingInstruction ("xml","version='1.0'")  
   xmlDoc.insertBefore objIntro,xmlDoc.childNodes(0)  

    
    
    set CreateADML = xmlDoc
    
end function




Sub ImportRegFile(sRegFileName)

	' this function will read the .REG file and parse it in order to store it's data in the internal tables
	
	dim strLine, sTempLine, sSubkey, sValueName, sValuetype, SValueData, iIndex ,sTestFile
	Set objTextFile = objFSO.OpenTextFile(sRegFileName , ForReading,, -2)

'    if objTextFile.AtEndOfStream <> True then sTempLine = objtextFile.ReadLine
	Do While objTextFile.AtEndOfStream <> True
        if (objTextFile.AtEndOfStream <> True) and (bSkip <> true) then sTempLine = objtextFile.ReadLine
        bSkip = false

		strLine = sTempLine
		If left(strLine, 16) = "Windows Registry" or strLine = "" or left(strLine, 8) = "REGEDIT4" Then
			' If it's a declaratory line, then skip		
		else 
			' If this is a KEY, then create a new category
			If left(strLine, 1) = ";" Then
	            ' If it's a comment line, then skip		    
			elseIf left(strLine, 1) = "[" Then
    			' If this is a KEY, then create a new category
				sSubkey = left(right(strLine, len(strLine)- 1), len(strLine)- 2)
				redim preserve lCategories(4,ubound(lCategories,2) +1)		
                lCategories(1,ubound(lCategories,2)) = GetName(sSubkey)
                lCategories(2,ubound(lCategories,2)) = sSubkey
				lCategories(3,ubound(lCategories,2)) = GenerateGUID
                lCategories(4,ubound(lCategories,2)) = GetParentGUID(sSubkey,lCategories(1,ubound(lCategories,2)))

			elseif left(strLine, 1) = """" or left(strLine, 1) = "@" Then

				'If the line starts with @, it's an asignation of the Default Value.
				' I'm forcing the string to be the corresponding valuename
				if left(strLine, 1) = "@" Then
    				strLine = """(Default)""" & right(strLine, len(strLine)- 1)
'    				strLine = """@""" & right(strLine, len(strLine)- 1)
                end if			
				'If the line starts with double quotes, it's an asignation of values, this will be converted into a pilicy for the ADMX/L files
				strLine = right(strLine, len(strLine)- 1)
				iIndex = instr(strLine,"""")
				if iIndex > 0 then
					sValueName= left(strline,iIndex-1)
                    redim preserve lPolicies(8, ubound(lPolicies,2) +1)		
				    Set TypeLib = CreateObject("Scriptlet.TypeLib")
                    lPolicies(1,ubound(lPolicies,2)) = sValueName
				    lPolicies(2,ubound(lPolicies,2)) = GenerateGUID
                    lPolicies(3,ubound(lPolicies,2)) = lCategories(3,ubound(lCategories,2))
                    lPolicies(4,ubound(lPolicies,2)) = sValueName

                    strLine=trim(strLine)
    				iIndex2 = instr(strLine,"=")
					strLine = right(strLine, len(strLine)- iIndex2)
                    strLine=trim(strLine)
                    if left(strLine,1) = " " then strLine=right(strLine, len(strLine)-1)
                    strLine=trim(strLine)
                    if left(strLine,1) = chr(9) then strLine=right(strLine, len(strLine)-1)
                    strLine=trim(strLine)
                    if left(strLine,1) = " " then strLine=right(strLine, len(strLine)-1)
                    strLine=trim(strLine)
                    if left(strLine,1) = chr(9) then strLine=right(strLine, len(strLine)-1)


					' Now, we need to determine if what we have on the right side of the = is an string or another kind of value.
					if left(strline,1)="""" then
						' String value
						sValuetype = "string"
						SValueData = left(right(strLine, len(strLine)- 1), len(strLine)- 2)
					else
						' non string
						iIndex = instr(strLine,":")
						if iIndex > 0 then
							sValuetype = left(strline,iIndex-1)
							SValueData = right(strLine, len(strLine)- iIndex)
							
                            if left(lcase(sValuetype),3) = "hex" then
                                bSkip = false
                                do
                                    if right(SValueData,1)="\" then 
                                        SValueData = left(SValueData,len(SValueData)-1)
                                        if (objTextFile.AtEndOfStream <> True) and (bSkip <> true) then 
                                            sTempLine = objtextFile.ReadLine
                                            if left(sTempLine,1) = "@" or left(sTempLine,1) = "[" or left(sTempLine,1) = """" then
                                                bSkip = true
                                                exit do
                                            else
                                                SValueData = SValueData & sTempLine
                                            end if
                                        else
                                            'bSkip = true
                                            exit do
                                        end if
                                    else
                                        'bSkip = true
                                        exit do
                                    end if
                                loop until bSkip
                                SValueData = replace (SValueData," ","")                             
                            end if    
						else
'							sWriteLog   "Invalid record (datatype w/o ':'): " & sTempLine			
						end if
					end if
	                lPolicies(5,ubound(lPolicies,2)) = sValuetype
	                lPolicies(6,ubound(lPolicies,2)) = replace(SValueData,"\\","\")
                    sText=lCategories(2,ubound(lCategories,2))
    				lPolicies(8,ubound(lPolicies,2)) = GetClass(sText)
    				lPolicies(7,ubound(lPolicies,2)) = sText




				else
					sWriteLog   "Invalid record (Valuename w/o end quote): " & sTempLine					
				end if
			else
				sWriteLog   "Invalid record (or Valuename w/o quote): " & sTempLine					
			end if
		end if
'        if (objTextFile.AtEndOfStream <> True) and (bSkip <> true) then sTempLine = objtextFile.ReadLine
'        bSkip = false
	Loop
	objtextFile.Close

end sub



sub sWriteLog (stexto)
    wscript.echo stexto
end sub




sub ListCategories()

	' This is a function for testing porpouses, it will just list all items stored on the Categories table
    dim iCounter

    for icounter = 1 to ubound(lCategories,2)
        sWriteLog "Caption: [" & lCategories(1,iCounter) & "] " & vbcrlf &  vbtab & "Path: [" & lCategories(2,iCounter) & "] " & vbcrlf &  vbtab & " GUID: ["  & lCategories(3,iCounter) & "] " & vbcrlf &  vbtab & " ParentGuid: ["  & lCategories(4,iCounter) &  "]"
    next
end sub


sub ListPolicies()

	' This is a function for testing porpouses, it will just list all items stored on the Policies table

    dim iCounter

    for icounter = 1 to ubound(lPolicies,2)
        sWriteLog "Caption: [" & lPolicies(1,iCounter) & "] " & vbcrlf &  vbtab & " GUID: ["  & lPolicies(2,iCounter) & "] " & vbcrlf &  vbtab & " ParentGuid: ["  & lPolicies(3,iCounter) &  "] " & vbcrlf &  vbtab & " Name: ["  & lPolicies(3,iCounter) &  "] " & vbcrlf &  vbtab & " Type: ["  & lPolicies(3,iCounter) &  "] " & vbcrlf &  vbtab & " Data: ["  & lPolicies(6,iCounter) &  "]"
    next
end sub




sub WriteCategories()

	'This function converts the KEYS read from the .REG file into the corresponding categories for the GPOs

    dim iCounter
    set ADMXParentNode = ADMXDoc.selectSingleNode("policyDefinitions/categories")
    set ADMLStringNode = ADMLDoc.selectSingleNode("policyDefinitionResources/resources/stringTable")
    for icounter = 0 to ubound(lCategories,2)
    
    '   sWriteLog "Path: [" & lCategories(1,iCounter) & "] " & vbcrlf &  vbtab &  _
    '                  " GUID: ["  & lCategories(2,iCounter) & "] " & vbcrlf &  vbtab & _
    '                  " ParentGuid: ["  & lCategories(3,iCounter) &  "]"
        

    ' Create the category node on the ADMX file
        Set objCategory = ADMXDoc.createElement("category")  
        ADMXParentNode.appendChild objCategory  
    
            ' Set the properties for the category node    
            Set xmlAttribute = ADMXDoc.createAttribute("name")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("CAT_" & lCategories(3,iCounter)))
    	    objCategory.Attributes.setNamedItem(xmlAttribute)
            Set xmlAttribute = ADMXDoc.createAttribute("displayName")
            sTexto="$(string.CAT_" & lCategories(3,iCounter)
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode(sTexto & ")"))
	        objCategory.Attributes.setNamedItem(xmlAttribute)
            Set xmlAttribute = ADMXDoc.createAttribute("explainText")
            sTexto="$(string.CAT_" & lCategories(3,iCounter)
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode(sTexto & "_HELP)"))
	        objCategory.Attributes.setNamedItem(xmlAttribute)

	' Set the parent category (so AD knows how to build the Tree)
        if lCategories(4,iCounter) <> "" then
            Set objTemp = ADMXDoc.createElement("parentCategory")  
            objCategory.appendChild objTemp  
            Set xmlAttribute = ADMXDoc.createAttribute("ref")    
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("CAT_" & lCategories(4,iCounter)))
            objTemp.Attributes.setNamedItem(xmlAttribute)  
        end if


        ' Create the string node on the ADML file
        Set objTemp = ADMLDoc.createElement("string")  
        ADMLStringNode.appendChild objTemp  
            Set xmlAttribute = ADMLDoc.createAttribute("id")
            Set xmlText = xmlAttribute.appendChild(ADMLDoc.createTextNode("CAT_" & lCategories(3,iCounter)))
            objTemp.Attributes.setNamedItem(xmlAttribute)
            objTemp.text = lCategories(1,iCounter)
        Set objTemp = ADMLDoc.createElement("string")  
        ADMLStringNode.appendChild objTemp  
            Set xmlAttribute = ADMLDoc.createAttribute("id")
            Set xmlText = xmlAttribute.appendChild(ADMLDoc.createTextNode("CAT_" & lCategories(3,iCounter) & "_HELP"))
            objTemp.Attributes.setNamedItem(xmlAttribute)
            objTemp.text = "This Category configures the Values located under the [" & lCategories(2,iCounter) & "] Key." & vbcrlf & vbcrlf & _
                            "This policy file was generated by the REG_2_ADMXL tool" & vbcrlf & _
                            "Please change this part to define the description"
    
        '      <parentCategory ref="SAMPLE" />

    next
end sub







sub WritePolicies()

    dim iCounter
    set ADMXParentNode = ADMXDoc.selectSingleNode("policyDefinitions/policies")
    set ADMLStringNode = ADMLDoc.selectSingleNode("policyDefinitionResources/resources/stringTable")
    set ADMLPresentationNode = ADMLDoc.selectSingleNode("policyDefinitionResources/resources/presentationTable")
    for icounter = 1 to ubound(lPolicies,2)
    
    '   sWriteLog "Path: [" & lPolicies(1,iCounter) & "] " & vbcrlf &  vbtab &  _
    '                  " GUID: ["  & lPolicies(2,iCounter) & "] " & vbcrlf &  vbtab & _
    '                  " ParentGuid: ["  & lPolicies(3,iCounter) &  "]"
        
    ' Create the policy node On the ADMX File
        Set objPolicy = ADMXDoc.createElement("policy")  
        ADMXParentNode.appendChild objPolicy  

    
            ' Set the properties for the Policy node On the ADMX File   
            Set xmlAttribute = ADMXDoc.createAttribute("name")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("POL_" & lPolicies(2,iCounter)))
    	    objPolicy.Attributes.setNamedItem(xmlAttribute)
            Set xmlAttribute = ADMXDoc.createAttribute("displayName")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("$(string.POL_" & lPolicies(2,iCounter) & ")"))
	        objPolicy.Attributes.setNamedItem(xmlAttribute)
            Set xmlAttribute = ADMXDoc.createAttribute("explainText")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("$(string.POL_" & lPolicies(2,iCounter) & "_HELP)"))
	        objPolicy.Attributes.setNamedItem(xmlAttribute)

'            Set xmlAttribute = ADMXDoc.createAttribute("valueName")
'            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode(lPolicies(1,iCounter)))
' 	         objPolicy.Attributes.setNamedItem(xmlAttribute)
            Set xmlAttribute = ADMXDoc.createAttribute("key")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode(lPolicies(7,iCounter)))
	        objPolicy.Attributes.setNamedItem(xmlAttribute)
            Set xmlAttribute = ADMXDoc.createAttribute("class")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode(lPolicies(8,iCounter)))
	        objPolicy.Attributes.setNamedItem(xmlAttribute)

            'presentation="$(presentation.Sample_Textbox)"

            'explainText="$(string.Sample_Textbox_Help)" 




        ' Create the string node On the ADML File
        Set objTemp = ADMLDoc.createElement("string")  
        ADMLStringNode.appendChild objTemp  
            Set xmlAttribute = ADMLDoc.createAttribute("id")
            Set xmlText = xmlAttribute.appendChild(ADMLDoc.createTextNode("POL_" & lPolicies(2,iCounter)))
            objTemp.Attributes.setNamedItem(xmlAttribute)
            objTemp.text = lPolicies(1,iCounter)      
        Set objTemp = ADMLDoc.createElement("string")  
        ADMLStringNode.appendChild objTemp  
            Set xmlAttribute = ADMLDoc.createAttribute("id")
            Set xmlText = xmlAttribute.appendChild(ADMLDoc.createTextNode("POL_" & lPolicies(2,iCounter) & "_HELP"))
            objTemp.Attributes.setNamedItem(xmlAttribute)
            objTemp.text = "This Policy configures the Value [" & lPolicies(4,iCounter) & "] located under the [" & lPolicies(7,iCounter) & "] Key." & vbcrlf & vbcrlf & _
                           "In the .REG file, this setting was defined as [" & lPolicies(5,iCounter) & "] and had the value [" & lPolicies(6,iCounter) & "] assigned." & vbcrlf & vbcrlf & _
                            "This policy file was generated by the REG_2_ADMXL tool" & vbcrlf & _
                            "Please change this part to match your own awesome slogan"

	    
' Parent category so AD knows under what node of the tree to show this policy    
        Set objTemp = ADMXDoc.createElement("parentCategory")  
        objPolicy.appendChild objTemp  
            Set xmlAttribute = ADMXDoc.createAttribute("ref")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("CAT_" & lPolicies(3,iCounter)))
            objTemp.Attributes.setNamedItem(xmlAttribute)  

'This is another of those settings that I do not really know if i need, nor I know what are oll the posible values. 
' I've found 2: "SUPPORTED_WindowsVista" and "SUPPORTED_ProductOnly". Because I do not really know what this last one means, I'll use the Vista one for everything.
' This goes on the ADMX file
        Set objTemp = ADMXDoc.createElement("supportedOn")  
        objPolicy.appendChild objTemp  
            Set xmlAttribute = ADMXDoc.createAttribute("ref")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("windows:SUPPORTED_WindowsVista"))
            objTemp.Attributes.setNamedItem(xmlAttribute)  



        Set objElements = ADMXDoc.createElement("elements")  
        objPolicy.appendChild objElements


'      <presentation id="POL_A10AF138_0BBF_4285_85DC_A68ACC333E63">
' Create the presentation node
' This goes on the ADML file
        Set objpresentation = ADMLDoc.createElement("presentation")  
        ADMLPresentationNode.appendChild objpresentation  
            Set xmlAttribute = ADMLDoc.createAttribute("id")
            Set xmlText = xmlAttribute.appendChild(ADMLDoc.createTextNode("POL_" & lPolicies(2,iCounter)))
            objpresentation.Attributes.setNamedItem(xmlAttribute)
            ' Set the presentation for the presentation node    
            Set xmlAttribute = ADMXDoc.createAttribute("presentation")
            Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("$(presentation.POL_" & lPolicies(2,iCounter) & ")"))
    	    objPolicy.Attributes.setNamedItem(xmlAttribute)

' Here is the cheap and basic logic that determines what kind of interface the user will have in AD to enter the policy values.
' Currently, the logic is: If the data is a text gets a textbox, if the data is dword gets a numeric textbox. if the data is anything else, then becomes a text.
' I'm aware that this does not cover all posible cases, but it's a start and enought for my current needs.
' This goes on the ADMX file        
        if lcase(lPolicies(5,iCounter)) = "string" then
            '        <text id="Sample_TextboxPrompt" valueName="Example2textbox" />
            Set objTemp = ADMXDoc.createElement("text")  
            objElements.appendChild objTemp  
                Set xmlAttribute = ADMXDoc.createAttribute("id")
                Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("TXT_" & lPolicies(2,iCounter)))
                objTemp.Attributes.setNamedItem(xmlAttribute)  
                Set xmlAttribute = ADMXDoc.createAttribute("valueName")
                Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode(lPolicies(1,iCounter)))
	            objTemp.Attributes.setNamedItem(xmlAttribute)

			' The strings for the previous data must be saved as well
			' This goes on the ADML file        
	        	' <TextBox refId="TXT_EA865626_37FD_48A5_8CFE_77702C6D648D">
        	    	' Create the string node
		           Set objTextbox = ADMLDoc.createElement("textBox")  
		            objpresentation.appendChild objTextbox  
                	Set xmlAttribute = ADMLDoc.createAttribute("refId")
	                Set xmlText = xmlAttribute.appendChild(ADMLDoc.createTextNode("TXT_" & lPolicies(2,iCounter)))
        	        objTextbox.Attributes.setNamedItem(xmlAttribute)

	                '          <label>Country</label>
        	        Set objTemp = ADMLDoc.createElement("label")  
                	objTextbox.appendChild objTemp  
	                objTemp.text=lPolicies(1,iCounter)
	
        	        '          <defaultValue>US</defaultValue>
                	Set objTemp = ADMLDoc.createElement("defaultValue")  
	                objTextbox.appendChild objTemp  
        	        objTemp.text=lPolicies(6,iCounter)

       elseif lcase(lPolicies(5,iCounter)) = "dword" then     
            '         <decimal id="DXT_CECFD96A_F36B_4AB8_8B0F_57F8BAB84D08" key="SOFTWARE\COMPANY\PRODUCT\90\Config" valueName="User_Id" />
            Set objTemp = ADMXDoc.createElement("decimal")  
            objElements.appendChild objTemp  
                Set xmlAttribute = ADMXDoc.createAttribute("id")
                Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("DXT_" & lPolicies(2,iCounter)))
                objTemp.Attributes.setNamedItem(xmlAttribute)  
                Set xmlAttribute = ADMXDoc.createAttribute("valueName")
                Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode(lPolicies(1,iCounter)))
	            objTemp.Attributes.setNamedItem(xmlAttribute)


            '        <decimalTextBox refId="DXT_CECFD96A_F36B_4AB8_8B0F_57F8BAB84D08">
            '       </decimalTextBox>
            ' Create the decimalTextBox node ' This goes on the ADML file        
	           Set objTextbox = ADMLDoc.createElement("decimalTextBox")  
        	    objpresentation.appendChild objTextbox  
                	Set xmlAttribute = ADMLDoc.createAttribute("refId")
	                Set xmlText = xmlAttribute.appendChild(ADMLDoc.createTextNode("DXT_" & lPolicies(2,iCounter)))
        	        objTextbox.Attributes.setNamedItem(xmlAttribute)

       elseif left(lcase(lPolicies(5,iCounter)),3) = "hex" then     
            ' This is a Hexadecimal Value ... I have not found a way to handle them so, for now, I will just handle them as string
            Set objTemp = ADMXDoc.createElement("text")  
            objElements.appendChild objTemp  
                Set xmlAttribute = ADMXDoc.createAttribute("id")
                Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode("HXT_" & lPolicies(2,iCounter)))
                objTemp.Attributes.setNamedItem(xmlAttribute)  
                Set xmlAttribute = ADMXDoc.createAttribute("valueName")
                Set xmlText = xmlAttribute.appendChild(ADMXDoc.createTextNode(lPolicies(1,iCounter)))
	            objTemp.Attributes.setNamedItem(xmlAttribute)


            '        <decimalTextBox refId="DXT_CECFD96A_F36B_4AB8_8B0F_57F8BAB84D08">
            '       </decimalTextBox>
            ' Create the decimalTextBox node ' This goes on the ADML file        
	           Set objTextbox = ADMLDoc.createElement("TextBox")  
        	    objpresentation.appendChild objTextbox  
                	Set xmlAttribute = ADMLDoc.createAttribute("refId")
	                Set xmlText = xmlAttribute.appendChild(ADMLDoc.createTextNode("HXT_" & lPolicies(2,iCounter)))
        	        objTextbox.Attributes.setNamedItem(xmlAttribute)
        else
            wscript.echo "UNKNOWN DATATYPE: " & lPolicies(5,iCounter)
            ' Create the decimalTextBox node
            Set objTemp = ADMXDoc.createElement("Text")  
            objElements.appendChild objTemp  
           Set objTextbox = ADMLDoc.createElement("Text")  
            objpresentation.appendChild objTextbox  

        end if

	' If we had a Boolean data or something that get's turn ON/OFF we would use this, but I have not find a good way to determine that on the fly, so I just leave it here in case i ever do.
	'      Set objTemp = ADMXDoc.createElement("enabledValue")  
	'      objPolicy.appendChild objTemp  
	'      Set objTemp = ADMXDoc.createElement("disabledValue")  
	'      objPolicy.appendChild objTemp  	            	                      	            
	            
    next
end sub


function GetClass(byref sKey)

    dim iBar
	' This function determines the scope ("CLASS" in the ADMX file) of the KEY.
	' As allwyass, my logic is really basic: everything is BOTH, except for HKCU that get's assigned USER and HKLM that get's assigned Machine.
    dim sTempClass
    sTempClass = "Both"
    if left(sKey,17)="HKEY_CURRENT_USER" then
        sKey=right(sKey,len(sKey)-17-1)
        sTempClass="User"
    elseif left(sKey,4)="HKCU" then
        sKey=right(sKey,len(sKey)-4-1)
        sTempClass="User"
    elseif left(sKey,18)="HKEY_LOCAL_MACHINE" then
        sKey=right(sKey,len(sKey)-18-1)
        sTempClass="Machine"
    elseif left(sKey,4)="HKLM" then
        sKey=right(sKey,len(sKey)-4-1)
        sTempClass="Machine"
    elseif left(sKey,17)="HKEY_CLASSES_ROOT" then
        sKey= "SOFTWARE\Classes" & right(sKey,len(sKey)-17)
        sTempClass="Both"
    elseif left(sKey,4)="HKCR" then
        sKey="SOFTWARE\Classes" & right(sKey,len(sKey)-4)
        sTempClass="Both"
    elseif left(sKey,19)="HKEY_CURRENT_CONFIG" then
        sKey= "SYSTEM\CurrentControlSet\Hardware Profiles\Current"   & right(sKey,len(sKey)-19)
        sTempClass="Machine"
    elseif left(sKey,4)="HKCC" then
        sKey= "SYSTEM\CurrentControlSet\Hardware Profiles\Current"   & right(sKey,len(sKey)-4)
        sTempClass="Machine"
    elseif left(sKey,10)="HKEY_USERS" then
        sKey=right(sKey,len(sKey)-10-1)
        iBar = instr(1,sKey,"\")
        sKey=right(sKey,len(sKey)-iBar)        
        sTempClass="Both"
    elseif left(sKey,3)="HKU" then
        sKey=right(sKey,len(sKey)-3-1)
        iBar = instr(1,sKey,"\")
        sKey=right(sKey,len(sKey)-iBar)        
        sTempClass="Both"
    end if
    GetClass = sTempClass
end function




function GetName(sPath)
	' This function retrieves the name of the current KEY based on the full PAth
    iLast = InStrRev(sPath,"\")
    sTemp="\\\\"
    if iLast > 0 then
        sTemp=right(sPath,len(sPath)-iLast)
    end if
    GetName=sTemp
end function


function GetParentGUID(sPath,sName)
	' This function finds the Parent of the current registry KEY based on the PATH structure.
    sFind = replace(sPath,"\" & sName,"")
    sTemp="XML_2_ADMXL"
    for icounter = 1 to ubound(lCategories,2)
        if lcase(sFind) = lcase(lCategories(2,iCounter)) then
            sTemp= lCategories(3,iCounter)   
        end if
    next
    GetParentGUID=sTemp
end function




function GenerateGUID()
	' All settings in the GP must be unique, not only for this particular ADMX but for any other on the system.
	' The best way to ensure that is to use GUIDs to name the objects.
	Set TypeLib = CreateObject("Scriptlet.TypeLib")
        sTemp = TypeLib.GUID
        sTemp = replace(sTemp,"{","")
        sTemp = replace(sTemp,"}","")
        sTemp = replace(sTemp,"-","_")
        GenerateGUID =  left(sTemp, len(sTemp)-2)

end function