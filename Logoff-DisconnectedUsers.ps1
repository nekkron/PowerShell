quser | Select-String "Disc" | ForEach {logoff ($_.tostring() -split ' +')[2]}
