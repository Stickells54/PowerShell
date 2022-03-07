<#	
	.NOTES
	===========================================================================
	 Created on:   	3/6/2022 7:28 PM
	 Created by:   	Travis Stickells
	 Filename:     	AppVol_BulkAssign.ps1
	===========================================================================
	.DESCRIPTION
		Bulk Entitle an array of users to an appstack. Useful when you need a lot of users to have access quickly but cannot get an AD group created in time (bureaucracy, right?)

	.NOTES
		The API calls are made over HTTPS. Make sure you either have a truseted cert installed or have Set-PowerCLIConfiguration to ignore/warn for invalid SSL certs.

	.PARAMETER AVServer
		AppVolumes Manager URL to auth to. Will run API calls to this server/URL.

	.PARAMETER UserArray
		Array of user sAMAccountName that you want to entitle to the group. The script pulls the user's DN and entitles them that way (thank the AV API for that fun quirk)
		Defaults to a USers.csv file on the C:\Temp directory. 
	.PARAMETER AVCreds
		Credentials used to auth to the AV server. Must have rights to entitle users to an appstack.
	
	.PARAMETER AppName
		Name of the AppStack as it appears in AppVol Manager
#>

param (
	[Parameter(Mandatory = $true)]
	$AVServer,
	[Parameter(Mandatory = $true)]
	$UserArray = Import-Csv C:\Temp\Users.csv,
	[Parameter(Mandatory = $true)]
	$AVCreds = (Get-Credential),
	[Parameter(Mandatory = $true)]
	$AppName
)

#Create the payload to auth to the AV server
$AuthPayload = @{
	username = $AVCreds.UserName
	password = $AVCreds.GetNetworkCredential().Password
}

#Auth to server and save the session as a variable
try
{
	Invoke-RestMethod -SessionVariable AVSession -Method Post -Uri "https//$AVServer/cv_api/sessions" -Body $AuthPayload
}
catch { Write-Host "Failed to authenticate to $AVServer" }

#Find the appstack ID from the name
$AppID = (Get-AppVolumes | where name -EQ $Appname).id

#Find the DN for each user, add it to the URI, re-encode the URI into URL format,  and entitle them to the appstack
foreach ($User in $UserArray)
{
	try
	{
		$USERDN = (Get-ADUser -Identity $User -Properties DistinguishedName).DistinguishedName
		$URI_PLAIN = "https://$AVServer/cv_api/assignments?action_type=assign&id=$AppID&assignments%5B0%5D%5Bentity_type%5D=user&assignments%5B0%5D%5Bpath%5D=$USERDN&rtime=(false.toString())&mount_prefix="
		$URI_ENCODED = [System.Web.HTTPUtility]::UrlEncode($URI_PLAIN)
		Invoke-RestMethod -WebSession $AVSession -Uri $URI_ENCODED -Method Post
	}catch {Write-Host "Error entitling user $User to $AppName"}
	
}
