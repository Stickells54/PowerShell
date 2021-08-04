<#	
	.NOTES
	===========================================================================
	 Created on:   	7/30/2021 9:38 AM
	 Created by:   	Travis Stickells
	 Organization: 	USPS
	 Filename:     	RDPEntitle.ps1
	===========================================================================
	.DESCRIPTION
	Created to remotely add users to the local RDP group on a given computer.

	.PARAMETER ComputerName
	Name of the computer the user should be able to RDP to.

	.PARAMETER UserID
	The USER ID of the user that should be entitled. 

	.PARAMETER LOGSTORE
	Path to location where the LOG file should be stored. Not needed. Only if you want to log the outcome externally. 

	.PARAMETER LOGNAME
	Name of the log file. It will be appended to have the computer name as the suffix. Not needed. Only if you want to log the outcome externally.

#>

param (
	[parameter (Mandatory = $true)]
	$ComputerName,
	[parameter (Mandatory = $true)]
	$UserID,
	$LogStore,
	$LogName,
	[parameter (Mandatory = $true)]
	$Domain
)
$LogName = "$LogName_$ComputerName"
$ScriptBlockAdd = [scriptblock]::Create("Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $Domain\$UserID")
$ScriptBlockGet = [scriptblock]::Create("(Get-LocalGroupMember -Group 'Remote Desktop Users').Name")

# Test Connection to Computer
$ConnectionStatus = (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)

if ($ConnectionStatus)
{
	$Members = Invoke-Command -Session $Session -ScriptBlock $ScriptBlockGet
	if ($Members -notcontains "$Domain\$UserID")
	{
		if ($LogStore)
		{
			
			Add-Content -Path $LogStore\$LogName -Value "$ComputerName is online and reachable."
			Add-Content -Path $LogStore\$LogName -Value "Adding $UserID to Remote Desktop User Group group on $ComputerName."
		}
		
		# Add user to group using a new PSSession on the remote machine.
		$Session = New-PSSession -ComputerName $ComputerName
		Invoke-Command -Session $Session -ScriptBlock $ScriptBlockAdd
		Start-Sleep 3
		#Confirm the user as added
		$Members = Invoke-Command -Session $Session -ScriptBlock $ScriptBlockGet
		if ($Members -notcontains "$Domain\$UserID")
		{
			if ($LogStore)
			{
				Add-Content -Path $LogStore\$LogName -Value "$UserID not added to Remote Desktop User Group"
			}
			
			Write-Host "$UserID not added to Remote Desktop User Group.. Exiting Script.."
			Start-Sleep 5
			Exit 0
		}
		if ($Members -contains "$Domain\$UserID")
		{
			if ($LogStore)
			{
				Add-Content -Path $LogStore\$LogName -Value "$UserID successfully added to Remote Desktop User Group"
			}
			
			Write-Host "$UserID successdully added to Remote Desktop User Group.. Exiting Script.."
			Start-Sleep 5
			Exit 0
		}
	}
	if ($Members -contains "$Domain\$UserID")
	{
		if ($LogStore)
		{
			Add-Content -Path $LogStore\$LogName -Value "$UserID already added to Remote Desktop User Group on $ComputerName"
		}
		
		Write-Host "$UserID already added to Remote Desktop User Group on $ComputerName.. Exiting Script.."
		Start-Sleep 5
		Exit 0
	}
}


if (!$ConnectionStatus)
{
	if ($LogStore) { Add-Content -Path $LogStore\$LogName -Value "Computer not reachable. Exiting Script.." }
	Write-Host "Computer not reachable. Exiting Script.." -ForegroundColor Yellow -BackgroundColor Black
	Start-Sleep 5
	Exit 0
}
