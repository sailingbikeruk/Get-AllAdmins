Import-Module Activedirectory

# Lines below are interchanged for operation or testing - Get-ADForest is used in normal operation, the manual config is used in testing
$Domains = (Get-ADforest).domains

# Declare Variables
$ForestPrivGroups = "Enterprise Admins", "Schema Admins"
$DomainPrivGroups = "Administrators", "Account Operators", "Server Operators", "Backup Operators", "Domain Admins"
$Members = @()
$MemberDetails = @()
$colMembers = @()
$FullDetails = @()
$Domain = (Get-AdForest).Name

# =============== Do the Forest Privilige Groups First ================
foreach ($group in $ForestPrivGroups) {
    $Members = @() 
        
    Write-Host "Enumerating $Group" -foreground Blue        
    $Members = Get-ADGroupMember $Group -server $Domain -Recursive         
    $Count = $Members.count                
    Write-Host "Found $count members in $Group"        
    foreach ($member in $Members) {            
        $MembersDetails = get-aduser $member -properties * | Select-Object DisplayName, Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires, SamAccountName, UserPrincipalName, Description, @{Name = 'PasswordAge'; Expression = { ((Get-Date) - $_.PasswordLastSet).Days } }                      
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
foreach ($Domain in $Domains) {
    Write-Host "Enumerating Groups in $Domain" -ForegroundColor Yellow
    foreach ($Group in $DomainPrivGroups) {
        $Members = @()
        Write-Host "Enumerating $Group" -foreground Blue
        $Members = Get-ADGroupMember $Group -server $Domain -Recursive 
        $Count = $Members.count        
        Write-Host "Found $count members in $Group"
        foreach ($member in $Members) {
            $MembersDetails = get-aduser $member -properties * | Select-Object DisplayName, Enabled, LastLogonDate, PasswordLastSet, PasswordNeverExpires, SamAccountName, UserPrincipalName, Description, @{Name = 'PasswordAge'; Expression = { ((Get-Date) - $_.PasswordLastSet).Days } }          
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
$colMembers | export-csv -Path E:\Scripts\Ian\CSV\PrivUsers\AllPrivUsers.csv -NoTypeInformation




