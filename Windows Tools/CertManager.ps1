
<#	
	.NOTES
	===========================================================================
	 Created on:   	8/14/2020 
	 Created by:   	Travis Stickells
	 Filename:     	CertManager.ps1
	===========================================================================
	.DESCRIPTION
	Interactive menu-based certificate management script. You can generate a CSR, multiple CSRs, and manipulate certificates returned from the CSRs.

#>
 param
(
	[parameter(Mandatory = $true)]
	$OU,
	[Parameter(Mandatory = $true)]
	$Org,
	[Parameter(Mandatory = $true)]
	$Country = 'US',
	
)

# First, we need to ddo some "backend" setup like create a menu for the users and define the actual functions in the script
function Show-Menu
{
	param (
		[string]$Title = 'Cert Management Script'
	)
	Clear-Host
	Write-Host "================ $Title ================" -ForegroundColor Green
	
	
	Write-Host "OpenSSL should be in C:\OpenSSL." -ForegroundColor Yellow -BackgroundColor Black
	Write-Host "Press CTRL+C To exit at anytime" -ForegroundColor Yellow -BackgroundColor Black
	Write-Host "1: Press '1' to generate a single CSR"
	Write-Host "2: Press '2' to bulk generate CSR from CSV file. (must use template)"
	Write-Host "3: Press '3' to generate a PFX, PEM, CER, and Key from your CER file"
	Write-Host "4: Press '4' to download a CSV template for bulk importing"
	Write-Host "Q: Press 'Q' to quit"
}

function GenerateSingleCSR
{
	$CSRLocation = Read-Host -Prompt "Enter the path where the CSR should be created   ex. C:\CSR: "
	if (!(Test-Path -Path $CSRLocation))
	{
		New-Item -Path $CSRLocation -ItemType Directory | Out-Null
		Write-Host "Directory created as it did not exist already." -ForegroundColor Green
	}
	$CSRCN = Read-Host -Prompt "Enter the CN (FQDN): "
	$CSRL = Read-Host -Prompt "Enter City: "
	$CSRS = Read-Host -Prompt "Enter State:  "
	Write-Output "CN=$CSRCN,City=$CSRL,State=$CSRS,OU=$OUVDI,O=$Org,C=$Country"
	$CSRCorrect = Read-Host -Prompt "Does this look correct? [y/n]: "
	if ($CSRCorrect -eq "n") { GenerateSingleCSR }
	if ($CSRCorrect -eq "y")
	{
		$INF =
		@"

            [NewRequest]
            Subject = "CN=$($CSRCN), OU=$OUVDI, O=$Org, L=$($CSRL), S=$($CSRS), C=$Country"
            KeySpec = 1
            KeyLength = 2048
            Exportable = TRUE
            SMIME = TRUE
            MachineKeySet = TRUE
            HashAlgorithm = sha256
            PrivateKeyArchive = FALSE
            UserProtected = FALSE
            UseExistingKeySet = FALSE
            RequestType = PKCS10
            KeyUsage = 0xa0

            [EnhancedKeyUsageExtension]

            OID=1.3.6.1.5.5.7.3.1 
"@
		
		$INF | Out-File -FilePath $CSRLocation\inf.inf -Force
		certreq -new $CSRLocation\inf.inf $CSRLocation\CSR.txt
		
		Write-Host "CSR should be available at $CSRLocation\CSR.txt"
	}
	
}

function DownloadCSRTemplate
{
	$SaveLocation = Read-Host -Prompt "Where should the template be saved? ex C:\CSR: "
	if (!(Test-Path -Path $SaveLocation))
	{
		New-Item -Path $SaveLocation -ItemType Directory
		Write-Host "Path Created as it did not already exist." -ForegroundColor Green
	}
	Write-Host "Copying Template to location"
	Invoke-WebRequest -Uri "https://github.com/Stickells54/PowerShell/blob/master/Windows%20Tools/csrtemplate.csv" -OutFile "$SaveLocation\csrtemplate.csv"
	if (!(Test-Path -Path $SaveLocation\csrtemplate.csv)) { Write-Host "Copy failed" }
}

function GenerateBulkCSR
{
	$CSVLocation = Read-Host "Enter path to CSR template ex C:\Csr\csrtemplate.csv: "
	$CSRSAVELOCATION = Read-Host "Enter path where CSRs should be saved: "
	if (!(Test-Path -Path $CSRSAVELOCATION))
	{
		New-Item -Path $CSRSAVELOCATION -ItemType Directory
		Write-Host "Path Created as it did not already exist." -ForegroundColor Green
	}
	$CSRList = Import-Csv $CSVLocation
	foreach ($CSR in $CSRList)
	{
		$Path = "$($CSRSAVELOCATION)\$($CSR.CRTMGT)"
		New-Item -ItemType Directory -Path $Path -Force
		if ($CSR.SAN1 -eq $null)
		{
			$INF =
			@"

            [NewRequest]
            Subject = "CN=$($CSR.CN), OU=$OUVDI, O=$Org, L=$($CSR.City), S=$($CSR.State), C=$Country"
            KeySpec = 1
            KeyLength = 2048
            Exportable = TRUE
            SMIME = TRUE
            PrivateKeyArchive = FALSE
            UserProtected = FALSE
            UseExistingKeySet = FALSE
            RequestType = PKCS10
            KeyUsage = 0xa0

            [EnhancedKeyUsageExtension]

            OID=1.3.6.1.5.5.7.3.1 
"@
			
			$INF | Out-File -FilePath $Path\inf.inf -Force
			certreq -new $path\inf.inf $Path\CSR.txt
		}
		
		if ($CSR.SAN1 -ne $null)
		{
			$INF =
			@"

            [NewRequest]
            Subject = "CN=$($CSR.CN), OU=$OUVDI, O=$Org, L=$($CSR.City), S=$($CSR.State), C=$Country"
            KeySpec = 1
            KeyLength = 2048
            Exportable = TRUE
            SMIME = TRUE
            PrivateKeyArchive = FALSE
            UserProtected = FALSE
            UseExistingKeySet = FALSE
            RequestType = PKCS10
            KeyUsage = 0xa0

            [EnhancedKeyUsageExtension]

            OID=1.3.6.1.5.5.7.3.1 

            [Extensions]
            2.5.29.17 = "{text}"
            _continue_ = "dns=$($CSR.SAN1)&"
                                                _continue_ = "dns=$($CSR.SAN2)"
            
"@
			
			$INF | Out-File -FilePath $Path\inf.inf -Force
			certreq -new $path\inf.inf $Path\CSR.txt
		}
	}
}

function ImportExport
{
	Write-Host "This will attempt to perform the Import/Export function on all certs in the directory you specify. To avoid errors, use a directory that ONLY has the CER files you need." -ForegroundColor Yellow -BackgroundColor Black
	Write-Host "Make sure the format of the CER files are CN.cer. The script uses the filename to determine the CN to perform the Exporting correctly." -ForegroundColor Yellow -BackgroundColor Black
	$CertsLocation = Read-Host -Prompt "Enter the folder where your CRT files are stored i.e C:\CER: "
	$ExportLocation = Read-Host -Prompt "Enter the folder where you want the exported certificates to be created ex C:\Certs\Exported: "
	$PFXPWD = Read-Host -Prompt "Enter a password for the PFX file: "
	$PFXPWDENCRYPT = ConvertTo-SecureString -String $PFXPWD -Force -AsPlainText
	$CertNames = @() #This is an empty array we will use to create a list of CNs that will be used to identify certs for exporting later
	if (!(Test-Path -Path $ExportLocation))
	{
		New-Item -Path $ExportLocation -ItemType Directory
		Write-Host "Directory Created since it did not previously exist" -ForegroundColor Green
	}
	$Certs = (GCI -Path $CertsLocation | ? Name -Like "*.cer").Name
	Write-Host  "Importing Certs..."
	foreach ($Cert in $Certs)
	{
		Import-Certificate -CertStoreLocation Cert:\LocalMachine\My\ -FilePath $CertsLocation\$Cert | Out-Null
		$CN = $Cert.Substring(0, $Cert.length - 4)
		$CertNames = $CertNames + $CN
	}
	Write-Host "Certs Imported. Beginning Export Process.."
	#This part is convulated kind of, so I will try and explain as I go
	
	foreach ($Cert in $CertNames)
	{
		$CERTTP = (dir Cert:\LocalMachine\My\ -Recurse | ? Subject -Like "*CN=$($Cert)*").Thumbprint | Out-Null ### This finds the certificate in the Personal Directory that has a CN matching that if the CN provided in the CertNames array. This is a foreach loop so it does this for each cert in the array   
		New-Item -Path $ExportLocation\$Cert -ItemType Directory -Force | Out-Null ## Create a folder in the directory provided with the CN of each cert. This is where the PFX files will be stored.
		Get-ChildItem -Path Cert:\LocalMachine\my\$($CERTTP) | Export-PfxCertificate -Password $PFXPWDENCRYPT -FilePath $ExportLocation\$Cert\$Cert.pfx | Out-Null ## Export the cert we installed earlier in the function to a PFX with the password given by the user
	}
	## Check if OpenSSL is in the correct directory of C:\OpenSSL. Copies it to the machine if now
	$OpenSSLTest = Test-Path -Path C:\OpenSSL
	if ($OpenSSLTest -eq $false)
	{
		New-Item -Path C:\OpenSSL -ItemType Directory
		Copy-Item -Path "\\rlghncsxvum3.devsub.dev.dce.usps.gov\team_vdi\Certificate Repository\OpenSSL\*" -Recurse -Destination C:\OpenSSL
	}
	#Run OpenSSL Command to generate PEM,CER, and KEY files from PFX
	foreach ($pfxcert in $CertNames)
	{
		$Cert = "$ExportLocation\$pfxcert\$pfxcert.pfx"
		#Convert PFX to PEM
		Start-Process -FilePath C:\OpenSSL\openssl.exe -ArgumentList "pkcs12 -in $Cert -passin pass:$PFXPWD -out $ExportLocation\$pfxcert\$pfxcert.pem -nodes" -NoNewWindow
		#Convert PFX to CRT wihtout key
		Start-Process -FilePath C:\OpenSSL\openssl.exe -ArgumentList "pkcs12 -in $Cert -passin pass:$PFXPWD -out $ExportLocation\$pfxcert\$pfxcert.crt -nokeys" -NoNewWindow
		#Convert existing PEM to Key file
		Start-Process -FilePath C:\OpenSSL\openssl.exe -ArgumentList "rsa -in $ExportLocation\$pfxcert\$pfxcert.pem -out $ExportLocation\$pfxcert\$pfxcert.key -nodes" -NoNewWindow
	}
}

do
{
	Show-Menu
	$selection = Read-Host "Please make a selection:  "
	switch ($selection)
	{
		'1' {
			GenerateSingleCSR
		} '2' {
			GenerateBulkCSR
		} '3' {
			ImportExport
		} '4' {
			DownloadCSRTemplate
		}
	}
	pause
}
until ($selection -eq 'q')
