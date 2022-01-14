$ComputerList = @()
$Creds = (Get-Credential)

foreach ($Computer in $ComputerList){
    Write-Host "Connecting to $computer..."
    Enter-PSSession -ComputerName $Computer -Credential $Creds
    Write-Host "Connected to $computer.. Installing Chocolatey"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Start-Sleep 5
    Exit-PSSession
    Write-Host "Chocolatey Installed on $computer"
}