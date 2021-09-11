<#	
	.NOTES
	===========================================================================
	 Created on:   	9/10/2021 8:40 AM
	 Created by:   	Travis Stickells	
	 Filename:     	IP_Printer_Mapper.ps1
	===========================================================================
	.DESCRIPTION
		VMware DEM does not natively support TCP/IP network printer persistence. Here is the process to make this work:
		- Create a Logoff setting in DEM that runs IP_Printer_Capture.ps1 to capture the user's IP Printers on logoff.
		- Create a Logon setting in DEM that runs IP_Printer_Mapper.ps1 to then re-map the printer on logon.

	.NOTES
		- You need to have the printer driver you want to use in the base image. 
		- You should exclude the printer entities that exist in the base image so that only the printers added by users are capture. These are to be added to $ExistingPrinters array below.
		- Captured printer info is stored in the user's DEM profile directory and then pulled back down on logon via the IP_Printer_Mapper.ps1 script. 
		- Set the user profile directory to the $DEMUserShare variable. This should match wahtever is set in the GPOs i.e. "\\path\to\usershare\$env:Username" !!! NO TRAILING '\' !!!
		- In DEM you will use %username% but because this is POSH, we need to use $env:Username in its place for the DEM User Share path
#>

$DEMUserShare = "\\path\to\demusershare\$env:Username" # No trailing '\' - Should match the path in IP_Printer_Capture.ps1
$LogFile = "$DEMUserShare\IP_Printer.log"

Start-Transcript -Path $LogFile 

# Create empty arrays for the data we need
$PrinterIPs = @()
$PrinterNames = @()
$PrinterDriverNames =@()

# Import the information for the printers that were captured..
$PrinterList = Import-Csv -Path "$DEMUserShare\IP_PRINTERS.CSV"

# Fill the empty arrays with the data we imported
$PrinterList.IP | % { $PrinterIPs += $_ }
$PrinterList.Names | % { $PrinterNames += $_ }
$PrinterList.Drivers | % {$PrinterDriverNames += $_}

$PrinterNames | % {Write-Output "Detected Printer $_ to be added"}

# Loop through the arrays and add the printers
for ($Printer = 0; $Printer -lt $PrinterNames.Count; $Printer++)
{
	Add-PrinterPort -Name $PrinterIPs[$Printer] -PrinterHostAddress $PrinterIPs[$Printer]
	Write-Output "Added Printer Port: $PrinterIPs[$Printer]"
	Add-Printer -Name $PrinterNames[$Printer] -PortName $PrinterIPs[$Printer] -DriverName $PrinterDriverNames[$Printer]
	Write-Output "Printer $PrinterNames[$Printer] added. Port: $PrinterIPs[$Printer] DriverName: $PrinterDriverNames[$Printer]"
}

Write-Output "All Printers added!"

Exit 0
