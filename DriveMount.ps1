## Create PSDrive to network share containing Install Scripts and POSH Modules
$User = "server\user"
$Pass = ConvertTo-SecureString -String 'password' -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
Try
{
	New-PSDrive -Name "V" -Root "\\server\share" -PSProvider "FileSystem" -Credential $Credential
}
Catch { Write-Output "V Drive failed to mount" }

