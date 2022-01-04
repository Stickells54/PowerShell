<#	
	.NOTES
	===========================================================================
	 Created on:   	4/18/2021 
	 Created by:   	Travis Stickells
	 Filename:     	UserFileMigrations.ps1
	===========================================================================
	.DESCRIPTION
	Used to migrate user files from static\full clone desktops to a network share that will later be used for folder redirection. Read over the script and change directories as needed. Usefull for when you are 
	migrating users from static machines over to instant clones. Make sure you have your folder redirection setup in GPO/VMware DEM to match where the folders are being redirected. 

	.Parameter CONSERV
	IP or Hostname of the Horizon Connection Server
	
	.Parameter HZAdmin
	Username of a Horizon View Administrator Account

	.Parameter HZPAss
	Password for the user account

	.PARAMETER Domain
	The domain associated with the user HZAdmin account

	.PARAMETER FQDN
	FQDN for the VMs in the pool. i.e. contoso.com. The script will look for files in $VM.contoso.com\c$\users\$user\etc

	.PARAMETER PoolName
	Name of the Horizon Pool that you want to migrate user files from

	.PARAMETER RedirectPath
	The remote share where users files should be copied to.

	.PARAMETER Directories
	The user directories that should be copied over. Add or remove user directories as needed.
#>

param
(
	[parameter(Mandatory = $true)]
	$CONSERV,
	$HZAdmin,
	$HZPass,
	$Domain,
	$FQDN,
	$PoolName,
	$RedirectPath,
	$Directories = @('Desktop', 'Documents', 'Favorites')
	
)

Import-Module VMware.VimAutomation.Core
Import-Module VMware.Hv.Helper
Import-Module VMware.VimAutomation.HorizonView

##########################################
Connect-HVServer -Server $CONSERV -Domain $Domain -User $HZAdmin -Password $HZPass
$VMs = Get-HVMachineSummary -PoolName $PoolName
$Machines = @()
foreach ($VM in $VMs)
{
	if ($Null -ne $VM.NamesData.Username) { $Machines += $VM.Base.Name }
}

$UserArray = $VMs.NamesData.Username
$Users = @()
foreach ($User in $UserArray)
{
	if ($Null -ne $User)
	{
		$Split = $User.Split('\')
		$User = $Split[1]
		$Users += $User
	}
}

for ($i = 0; $i -lt $Users.Count; $i++)
{
	$Machine = $Machines[$i]
	$User = $Users[$i]
	foreach ($Directory in $Directories)
	{
		New-Item -ItemType Directory -Path $RedirectPath\$User\$Directory\
		Copy-Item -Path "\\$($Machine).$($FQDN)\c$\Users\$($User)\$($Directory)\*" -Destination $RedirectPath\$User\$Directory\
	}
}
