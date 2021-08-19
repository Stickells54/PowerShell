<#	
	.NOTES
	===========================================================================
	 Created on:   	8/18/2021 11:10 AM
	 Created by:   	Travis Stickells
	 Filename:     	ForceDisconnectRDSSessions.ps1
	===========================================================================
	.DESCRIPTION
		Force-logoff specific type of sessions for a specific user.
	.PARAMETER User
		UserID of the person we want to force logoff sessions for.

	.PARAMETER FQDN
		FQDN of the user's domain i.e. domain.contoso.com

	.PARAMETER ConnectionServer
		FQDN or VIP of the Horizon Connection Servers

	.PARAMETER DesktopType
		RDS for RDSH Apps or Desktop for Horizon Deskstop sessions
#>

param(
	[Parameter(Mandatory=$True,)]
	$USER,
	[Parameter(Mandatory = $True,)]
	$FQDN,
	[Parameter(Mandatory = $True,)]
	$ConnectionServer,
	[Parameter(Mandatory = $true)]
	[ValidateSet]("RDS", "Desktop")
	$DesktopType
)

$User = $FQDN + '\' + "$USER" #this is the username format that the session block returns
$HVSVC = Connect-HVServer -Server $ConnectionServer
$Sessions = Get-HVLocalSession
$SessionExists = $false #We will check the condition on this variable later to confirm a session was found
foreach ($Session in $Sessions){
    if (($Session.NamesData.UserName -eq $User) -and ($Session.NamesData.DesktopType -eq $DesktopType)){
        $SessionExists = $True #Changes the condition of the variable once any session matching our parameters are found
		$ServerName = $Session.NamesData.MachineorRDSServerName
		if ($DesktopType -eq 'RDS')
		{
			$ApplicationName = $Session.NamesData.ApplicationNames
			Write-Host "Application Name: $ApplicationName"
		}
		$UserID = $Session.NamesData.UserName.Split("\")[1] # We are using the username from the session object to verify we have the correct user's session in the output
        Write-Host "Disconnecting $UserID from $ServerName.."
           try{
        $HVSVC.ExtensionData.Session.Session_LogoffForced(($session.id))
        Write-Host "Session Force Logged off successfully..."
        }Catch{Write-Host "An error occurred when logging off $USERID"}
    }
}
if ($SessionExists -eq $false){
    Write-Host "No Sessions found for $USER" -ForegroundColor Red -BackgroundColor Black
}
Read-Host -Prompt "Press any key to exit..." #Basically a pause to allow the person running the script to read the output
Exit 0