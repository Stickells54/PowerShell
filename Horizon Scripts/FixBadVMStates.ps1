param(
    [parameter(Mandatory=$true)]
    $ConnectionServer,
    [parameter(Mandatory=$true)]
    $User,
    [parameter(Mandatory=$true)]
    $Password,
    [parameter(Mandatory=$true)]
    $Domain

)
Start-Transcript C:\Temp\BadVMCleanup.log -UseMinimalHeader 
Import-Module -Name VMware.Hv.Helper
Import-Module -Name VMware.VimAutomation.HorizonView
#Initialize Array
$UnwantedVMs = New-Object System.Collections.ArrayList
#Set Error States we are monitoring for
$ErrorStates = @('ERROR' , 'AGENT_UNREACHABLE', 'AGENT_CONFIG_ERROR', 'AGENT_ERR_DISABLED', 'AGENT_ERR_DOMAIN_FAILURE', 'AGENT_ERR_INVALID_IP', 'AGENT_ERR_NEED_REBOOT', 'ALREADY_USED')
#Connect to Horizon
Connect-HVServer -Server $HZCON -User $User -Password  $Password  -Domain $Domain
#Get all IC Pools
$IC_Pools = (Get-HVPool -PoolType AUTOMATED | ? {	$_.Source -eq "INSTANT_CLONE_ENGINE" }).base.name
#Get all desktops in each state of for each pool
foreach ($VDIPOOL in $IC_Pools){
    foreach ($State in $ErrorStates){
     Write-Host "Checking for VMs in ErrorState $State inside of pool $VDIPOOL"
     $ProblemVMs = (Get-HVMachineSummary -State $State -PoolName $VDIPOOL).base.name
     if ($null -ne $ProblemVMs){Remove-HVMachine -MachineNames $ProblemVMs -DeleteFromDisk -Confirm:$false}  
}

