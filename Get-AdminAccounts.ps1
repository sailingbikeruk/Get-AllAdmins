Import-Module Activedirectory

# Get Domains
$ChildDomains = (Get-ADForest).domains
$ForestDomain = (Get-AdForest).Name

# Declare Variables
$ForestPrivGroups = "Enterprise Admins", "Schema Admins"
$DomainPrivGroups = "Administrators", "Account Operators", "Server Operators", "Backup Operators", "Domain Admins"
$Members = @()
$colMembers = @()
$FullDetails = @()
$Domain = (Get-AdForest).Name
$Filepath = "E:\Scripts\Ian\CSV\AllPrivUsers.csv " # Change this to suit your needs.

# =============== Do the Forest Privileged Groups First ================
foreach ($group in $ForestPrivGroups) 
{
    $Members = @() 
    Write-Host "Enumerating $Group" -foreground Blue        
    $Members = Get-ADGroupMember $Group -server $ForestDomain -Recursive         
    $Count = $Members.count                
    Write-Host "Found $count members in $Group"        
    
    foreach ($member in $Members) {            
        $MembersDetails = get-aduser $member -properties * | Select-Object DisplayName, Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires, SamAccountName, UserPrincipalName, Description, @{Name = 'PasswordAge'; Expression = { ((Get-Date) - $_.PasswordLastSet).Days } }                      

# Build a custom object to hold the user details as well as the forest domain and group name
        $FullDetails = [PSCustomObject]@{
            DisplayName = $MembersDetails.DisplayName
            Enabled = $MembersDetails.Enabled
            LastLogonDate = $MembersDetails.LastLogonDate
            PasswordAge = $MembersDetails.PasswordAge
            PasswordLastSet = $MembersDetails.PasswordLastSet
            PasswordNeverExpires = $MembersDetails.PasswordNeverExpires
            SamAccountName = $MembersDetails.SamAccountName
            UserPrincipalName = $MembersDetails.UserPrincipalName
            Description = $MembersDetails.Description
            Domain = $ForestDomain
            Group = $Group
        }
        $colMembers += $FullDetails 
    }
}
# ====================== Iterate through each child domain ==================================
foreach ($Domain in $ChildDomains) {
    Write-Host "Enumerating Groups in $Domain" -ForegroundColor Yellow
    foreach ($Group in $DomainPrivGroups) {
        $Members = @()
        $PDCEmulator = get-addomain -Identity $Domain | Select -expandproperty pdcemulator
        Write-Host "Enumerating $Group" -foreground Blue
        $Members = Get-ADGroupMember $Group -server $PDCEmulator -Recursive 
        $Count = $Members.count        
        Write-Host "Found $count members in $Group"
        foreach ($member in $Members) {
            $MembersDetails = get-aduser $member -properties * | Select-Object DisplayName, Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires, SamAccountName, UserPrincipalName, Description, @{Name = 'PasswordAge'; Expression = { ((Get-Date) - $_.PasswordLastSet).Days } }          

# Build a custom object to hold the user details as well as the child domain and group name
            $FullDetails = [PSCustomObject]@{
                DisplayName          = $MembersDetails.DisplayName
                Enabled              = $MembersDetails.Enabled
                LastLogonDate        = $MembersDetails.LastLogonDate
                PasswordAge          = $MembersDetails.PasswordAge
                PasswordLastSet      = $MembersDetails.PasswordLastSet
                PasswordNeverExpires = $MembersDetails.PasswordNeverExpires
                SamAccountName       = $MembersDetails.SamAccountName
                UserPrincipalName    = $MembersDetails.UserPrincipalName
                Description          = $MembersDetails.Description
                Domain               = $Domain
                Group                = $Group
            }
            $colMembers += $FullDetails 
        }

    }
}
write-host "`n`nwriting CSV file to E:\Scripts\Ian\CSV\PrivUsers\AllPrivUsers.csv " -ForegroundColor Green
$colMembers | export-csv -Path $Filepath -NoTypeInformation




