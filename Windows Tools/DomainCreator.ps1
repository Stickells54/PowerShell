## Fill out to your needs. This is for quick domain contoller creation for temporary lab use.
$DomainName = "Test.local"
$AdminPass = "VMware1!@#!@#"

$AdminPass = ConvertTo-SecureString -String $AdminPass -AsPlainText -Force
Add-WindowsFeature AD-Domain-Services
ADD-WindowsFeature RSAT-Role-Tools
Install-ADDSForest -DomainName $DomainName -InstallDNS -SafeModeAdministratorPassword $AdminPass -Confirm:$false