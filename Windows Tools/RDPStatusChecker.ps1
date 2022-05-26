<#	
	.NOTES
	===========================================================================
	 Created on:   	2/3/22
	 Created by:   	Travis Stickells
	 Filename:     	RDPStatusChecker.ps1
	===========================================================================
	.DESCRIPTION
	Created to check remote computers to make sure the RDP enabled setting is set if they have HZ Direct Connection agent installed.

	.PARAMETER REGKEY
	Regkey location of the RDP setting. 

	.PARAMETER ComputerNames
	The computers that should be checked for RDP status. 

	.PARAMETER Credentials
	Credentials used to access the remote computer.

#>

param (
    $REGKEY = 'HKLM:\Software\Policies\VMware, Inc.\VMware VDM\Agent\Configuration\',
    $ComputerNames,
    [parameter (Mandatory = $true)]
    $Credentials = (Get-Credential)
)

$SB_GetRDPStatus = [scriptblock]::Create("Get-ItemPropertyValue -Path $REGKEY  -Name AllowDirectRDP")
 

foreach ($computer in $ComputerNames){
    $status = Invoke-Command -ComputerName $computer -Credential $Credentials -ScriptBlock $SB_GetRDPStatus
}