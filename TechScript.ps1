<#
	This script was made to make some tasks easier. It is also a first time implementation. The main purpose
for writing this script was to get familiar with functions and calling functions based on input in powershell.
There are probably bugs and some stuff isnt gonna always work, but you cant learn unless you break some shit.
Nobody will ever read this, but it is a note to my future self to see how much better my posh scripts will be 
in the next 5 years. Script will be updated when I get the urge to learn something new in posh. One day, I
will rewrite the entire thing in a .NET language (probably C#) and build a gui to make it easier. 

Travis Stickells
#>


################################################################################################
#####################  FUNCTION DEFINITIONS  ###################################################
################################################################################################
function LoggedInUser
{
	$computername = Read-Host -Prompt "Enter PC Name: "
	
	query user /server:$computername
	
}

function ExistingUser
{
	$Name = Read-Host -Prompt "Enter User ID: "
	$User = Get-ADUser -LDAPFilter "(sAMAccountName=$Name)"
	If ($User -eq $Null) { "User does not exist in AD" }
	Else { "User found in AD" }
}

function AddVDIDesktop
{
	$AddUser = Read-Host -Prompt "Badge ID of user: "
	Add-ADGroupMember -Identity DP_Clinical -Members $AddUser -Confirm:$false
	$members = Get-ADGroupMember -Identity DP_Clinical -Recursive | Select -ExpandProperty SamAccountName
	
	If ($members -contains $Adduser)
	{
		Write-Host "$AddUser now has VDI and SSO Access."
	}
	Else
	{
		Write-Host "$AddUser still does not have access. Something went wrong."
	}
}

function CheckCitrix
{
	
	$user = Read-Host -Prompt "Badge ID of user: "
	$groups = 'Apps_Clinical'
	
	foreach ($group in $groups)
	{
		$members = Get-ADGroupMember -Identity $group -Recursive | Select -ExpandProperty SamAccountName
		
		If ($members -contains $user)
		{
			Write-Host "$user has Citrix Access. You can revoke access using the other menu prompt."
		}
		Else
		{
			Write-Host "$user Does not have Citrix Access. You can add access using the other menu prompts"
		}
	}
	
}

function AddToCitrix
{
	$AddUser = Read-Host -Prompt "Badge ID of user: "
	Add-ADGroupMember -Identity Apps_Clinical -Members $AddUser -Confirm:$false
	
	$members = Get-ADGroupMember -Identity Apps_Clinical -Recursive | Select -ExpandProperty SamAccountName
	
	If ($members -contains $Adduser)
	{
		Write-Host "$AddUser now has Citrix Access."
	}
	Else
	{
		Write-Host "$AddUser still does not have access. Wait 60 seconds and check using option 2."
	}
}

function RemoveCitrix
{
	
	$user = Read-Host -Prompt "Enter User ID: "
	
	Remove-ADGroupMember -Identity Apps_Clinical -Members $user -Confirm:$false
	
	$members = Get-ADGroupMember -Identity Apps_Clinical -Recursive | Select -ExpandProperty SamAccountName
	
	If ($members -contains $user)
	{
		Write-Host "$User still has Citrix access."
	}
	Else
	{
		Write-Host "$User has had Citrix access revoked."
	}
}

function AddNewUser
{
	Write-Host
	Write-Host
	#Getting variable for the First Name
	$firstname = Read-Host "Enter in the First Name"
	Write-Host
	#Getting variable for the Last Name
	$lastname = Read-Host "Enter in the Last Name"
	Write-Host
	#Setting Full Name (Display Name) to the users first and last name
	$fullname = "$firstname $lastname"
	Write-Host
	#Setting the employee ID. 
	$empID = Read-Host "Enter in the Employee ID"
	#Setting username to badge ID. 
	$logonname = $empID
	#Setting the Path for the OU.
	$OU = "OU=Standard,OU=IMC-Users,DC=IberiaMC,DC=local"
	#Setting the variable for the domain.
	$domain = $env:userdnsdomain
	#Setting the variable for the description.
	$Description = Read-Host "Enter in the User Description"
	
	
	cls
	#Displaying Account information.
	Write-Host "======================================="
	Write-Host
	Write-Host "Firstname:      $firstname"
	Write-Host "Lastname:       $lastname"
	Write-Host "Display name:   $fullname"
	Write-Host "Logon name:     $logonname"
	
	#Checking to see if user account already exists.  If it does it
	#will append the next letter of the first name to the username.
	DO
	{
		If ($(Get-ADUser -Filter { SamAccountName -eq $logonname }))
		{
			Write-Host "WARNING: Logon name" $logonname.toUpper() "already exists!!" -ForegroundColor:Green
			Write-Host
			Write-Host
			Write-Host
			$taken = $true
			sleep 5
			return 
		}
		else
		{
			$taken = $false
		}
	}
	Until ($taken -eq $false)
	
	cls
	#Displaying account information that is going to be used.
	Write-Host "======================================="
	Write-Host
	Write-Host "Firstname:      $firstname"
	Write-Host "Lastname:       $lastname"
	Write-Host "Display name:   $fullname"
	Write-Host "Logon name:     $logonname"
	
	#Setting minimum password length to 12 characters and adding password complexity.
	$PasswordLength = 8
	
	Do
	{
		Write-Host
		$isGood = 0
		$Password = Read-Host "Enter in the Password" -AsSecureString
		$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
		$Complexity = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
		
		if ($Complexity.Length -ge $PasswordLength)
		{
			Write-Host
		}
		else
		{
			Write-Host "Password needs $PasswordLength or more Characters" -ForegroundColor:Green
		}
		
		if ($Complexity -match "[^a-zA-Z0-9]")
		{
			$isGood++
		}
		else
		{
			Write-Host "Password does not contain Special Characters." -ForegroundColor:Green
		}
		
		if ($Complexity -match "[0-9]")
		{
			$isGood++
		}
		else
		{
			Write-Host "Password does not contain Numbers." -ForegroundColor:Green
		}
		
		if ($Complexity -cmatch "[a-z]")
		{
			$isGood++
		}
		else
		{
			Write-Host "Password does not contain Lowercase letters." -ForegroundColor:Green
		}
		
		if ($Complexity -cmatch "[A-Z]")
		{
			$isGood++
		}
		else
		{
			Write-Host "Password does not contain Uppercase letters." -ForegroundColor:Green
		}
		
	}
	Until ($password.Length -ge $PasswordLength -and $isGood -ge 3)
	
	
	Write-Host
	Read-Host "Press Enter to Continue Creating the Account"
	Write-Host "Creating Active Directory user account now" -ForegroundColor:Green
	
	#Creating user account with the information you inputted.
	New-ADUser -Name $fullname -GivenName $firstname -Surname $lastname -DisplayName $fullname -SamAccountName $logonname -UserPrincipalName $logonname@$Domain -AccountPassword $password -Enabled $true -Path $OU -Description $Description -Confirm:$false
	
	sleep 2
	
	
	Write-Host
	
	$ADProperties = Get-ADUser $logonname -Properties *
	
	Sleep 3
	
	cls
	
	Write-Host "========================================================"
	Write-Host "The account was created with the following properties:"
	Write-Host
	Write-Host "Firstname:      $firstname"
	Write-Host "Lastname:       $lastname"
	Write-Host "Display name:   $fullname"
	Write-Host "Logon name:     $logonname"
	Write-Host
	Write-Host
	
	$AddUsertoCitrix = Read-Host -Prompt "Add user to Citrix? (Y,N): "
	if ($AddUsertoCitrix -eq 'Y') { AddToCitrix }
	Else {"All done!"}
}

function FixCPSI
{
	
	$computername = Read-Host -Prompt "Name of PC: "
	
	Copy-Item -Path \\hv-uemshare\UEMConfig\Scripts\thrive_connections.cfg -Destination \\$computername\c$\Users\$env:USERNAME\cpsi 
	
	Write-Host "Have the user restart CPSI"
}

function Show-Menu
{
	param (
		[string]$Title = 'Iberia Medical Tech Toolbox'
	)
	cls
	Write-Host "================ $Title ================"
	
	Write-Host "1: Find Logged in user of remote machine"
	Write-Host "2: Check if user has Citrix Access"
	Write-Host "3: Give user Citrix Access"
	Write-Host "4: Revoke user Citrix Access"
	Write-Host "5: Fix Blanked out CPSI"
	Write-Host "6: Add new AD user"
	Write-Host "7: Give user SSO/VDI access"
	Write-Host "8: Check if user already exists in AD"
	Write-Host "Q: Press 'Q' to quit."
}


################################################################################################
#####################  FUNCTION DEFINITIONS  ###################################################
################################################################################################

####### DO LOOP FOR THE MAIN MENU##########
do
{
	Show-Menu
	$input = Read-Host "Please make a selection"
	switch ($input)
	{
		'1' {
			LoggedInUser
		} '2' {
			CheckCitrix
		} '3' {
			AddToCitrix
		} '4' {
			RemoveCitrix
		} '5' {
			FixCPSI
		} '6' {
			AddNewUser
		} '7' {
			AddVDIDesktop
		} '8' {
			ExistingUser
		}'q' {
			exit
		}
	}
	pause
}
until ($input -eq 'q')
