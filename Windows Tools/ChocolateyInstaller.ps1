<#	
	.NOTES
	===========================================================================
	 Created on:   	12/15/20
	 Created by:   	Travis Stickells
	 Filename:     	ChocolateyInstaller.ps1
	===========================================================================
	.DESCRIPTION
	Installs chocolatey on multiple systems at once. 

    .PARAMETER ComputerList
        Array of windows servers or workstations that you want to install Chocolatey on

    .PARAMETER Creds
        Credentials that have admin rights on the remote systems
    
    .PARAMETER LogLocation
        Absolute path to log file. 
#>

param (
    [Parameter (Mandatory = $true)]
    $ComputerList = @(),
    [Parameter(Mandatory = $true)]
    [SecureString] $Creds = (Get-Credential),
    $LogLocation = "C:\Temp\ChocoInstall.log"
)

#Log script output
Start-Transcript -Path $LogLocation

foreach ($Computer in $ComputerList){
    Write-Host "Installing Chocolatey to $computer..."
    try{
    Invoke-Command -ComputerName $Computer -Credential $Creds -ScriptBlock {Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))}
    }catch{Write-Output "Error invoking install command on $Computer"}
}