<#	
	.NOTES
	===========================================================================
	 Created on:   	4/20/2020 8:10 AM
	 Created by:   	Travis Stickells
	 Filename:     	ForceLogoff.ps1
	===========================================================================
	.DESCRIPTION
	Force-logoff all disconnected users in Horizon across all pools.

	.PARAMETER HVServer
	Horizon Server URL i.e. horizon.contoso.com

#>
param (
	[Parameter(Mandatory = $true)]
	$HVServer
)

Get-Module -Name VMware.Hv.Helper | Import-Module
$HVSVC = Connect-HVServer -Server $HVServer
$Sessions = Get-HVLocalSession

foreach ($Session in $Sessions)
{
	if (($Session).SessionData.SessionState -eq "Disconnected")
	{
		$HVSVC.ExtensionData.Session.Session_Logoff(($Session).ID.Id)
	}
}
