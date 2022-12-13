# @Author                Ungureanu Ovidiu
# @Date                  12/12/2022
# @Domain                domain.example
# @Version               2.0
# @Last Update           13/12/2022
# @Email for questions   ovidiu.ungureanucostin@gmail.com

# This script can be used to discovery all the required data from
# computers in Active Directory domain, using GPO. I added this script
# to be executed at user logon.
# Result: each user that has low permissions, is writing to a shared path
# the data, in a different file. So, there are generated many CSV files to avoid
# race conditions.
# In the future I am gonna upload a script to concatenate those files.





###############################################################################
######################## Global variables #####################################
###############################################################################
# Windows path to user profiles to get authenticated users on each device
$string_PathUsers = "C:\Users"
# List to exclude certain accounts from list, like administrator accounts
[string[]]$adminsSAMAccountnames = @("admin", "root", "admin2", "toor")





###############################################################################
############################ Code zone ########################################
###############################################################################
# Get user profiles as strings
$array_UsersProfile = (Get-ChildItem -Path $string_PathUsers -Exclude $adminsSAMAccountnames | select Name)

# Get device informations like SerialNumber, Computer Name
$string_SerialNumber = Get-WmiObject win32_bios | select SerialNumber
$string_ComputerName = Get-WmiObject win32_bios | select PSComputerName

# Get device IP
$string_IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | Out-String -stream | Select-String -Pattern 10.).ToString() -replace "IPAddress         : "    -replace ""

# User profile name(login username) to real name as a String Array
[string]$string_Users = ""
Foreach ($user in ($array_UsersProfile).Name){
    $temp = (Get-ADUser -Filter 'SamAccountName -eq $user' | Select Name).Name
	$string_Users = $string_Users + "," + $temp
}





###############################################################################
############################ Export CSV #######################################
###############################################################################
# Path to export file
$pathExport = "\\dc\Public\DiscoveryFolder\"

# Check is path exists, if not, create it
if(Test-Path $pathExport){
	# Do nothing
}else{
	# Create path
	New-Item $pathExport -ItemType Directory
	$pathExport = $pathExport + ($string_ComputerName).PSComputerName + ".csv"
}

$var = $pathExport + ($string_ComputerName).PSComputerName + ".csv"

# Create custom object to export to CSV file
$customObjectEntry = [PSCustomObject]@{
    SerialNumber = ($string_SerialNumber).SerialNumber
    ComputerName = ($string_ComputerName).PSComputerName
    IPAddress    = $string_IPAddress
    UsersHistory = $string_Users
} | Export-Csv -Path $var
