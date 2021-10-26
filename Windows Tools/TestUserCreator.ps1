$NumberofUsers = 10
$UserFirstName = "Test"
$UserLastName = "User"
$UserAccountName = "tstusr"
$Password = "VMw@r31!"
for($i=0;$i -lt $NumberofUsers; $i++){ New-ADUser -AccountPassword $Password -Confirm $false -PasswordNeverExpires $true -GivenName $UserFirstName + $i -Surname $UserLastName -SamAccountName $UserFirstName + $i -DisplayName $UserFirstName + $i + " " + $UserLastName -Enabled $true}