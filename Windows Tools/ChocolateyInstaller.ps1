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