<#	
	.NOTES
	===========================================================================
	 Created on:   	3/24/2021 
	 Created by:   	Travis Stickells
	 Filename:     	AppVolumeReport.ps1
	===========================================================================
	.DESCRIPTION
	Creates a detailed report of AppVolumes KPIs. 

	.Parameter AppVolMGR
	IP or Hostname of the AppVolumes Manager Server
	
	.Parameter OutputFile
	Absolute path to the XLSX file that will be generated
#>
param
(
	[parameter(Mandatory = $true)]
	$AppVolMGR,
	$OutputFile = "C:\Temp\AppVolReport.xlsx"
)

Get-Module -Name *appvolumes* -ListAvailable | Import-Module

## Gather AppStack Info
Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show('Please Enter your credentials to connect to AppVolumes in the format of DOMAIN\USER')
Connect-AppVolumes -server $AppVolMGR
$AppStackNames = (Get-AppVolumes).Name
$AppStackIDs = (Get-AppVolumes).ID
$AppStackDateCreated = (Get-AppVolumes).Created_At_Human
$AppStackDS = (Get-AppVolumes).datastore_name
$AppStackStatus = (Get-AppVolumes).status
$Applications = Get-AppVolumesApps
$ApplicationIDs = (Get-AppVolumesApps).id
$ApplicationNames = (Get-AppVolumesApps).Name
$AppStackOS = @()
$AppStackDescription = @()
$AppStackUserAssignments = @()
$AppStackGroupAssignments = @()
$ApplicationVersions = @()
$ApplicationAppStack = @()
foreach ($AppID in $AppStackIDs){
    $AppstackOS += (Get-AppVolumeDetails -AppID $AppID).primordial_os_name
            if ((Get-AppVolumeDetails -AppID $AppID).description -ne $null){$AppStackDescription += (Get-AppVolumeDetails -AppID $AppID).description}else{$AppStackDescription += "N/A"}
    [string]$UserAssignments = Get-AppVolumesCurrentAssignments | Where-Object {($_.snapvol_id -Match $AppID) -and ($_.entityt -Match 'User')} | select -ExpandProperty entity_upn
    [string]$GroupAssignments = Get-AppVolumesCurrentAssignments | Where-Object {($_.snapvol_id -Match $AppID) -and ($_.entityt -Match 'Group')} | select -ExpandProperty entity_upn
    if ($UserAssignments -ne $null){$AppStackUserAssignments += $UserAssignments}else{$AppStackUserAssignments += "N/A"}
    if ($GroupAssignments -ne $null){$AppStackGroupAssignemnts += $GroupAssignments}else{$AppStackGroupAssignments += "N/A"}     
     
}
foreach ($Application in $Applications){
    if ($Application.version -ne $null){$ApplicationVersions += $Application.version}else{$ApplicationVersions += 'N/A'}
    $StackID = Select-String -InputObject $Application.snapvol -Pattern "Appstacks/(\d+)" | % {$_.Matches.Groups[1].Value}
    $ApplicationAppStackName = (Get-AppVolumeDetails -AppID $StackID).Name
    $ApplicationAppStack += $ApplicationAppStackName
}


## Initialize Workbook and sheets. Also set names
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $true
$Workbook = $Excel.Workbooks.Add()
$Workbook.Worksheets.Add()
$WS1 = $Workbook.Worksheets.Item(1)
$WS1.Name = 'AppStacks + Groups'
$WS2 = $Excel.Worksheets.Item(2)
$WS2.Name = 'Application Versions'

## Add Column Titles to Worksheets   
$Row = 1
$Column = 1
$WS1.Cells.Item($Row,$Column) = 'AppStack Names'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 2
$WS1.Cells.Item($Row,$Column) = 'Date Created'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 3
$WS1.Cells.Item($Row,$Column) = 'Datastore Name'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 4
$WS1.Cells.Item($Row,$Column) = 'User Assignments'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 5
$WS1.Cells.Item($Row,$Column) = 'Group Assignments'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 6
$WS1.Cells.Item($Row,$Column) = 'Compatible OS'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 7
$WS1.Cells.Item($Row,$Column) = 'Status'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true

$Row = 1
$Column = 1
$WS2.Cells.Item($Row,$Column) = 'Application Name'
$WS2.Cells.Item($Row,$Column).Font.Size = 14
$WS2.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 2
$WS2.Cells.Item($Row,$Column) = 'Application Version'
$WS2.Cells.Item($Row,$Column).Font.Size = 14
$WS2.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 3
$WS2.Cells.Item($Row,$Column) = 'Application AppStack'
$WS2.Cells.Item($Row,$Column).Font.Size = 14
$WS2.Cells.Item($Row,$Column).Font.Bold = $true

## Add Date to Excel Worksheet
$r = 2
for ($i = 0;$i -lt $AppStackNames.Count; $i++){
    $WS1.Cells.Item($r,1) = $AppStackNames[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $AppStackNames.Count; $i++){
    $WS1.Cells.Item($r,2) = $AppStackDateCreated[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $AppStackNames.Count; $i++){
    $WS1.Cells.Item($r,3) = $AppStackDS[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $AppStackNames.Count; $i++){
    $WS1.Cells.Item($r,4) = $AppStackUserAssignments[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $AppStackNames.Count; $i++){
    $WS1.Cells.Item($r,5) = $AppStackGroupAssignments[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $AppStackNames.Count; $i++){
    $WS1.Cells.Item($r,6) = $AppStackOS[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $AppStackNames.Count; $i++){
    $WS1.Cells.Item($r,7) = $AppStackStatus[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $applicationNames.Count; $i++){
    $WS2.Cells.Item($r,1) = $applicationNames[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $applicationNames.Count; $i++){
    $WS2.Cells.Item($r,2) = $ApplicationVersions[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $applicationNames.Count; $i++){
    $WS2.Cells.Item($r,3) = $ApplicationAppStack[$i]
    $r++
}

## Format Excel file. Keep at end
$WS1usedRange = $WS1.UsedRange
$WS1usedRange.EntireColumn.AutoFit() | Out-Null
$WS2usedRange = $WS2.UsedRange
$WS2usedRange.EntireColumn.AutoFit() | Out-Null

$Workbook.SaveAs($OutputFile)
$Workbook.Close
$Excel.DisplayAlerts = 'False'
$Excel.Quit()

Write-Host "$OutputFile created successfully"
Read-Host -Prompt "Press Enter to Exit!"
Exit 0