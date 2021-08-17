<#	
	.NOTES
	===========================================================================
	 Created on:   	8/17/2021 1:04 PM
	 Created by:   	Travis Stickells	
	 Filename:     	PW_Encryptor.ps1
	===========================================================================
	.DESCRIPTION
		Creates a text file of the encrypted version of your passwords. Use this to create password files that you can load into automation scripts. 
		Example you would add to a script: 
		$User = 'user'
		$EncrypedPassword = Get-Content $OutFile | ConvertTo-SecureString
		$ScriptCred = New-Object System.Management.Automation.PsCredential($User, $EncryptedPassword)
)
	.PARAMETER Credential
		Prompts you for the credentials you need to encrypt and export

	.PARAMETER OutFile
		Name of the file you want to export the encrypted password file to. 
#>

param (
	$Credential,
	[Parameter(Mandatory = $true)]
	$OutFile = 'C:\Temp\PW_ENCRYPTED.txt'
)

if (!$Credential)
{
	$Credential = (Get-Credential)
}

try
{
	Write-Host "Creating Encrypted Password file..."
	$Credential.Password | ConvertFrom-SecureString | Set-Content $OutFile
	Write-Host "$OutFile Created..."
}
catch
{
	Write-Error "Unable to create $OutFile. Check directory permissions..."
}

Read-Host -Prompt "Press any key to exit..." 