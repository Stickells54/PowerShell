<#	
	.NOTES
	===========================================================================
	 Created on:   	3/24/2021 
	 Created by:   	Travis Stickells
	 Filename:     	HorizonReport.ps1
	===========================================================================
	.DESCRIPTION
	Creates a detailed report of Horizon KPIs. 

	.Parameter HZCon
	IP or Hostname of the Horizon Connection Server
	
	.Parameter OutputFile
	Absolute path to the XLSX file that will be generated

	.PARAMETER Cred
	Credentials used to authenticate in the Connection servers.
#>
param
(
	[parameter(Mandatory = $true)]
	$HZCon,
	$OutputFile = "C:\Temp\HorizonReport.xlsx",
	$Cred = (Get-Credential),
)

## Horizon Reporting Script
Import-Module -Name VMware.Hv.Helper
Import-Module -Name VMware.VimAutomation.Core

$User = $Cred.UserName
$Password = $Cred.GetNetworkCredential().Password

Connect-HVServer -Server $HZCon -User $User -Password $Password
$Pools = (Get-HVPool).Base.Name
$Descriptions = (Get-HVPool).Base.Description
$EnabledStatus = (Get-HVPool).DesktopSettings.Enabled
$DesktopSourceType =  (Get-HVPool).Source
$DesktopCluster = (Get-HVPool).AutomatedDesktopData.VirtualCenterNamesData.HostorClusterPath
$ClusterNames = @()
$PoolDescriptions = @()
$DesktopType = @()
$PoolsUserEntitlements = @()
$PoolsGroupEntitlements = @()
foreach ($Description in $Descriptions) {
    if($Description -eq $null){$PoolDescriptions += "NONE"}else {$PoolDescriptions += $Description}
}
foreach ($Cluster in $DesktopCluster) {
    $Split = $Cluster.split('/')
    $Cluster = $Split[3]
    $ClusterNames += $Cluster
}
foreach ($DesktopSRCType in $DesktopSourceType){
        if($DesktopSRCType -eq 'INSTANT_CLONE_ENGINE'){$DesktopType += 'Instant Clones'}
        if($DesktopSRCType -eq 'VIEW_COMPOSER'){$DesktopType += 'Linked Clones'}       
        if($DesktopSRCType -eq 'VIRTUAL_CENTER'){$DesktopType += 'Static Desktops'}
    }
foreach ($Pool in $Pools) {
    [string]$PoolUserEntitlements = (Get-HVEntitlement -Type User -ResourceName $Pool -ResourceType Desktop).base.loginname
    [string]$PoolGroupEntitlements = (Get-HVEntitlement -Type Group -ResourceName $Pool -ResourceType Desktop).base.loginname
    if($PoolUserEntitlements -eq $null){$PoolsUserEntitlements += "NONE"}else {$PoolsUserEntitlements += $PoolUserEntitlements}
    if($PoolGroupEntitlements -eq $null){$PoolsGroupEntitlements += "NONE"}else {$PoolsGroupEntitlements += $PoolGroupEntitlements}
}

## Initialize Workbook and sheets. Also set names
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $true
$Workbook = $Excel.Workbooks.Add()
$WS1 = $Workbook.Worksheets.Item(1)
$WS1.Name = 'Horizon Pool Info'

## Add Column Titles to Worksheets   
$Row = 1
$Column = 1
$WS1.Cells.Item($Row,$Column) = 'Pool Names'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 2
$WS1.Cells.Item($Row,$Column) = 'Pool Description'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 3
$WS1.Cells.Item($Row,$Column) = 'Pool Enabled Status'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 4
$WS1.Cells.Item($Row,$Column) = 'Pool Type'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 5
$WS1.Cells.Item($Row,$Column) = 'vCenter Cluster'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 6
$WS1.Cells.Item($Row,$Column) = 'User Entitlements'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true
$Row = 1
$Column = 7
$WS1.Cells.Item($Row,$Column) = 'Group Entitlements'
$WS1.Cells.Item($Row,$Column).Font.Size = 14
$WS1.Cells.Item($Row,$Column).Font.Bold = $true

## Populate the data
$r = 2
for ($i = 0;$i -lt $Pools.Count; $i++){
    $WS1.Cells.Item($r,1) = $Pools[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $Pools.Count; $i++){
    $WS1.Cells.Item($r,2) = $PoolDescriptions[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $Pools.Count; $i++){
    $WS1.Cells.Item($r,3) = $EnabledStatus[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $Pools.Count; $i++){
    $WS1.Cells.Item($r,4) = $DesktopType[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $Pools.Count; $i++){
    $WS1.Cells.Item($r,5) = $ClusterNames[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $PoolsUserEntitlements.Count; $i++){
    $WS1.Cells.Item($r,6) = $PoolsUserEntitlements[$i]
    $r++
}
$r = 2
for ($i = 0;$i -lt $PoolsGroupEntitlements.Count; $i++){
    $WS1.Cells.Item($r,7) = $PoolsGroupEntitlements[$i]
    $r++
}
## Format Excel file. Keep at end
$WS1usedRange = $WS1.UsedRange
$WS1usedRange.EntireColumn.AutoFit() | Out-Null
$Workbook.SaveAs($OutputFile)
$Workbook.Close
$Excel.DisplayAlerts = 'False'
$Excel.Quit()
