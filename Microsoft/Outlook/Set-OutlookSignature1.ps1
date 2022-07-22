# Create Corporate Outlook Signature Block
# https://community.spiceworks.com/topic/447761-powershell-creating-a-outlook-signature
$strName = $env:username

$strFilter = "(&(objectCategory=User)(samAccountName=$strName))"

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.Filter = $strFilter

$objPath = $objSearcher.FindOne()
$objUser = $objPath.GetDirectoryEntry()

$strName = $objUser.FullName
$strTitle = $objUser.Title
$strCompany = $objUser.Company
$strCred = $objUser.info
$strStreet = $objUser.StreetAddress
$strPhone = $objUser.homePhone
$strMainPhone = $objUser.telephonenumber
$strMobile = $objUser.mobile
$strCity =  $objUser.l
$strState = $objUser.st
$strEmail = $objUser.mail
$strWebsite = $objUser.wWWHomePage
$strDisplayTitle = $objUser.postofficebox
$strDoNotDisplayMobile = $objUser.pager
$strCerts = $objUser.department

$UserDataPath = $Env:appdata
if (test-path "HKCU:\\Software\\Microsoft\\Office\\11.0\\Common\\General") {
  get-item -path HKCU:\\Software\\Microsoft\\Office\\11.0\\Common\\General | new-Itemproperty -name Signatures -value signatures -propertytype string -force
 } 

if (test-path "HKCU:\\Software\\Microsoft\\Office\\12.0\\Common\\General") {
  get-item -path HKCU:\\Software\\Microsoft\\Office\\12.0\\Common\\General | new-Itemproperty -name Signatures -value signatures -propertytype string -force
}
if (test-path "HKCU:\\Software\\Microsoft\\Office\\15.0\\Common\\General") {
  get-item -path HKCU:\\Software\\Microsoft\\Office\\15.0\\Common\\General | new-Itemproperty -name Signatures -value signatures -propertytype string -force
}
$FolderLocation = $UserDataPath + '\\Microsoft\\signatures'  
mkdir $FolderLocation -force

#Stop WGA or WA employees getting signature.
IF ($strCompany -ne "Company Architects, Inc.")
{EXIT}

#Creates Signature wth Title and No Mobile/Ext phone numbers
IF ($strDoNotDisplayMobile -eq "1" -and $strDisplayTitle -eq "1")
{$stream = [System.IO.StreamWriter] "$FolderLocation\\$strName.htm"
$stream.WriteLine("<!DOCTYPE HTML PUBLIC `"-//W3C//DTD HTML 4.0 Transitional//EN`">")
$stream.WriteLine("<HTML><HEAD><TITLE>Signature</TITLE>")
$stream.WriteLine("<style type=`"text/css`">")
$stream.WriteLine("<!--")
$stream.WriteLine("A:link { COLOR: #0000A0; TEXT-DECORATION: none; font-weight: normal }")
$stream.WriteLine("A:visited { COLOR: #0000A0; TEXT-DECORATION: none; font-weight: normal }")
$stream.WriteLine("A:active { COLOR: black; TEXT-DECORATION: none }")
$stream.WriteLine("A:hover { COLOR: blue; TEXT-DECORATION: none; font-weight: none }")
$stream.WriteLine("-->")
$stream.WriteLine("</style>")
$stream.WriteLine("</head>")
$stream.WriteLine("<div style=`"line-height:16px; margin:6px 0; padding:8px 8px 8px 8px; font-family: 'Lucida Sans', Lucida Grande, Verdana, Arial, Sans-Serif; font-size:11px; color:#333333;`">")
$stream.WriteLine("<strong style=`"color:#333333; font-size:15px; color:#00007C; `">$strName</strong> $strCerts<br>")
$stream.WriteLine("$strTitle<br>")
$stream.WriteLine("<br>")
$stream.WriteLine("$strCompany</a><br>")
$stream.WriteLine("$strStreet  | $strCity, $strState<br>")
$stream.WriteLine("office: $strMainPhone<br>")
$stream.WriteLine("<a href=`"mailto:$strEmail`" style=`"color: #333333`">$strEmail</a><br>")
$stream.WriteLine("<a href=`"http://www.Company.com`">$strWebsite</a><br>")
$stream.WriteLine("<br>")
IF ($strState -eq "PA")
{$stream.WriteLine("<img src=`"http://Companyftp.com/Company_Company.jpg`">")}
Else
{$stream.WriteLine("<img src=`"http://Companyftp.com/CompanyIcon.jpg`">")}
$stream.WriteLine("<br>")
$stream.WriteLine("<font size=`"1`"><a href=`"https://www.facebook.com/CompanyArchitects`">Facebook </a>| <a href=`"https://twitter.com/CompanyArchitects`">Twitter </a>| <a href=`"https://www.linkedin.com/company/Company-architects`">LinkedIn</a></font><br>")
IF ($strState -eq "PA")
{$stream.WriteLine("<font color:`"#333333`"; font size=`"1`"> Company studio has merged with Company Architects</font>") 
$stream.WriteLine("</div>")
$stream.close()
}
Else
{$stream.WriteLine("</div>")
$stream.close()} 

#Creates RTF Signature
$wrd = new-object -com word.application 

# Make Word Visible 
$wrd.visible = $false
 
# Open a document  
$fullPath = $FolderLocation+”\$strName.htm"
$doc = $wrd.documents.open($fullpath) 

# Save as rtf
$opt = 6
$name = $FolderLocation+”\$strName.rtf"
$wrd.ActiveDocument.Saveas($name,$opt)

#Set company signature as default for New messages/Reply Messages
$EmailOptions = $wrd.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.NewMessageSignature=$strName
$EmailSignature.ReplyMessageSignature=$strName

# Close word
$wrd.Quit()

#Create Sigture Text File
$stream = [System.IO.StreamWriter] "$FolderLocation\\$strName.txt"
$stream.WriteLine("$strName")
$stream.WriteLine("$strTitle")
$stream.WriteLine(" ")
$stream.WriteLine("$StrCompany")
$stream.WriteLine("$strStreet  | $strCity, $strState")
$stream.WriteLine("office: $strMainPhone")
$stream.WriteLine("$strEmail")
$stream.WriteLine("$strWebsite")
IF ($strState -eq "PA")
{$stream.WriteLine("Company studio has merged with Company Architects") 
$stream.close()
}
Else
{$stream.close()}


EXIT
}

IF ($strDoNotDisplayMobile -eq "1")
{$stream = [System.IO.StreamWriter] "$FolderLocation\\$strName.htm"
$stream.WriteLine("<!DOCTYPE HTML PUBLIC `"-//W3C//DTD HTML 4.0 Transitional//EN`">")
$stream.WriteLine("<HTML><HEAD><TITLE>Signature</TITLE>")
$stream.WriteLine("<style type=`"text/css`">")
$stream.WriteLine("<!--")
$stream.WriteLine("A:link { COLOR: #0000A0; TEXT-DECORATION: none; font-weight: normal }")
$stream.WriteLine("A:visited { COLOR: #0000A0; TEXT-DECORATION: none; font-weight: normal }")
$stream.WriteLine("A:active { COLOR: black; TEXT-DECORATION: none }")
$stream.WriteLine("A:hover { COLOR: blue; TEXT-DECORATION: none; font-weight: none }")
$stream.WriteLine("-->")
$stream.WriteLine("</style>")
$stream.WriteLine("</head>")
$stream.WriteLine("<div style=`"line-height:16px; margin:6px 0; padding:8px 8px 8px 8px; font-family: 'Lucida Sans', Lucida Grande, Verdana, Arial, Sans-Serif; font-size:11px; color:#333333;`">")
$stream.WriteLine("<strong style=`"color:#333333; font-size:15px; color:#00007C; `">$strName</strong> $strCerts<br>")
$stream.WriteLine("<br>")
$stream.WriteLine("$strCompany<br>")
$stream.WriteLine("$strStreet  | $strCity, $strState<br>")
$stream.WriteLine("office: $strMainPhone<br>")
$stream.WriteLine("<a href=`"mailto:$strEmail`" style=`"color: #333333`">$strEmail</a><br>")
$stream.WriteLine("<a href=`"http://www.Company.com`">$strWebsite</a><br>")
$stream.WriteLine("<br>")
IF ($strState -eq "PA")
{$stream.WriteLine("<img src=`"http://Companyftp.com/Company_Company.jpg`">")}
Else
{$stream.WriteLine("<img src=`"http://Companyftp.com/CompanyIcon.jpg`">")}
$stream.WriteLine("<br>")
$stream.WriteLine("<font size=`"1`"><a href=`"https://www.facebook.com/CompanyArchitects`">Facebook </a>| <a href=`"https://twitter.com/CompanyArchitects`">Twitter </a>| <a href=`"https://www.linkedin.com/company/Company-architects`">LinkedIn</a></font><br>")
IF ($strState -eq "PA")
{$stream.WriteLine("<font color:`"#333333`"; font size=`"1`"> Company studio has merged with Company Architects</font>") 
$stream.WriteLine("</div>")
$stream.close()
}
Else
{$stream.WriteLine("</div>")
$stream.close()}

#Creates RTF Signature
$wrd = new-object -com word.application 

# Make Word Visible 
$wrd.visible = $false
 
# Open a document  
$fullPath = $FolderLocation+”\$strName.htm"
$doc = $wrd.documents.open($fullpath) 

# Save as rtf
$opt = 6
$name = $FolderLocation+”\$strName.rtf"
$wrd.ActiveDocument.Saveas($name,$opt)

#Set company signature as default for New messages/Reply Messages
$EmailOptions = $wrd.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.NewMessageSignature=$strName
$EmailSignature.ReplyMessageSignature=$strName

# Close word
$wrd.Quit()

#Create Sigture Text File
$stream = [System.IO.StreamWriter] "$FolderLocation\\$strName.txt"
$stream.WriteLine("$strName")
$stream.WriteLine(" ")
$stream.WriteLine("$StrCompany")
$stream.WriteLine("$strStreet  | $strCity, $strState")
$stream.WriteLine("office: $strMainPhone")
$stream.WriteLine("$strEmail")
$stream.WriteLine("$strWebsite")
IF ($strState -eq "PA")
{$stream.WriteLine("Company studio has merged with Company Architects") 
$stream.close()
}
Else
{$stream.close()}

EXIT
}

IF ($strDisplayTitle -eq "1") 
#Create HTML Signature  
{$stream = [System.IO.StreamWriter] "$FolderLocation\\$strName.htm"
$stream.WriteLine("<!DOCTYPE HTML PUBLIC `"-//W3C//DTD HTML 4.0 Transitional//EN`">")
$stream.WriteLine("<HTML><HEAD><TITLE>Signature</TITLE>")
$stream.WriteLine("<style type=`"text/css`">")
$stream.WriteLine("<!--")
$stream.WriteLine("A:link { COLOR: #0000A0; TEXT-DECORATION: none; font-weight: normal }")
$stream.WriteLine("A:visited { COLOR: #0000A0; TEXT-DECORATION: none; font-weight: normal }")
$stream.WriteLine("A:active { COLOR: black; TEXT-DECORATION: none }")
$stream.WriteLine("A:hover { COLOR: blue; TEXT-DECORATION: none; font-weight: none }")
$stream.WriteLine("-->")
$stream.WriteLine("</style>")
$stream.WriteLine("</head>")
$stream.WriteLine("<div style=`"line-height:16px; margin:6px 0; padding:8px 8px 8px 8px; font-family: 'Lucida Sans', Lucida Grande, Verdana, Arial, Sans-Serif; font-size:11px; color:#333333;`">")
$stream.WriteLine("<strong style=`"color:#333333; font-size:15px; color:#00007C; `">$strName</strong> $strCerts<br>")
$stream.WriteLine("$strTitle<br>")
$stream.WriteLine("<br>")
$stream.WriteLine("$strCompany<br>")
$stream.WriteLine("$strStreet  | $strCity, $strState<br>")
$stream.WriteLine("office: $strMainPhone<br>")
$stream.WriteLine("direct: $strPhone<br>")
$stream.WriteLine("mobile: $strMobile<br>")
$stream.WriteLine("<a href=`"mailto:$strEmail`" style=`"color: #333333`">$strEmail</a><br>")
$stream.WriteLine("<a href=`"http://www.Company.com`">$strWebsite</a><br>")
$stream.WriteLine("<br>")
IF ($strState -eq "PA")
{$stream.WriteLine("<img src=`"http://Companyftp.com/Company_Company.jpg`">")}
Else
{$stream.WriteLine("<img src=`"http://Companyftp.com/CompanyIcon.jpg`">")}
$stream.WriteLine("<br>")
$stream.WriteLine("<font size=`"1`"><a href=`"https://www.facebook.com/CompanyArchitects`">Facebook </a>| <a href=`"https://twitter.com/CompanyArchitects`">Twitter </a>| <a href=`"https://www.linkedin.com/company/Company-architects`">LinkedIn</a></font><br>")
IF ($strState -eq "PA")
{$stream.WriteLine("<font color:`"#333333`"; font size=`"1`"> Company studio has merged with Company Architects</font>") 
$stream.WriteLine("</div>")
$stream.close()
}
Else
{$stream.WriteLine("</div>")
$stream.close()}

#Creates RTF Signature
$wrd = new-object -com word.application 

# Make Word Visible 
$wrd.visible = $false
 
# Open a document  
$fullPath = $FolderLocation+”\$strName.htm"
$doc = $wrd.documents.open($fullpath) 

# Save as rtf
$opt = 6
$name = $FolderLocation+”\$strName.rtf"
$wrd.ActiveDocument.Saveas($name,$opt)

#Set company signature as default for New messages/Reply Messages
$EmailOptions = $wrd.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.NewMessageSignature=$strName
$EmailSignature.ReplyMessageSignature=$strName

# Close word
$wrd.Quit()

#Create Sigture Text File
$stream = [System.IO.StreamWriter] "$FolderLocation\\$strName.txt"
$stream.WriteLine("$strName")
$stream.WriteLine("$strTitle")
$stream.WriteLine(" ")
$stream.WriteLine("$StrCompany")
$stream.WriteLine("$strStreet  | $strCity, $strState")
$stream.WriteLine("office: $strMainPhone")
$stream.WriteLine("direct: $strPhone")
$stream.WriteLine("mobile: $strMobile")
$stream.WriteLine("$strEmail")
$stream.WriteLine("$strWebsite")
IF ($strState -eq "PA") 
{$stream.WriteLine("Company studio has merged with Company Architects") }
$stream.close() 

}
Else
#Create HTML Signature
{$stream = [System.IO.StreamWriter] "$FolderLocation\\$strName.htm"
$stream.WriteLine("<!DOCTYPE HTML PUBLIC `"-//W3C//DTD HTML 4.0 Transitional//EN`">")
$stream.WriteLine("<HTML><HEAD><TITLE>Signature</TITLE>")
$stream.WriteLine("<style type=`"text/css`">")
$stream.WriteLine("<!--")
$stream.WriteLine("A:link { COLOR: #0000A0; TEXT-DECORATION: none; font-weight: normal }")
$stream.WriteLine("A:visited { COLOR: #0000A0; TEXT-DECORATION: none; font-weight: normal }")
$stream.WriteLine("A:active { COLOR: black; TEXT-DECORATION: none }")
$stream.WriteLine("A:hover { COLOR: blue; TEXT-DECORATION: none; font-weight: none }")
$stream.WriteLine("-->")
$stream.WriteLine("</style>")
$stream.WriteLine("</head>")
$stream.WriteLine("<div style=`"line-height:16px; margin:6px 0; padding:8px 8px 8px 8px; font-family: 'Lucida Sans', Lucida Grande, Verdana, Arial, Sans-Serif; font-size:11px; color:#333333;`">")
$stream.WriteLine("<strong style=`"color:#333333; font-size:15px; color:#00007C; `">$strName</strong> $strCerts<br>")
$stream.WriteLine("<br>")
$stream.WriteLine("$strCompany<br>")
$stream.WriteLine("$strStreet  | $strCity, $strState<br>")
$stream.WriteLine("office: $strMainPhone</a><br>")
$stream.WriteLine("direct: $strPhone<br>")
$stream.WriteLine("mobile: $strMobile<br>")
$stream.WriteLine("<a href=`"mailto:$strEmail`" style=`"color: #333333`">$strEmail</a><br>")
$stream.WriteLine("<a href=`"http://www.Company.com`">$strWebsite</a><br>")
$stream.WriteLine("<br>")
IF ($strState -eq "PA")
{$stream.WriteLine("<img src=`"http://Companyftp.com/Company_Company.jpg`">")}
Else
{$stream.WriteLine("<img src=`"http://Companyftp.com/CompanyIcon.jpg`">")}
$stream.WriteLine("<br>")
$stream.WriteLine("<font size=`"1`"><a href=`"https://www.facebook.com/CompanyArchitects`">Facebook </a>| <a href=`"https://twitter.com/CompanyArchitects`">Twitter </a>| <a href=`"https://www.linkedin.com/company/Company-architects`">LinkedIn</a></font><br>")
IF ($strState -eq "PA")
{$stream.WriteLine("<font color:`"#333333`"; font size=`"1`"> Company studio has merged with Company Architects</font>") 
$stream.WriteLine("</div>")
$stream.close()
}
Else
{$stream.WriteLine("</div>")
$stream.close()}

#Creates RTF Signature
$wrd = new-object -com word.application 

# Make Word Visible 
$wrd.visible = $false
 
# Open a document  
$fullPath = $FolderLocation+”\$strName.htm"
$doc = $wrd.documents.open($fullpath) 

# Save as rtf
$opt = 6
$name = $FolderLocation+”\$strName.rtf"
$wrd.ActiveDocument.Saveas($name,$opt)

#Set company signature as default for New messages/Reply Messages
$EmailOptions = $wrd.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.NewMessageSignature=$strName
$EmailSignature.ReplyMessageSignature=$strName

# Close word
$wrd.Quit()

#Create Sigture Text File
$stream = [System.IO.StreamWriter] "$FolderLocation\\$strName.txt"
$stream.WriteLine("$strName")
$stream.WriteLine(" ")
$stream.WriteLine("$StrCompany")
$stream.WriteLine("$strStreet  | $strCity, $strState")
$stream.WriteLine("office: $strMainPhone")
$stream.WriteLine("direct: $strPhone")
$stream.WriteLine("mobile: $strMobile")
$stream.WriteLine("$strEmail")
$stream.WriteLine("$strWebsite")
IF ($strState -eq "PA")
{$stream.WriteLine("Company studio has merged with Company Architects") 
$stream.close()
}
Else
{$stream.close()}
}
