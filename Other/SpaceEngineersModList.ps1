#=========================================================================
# Generate MOD ID List from a Steam Mod Collection URL
# Created by Archi
# Fixed by Stickells54
# Last modified 2022-6-8
# Version 1.1
#=========================================================================
cls
#Set URL of your Mod Collection for your server
#SE archicraft v2
$WorkshopCollectionURL = 'https://steamcommunity.com/sharedfiles/filedetails/?id=2496573352'
#Set Output Path and Filename of file which will contain MOD ID list
#Note: List will also display on screen
$modList = 'c:\mods.txt'
#==============================================================================================
#End configurable options
#==============================================================================================
$getPage = Invoke-WebRequest -Uri $WorkshopCollectionURL -UseBasicParsing
$modIDCollection = @()
$links = $getPage.Links
foreach ($link in $links)
{
	if ($link.outerHTML -like "*workshopItemTitle*")
	{
		$modID = $link.href.Replace('https://steamcommunity.com/sharedfiles/filedetails/?id=', '')
		if ($modIDCollection -notcontains $modID)
		{
			$desc = $link.innerText
			Write-Host "Found Mod: $desc"
			$modIDCollection += $modID
		}
	}
}
if (Test-Path $modList) { del $modList }
Set-Content -Path $modList $modIDCollection
Write-Host "Your mod list is at: $modList"
$modIDCollection
start $modList