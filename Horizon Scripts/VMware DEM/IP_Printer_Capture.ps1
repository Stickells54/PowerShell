<#	
	.NOTES
	===========================================================================
	 Created on:   	9/9/2021 1:56 PM
	 Created by:   	Travis Stickells	
	 Filename:     	IP_Printer_Capture.ps1
	===========================================================================
	.DESCRIPTION
		VMware DEM does not natively support TCP/IP network printer persistence. Here is the process to make this work:
		- Create a Logoff script in DEM that runs IP_Printer_Capture.ps1 to capture the user's IP Printers on logoff.
		- Create a Logon Script in DEM that runs IP_Printer_Mapper.ps1 to then re-map the printer on logon.

	.NOTES
		- You need to have the printer driver you want to use in the base image. 
		- You should exclude the printer entities that exist in the base image so that only the printers added by users are capture. These are to be added to $ExistingPrinters array below.
		- Captured printer info is stored in the user's DEM profile directory and then pulled back down on logon via the IP_Printer_Mapper.ps1 script. 
		- Set the user profile directory to the $DEMUserShare variable. This should match wahtever is set in the GPOs i.e. "\\path\to\usershare\$env:Username" !!! NO TRAILING '\' !!!
		- In DEM you will use %username% but because this is POSH, we need to use $env:Username in its place for the DEM User Share path
#>

$ExistingPrinters = @('Print Anywhere', 'OneNote (Desktop)', 'Microsoft XPS Document Writer', 'Microsoft Print to PDF', 'Fax')
$DEMUserShare = "\\path\to\demusershare\$env:Username" # No trailing '\'

#Create empty array for the printer properties we need to save
$NewPrinterNames = @()
$NewPrinterDriverNames = @()
$NewPrinterIP = @()

#Get the Name, DriverName, and PortName (IP for IP based Printers) for all printers that aren't in the existing printers array
$null = Get-Printer | % { if ($ExistingPrinters -notcontains $_.Name) { [string]$NewPrinterDriverNames += $_.DriverName; [string]$NewPrinterIP += $_.PortName; [string]$NewPrinterNames += $_.Name } }

#Create a PSObject and load all the data into the Object Properties
$Printers = New-Object -TypeName System.Management.Automation.PSObject
$Printers | Add-Member -MemberType NoteProperty -Name Drivers -Value $NewPrinterDriverNames
$Printers | Add-Member -MemberType NoteProperty -Name IP -Value $NewPrinterIP
$Printers | Add-Member -MemberType NoteProperty -Name Names -Value $NewPrinterNames

# Export the PSObject and the properties to CSV. We will call this CSV later and collect the information for importing!
$Printers | Export-Csv -Path "$DEMUserShare\IP_PRINTERS.CSV"
