<#	
	.NOTES
	===========================================================================
	 Created on:   	4/18/2021 
	 Created by:   	Travis Stickells
	 Filename:     	HorizonEntitleUsers.ps1
	===========================================================================
	.DESCRIPTION
	Bulk entitle individual users to a resource in Horizon.
	If using a CSV, the first column MUST be the word 'Users' and the usernames need to be in the format of DOMAIN\USER i.e.CONTOSO\USER1. There is an example CSV available on my GitHub.
	Only specify either $User or $UserCSV; not both

	.Parameter ResourceName
	ID of the Horizon Resource (Not display name if they are different in the Horizon Dash)
	
	.Parameter ResourceType
	Either Application (RDSH) or Desktop (Pool)

	.Parameter Users
	An array of user names. Example $Users = @('CONTOSO\USER1','CONTOSO\USER2','CONTOSO\USER3',). Probabyl easier to create an array first, then pass it as an argument into the script.

	.PARAMETER UserCSV
	Path to a CSV file containing a list of users to be entitled. Example $UserCSV = "C:\Temp\Users.CSV". CSV must have the word 'Users' in the first row of the column. 

#>
param
(
	[parameter(Mandatory = $true)]
	$ResourceName,
	[parameter(Mandatory = $true)]
	$ResourceType,
	$Users = @(),
	$UserCSV
)

## Need PowerCLI installed as well as the scripts from the github. https://github.com/vmware/PowerCLI-Example-Scripts
Import-Module -Name VMware.Hv.Helper
Import-Module -Name VMware.VimAutomation.Core

if ($UserCSV -and $Users)
{
	Write-Host "Please only specify either an array of users or a CSV - not both!"
	Read-Host -Prompt "Press Enter to exit Script!"
	Exit 0
}

if ($UserCSV)
{
	foreach ($User in $UserCSV.Users)
	{
		New-HVEntitlement -User $User -ResourceName $ResourceName -ResourceType $ResourceType
	}
	Read-Host -Prompt "Press Enter to exit Script!"
	Exit 0
}

if ($Users)
{
	foreach ($User in $Users)
	{
		New-HVEntitlement -User $User -ResourceName $ResourceName -ResourceType $ResourceType
	}
	Read-Host -Prompt "Press Enter to exit Script!"
	Exit 0
	
}

