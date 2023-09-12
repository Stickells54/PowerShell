Start-Transcript C:\Temp\AgentUnreachable.log
Import-Module -Name VMware.Hv.Helper
Import-Module -Name VMware.VimAutomation.HorizonView
# set Variables
$HZCON = ""
$UnwantedVMs = New-Object System.Collections.ArrayList
#Connect to Horizon
Connect-HVServer -Server $HZCON -User "" -Password '' -Domain USA
#Get all IC Pools
$IC_Pools = (Get-HVPool -PoolType AUTOMATED | ? {	$_.Source -eq "INSTANT_CLONE_ENGINE" }).base.name
$ErrorStates = @('ERROR' , 'AGENT_UNREACHABLE', 'AGENT_CONFIG_ERROR', 'AGENT_ERR_DISABLED', 'AGENT_ERR_DOMAIN_FAILURE', 'AGENT_ERR_INVALID_IP', 'AGENT_ERR_NEED_REBOOT', 'ALREADY_USED')
#Get all desktops in each state of for each pool
foreach ($VDIPOOL in $IC_Pools){

$GEStatus = (Get-HVPool -PoolName $VDIPOOL).GLobalentitlementData.GLobalEntitlement 

if ($GEStatus -ne $Null){
    foreach ($State in $ErrorStates){
        Write-Host "Checking for VMs in ErrorState $State inside of pool $VDIPOOL"
    	$ProblemVMs = (Get-HVMachineSummary -State $State -PoolName $VDIPOOL).base.name
        if ($null -ne $ProblemVMs){Remove-HVMachine -MachineNames $ProblemVMs -DeleteFromDisk -Confirm:$false}
    }
    }else{Write-Host "$VDIPOOL is not in USPS NEXT GE"}
}

