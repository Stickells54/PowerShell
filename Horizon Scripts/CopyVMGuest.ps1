# Requires: VMware PowerCLI

# CONFIGURATION
$esxiHost     = "192.168.1.100"       # IP or hostname of your ESXi host
$esxiUser     = "root"                # ESXi username
$esxiPassword = "yourEsxiPassword"   # ESXi password
$linuxVMName  = "UbuntuServer01"     # Name of the Linux VM
$guestFile    = "/home/user/myfile.txt"   # Full path to file inside Linux VM
$localPath    = "C:\Temp\myfile.txt"      # Destination on your Windows machine

# Connect to ESXi host
Write-Host "`nConnecting to ESXi host $esxiHost..." -ForegroundColor Cyan
Connect-VIServer -Server $esxiHost -User $esxiUser -Password $esxiPassword | Out-Null

# Get guest credentials
Write-Host "`nEnter credentials for the Linux guest VM:" -ForegroundColor Cyan
$linuxCred = Get-Credential

# Confirm the VM exists
$vm = Get-VM -Name $linuxVMName
if (-not $vm) {
    Write-Host "VM '$linuxVMName' not found on host!" -ForegroundColor Red
    exit 1
}

# Copy file from Linux VM to local Windows machine
Write-Host "`nCopying file from Linux VM to Windows machine..." -ForegroundColor Cyan
Copy-VMGuestFile -VM $vm `
    -Source $guestFile `
    -Destination $localPath `
    -LocalToGuest:$false `
    -GuestUser $linuxCred.UserName `
    -GuestPassword $linuxCred.GetNetworkCredential().Password

Write-Host "File copied successfully to $localPath" -ForegroundColor Green

# Disconnect from ESXi host
Disconnect-VIServer -Server $esxiHost -Confirm:$false | Out-Null
