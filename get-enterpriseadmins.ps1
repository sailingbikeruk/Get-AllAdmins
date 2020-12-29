# Version 2.0
Import-module ActiveDirectory

# Set ErrorAction to stop so the Try/Catch statements work
$ErrorActionPreference = "Stop"

# File Locations
$LogFile = "E:\Scripts\Ian\CSV\EA.Log"
$EmailBody = "e:\scripts\ian\csv\emailbody.txt"

# Initialising general variables
$members = @()
$Logstring = "If you see this then the logstring was only set at the start"
$Group = "Enterprise Admins"
$UnexpectedUser = 0

# Initialising email specific variables
$SmtpBody = ""
$SmtpSender = "InformationSecurity@Graftonplc.com"
$Email = ""
$LogEmail = "InformationSecurity@graftonplc.com", "Tim.Connop@graftonplc.com"
$SmtpSubject = "Enterprise Admins Group"
$SmtpServer = "10.15.2.9"
$message = ""

# Function to generate a logfile
# First make sure it doesnt already exist.
if (Test-Path $LogFile) {
    try {
        Remove-Item -path $LogFile
    }
    catch {
        # send the log file.
        $SmtpBody = "There was an issue removing a previous logfile for the Enterpise Admin Script at $(Get-Date)"
        try {
            $SmtpBody = "There was an issue removing a previous logfile for the Enterpise Admin Script at $(Get-Date)"
            logwrite("$(get-date) $SmtpBody")
        }
        Catch {        
            $SmtpBody = "There was an issue accessing the logfile for the Enterpise Admin Script at $(Get-Date)"
            $SmtpSubject = "Enterprise Admins Script - Logfile Error"
            Send-MailMessage -Body $SmtpBody -BodyAsHtml -From $SmtpSender -To $LogEmail -Subject $SmtpSubject -SmtpServer $SmtpServer -Attachments $LogFile
        }

    }
}
else {
    # send the log file.
    $SmtpBody = "There was an issue accessing the logfile for the Enterpise Admin Script $(Get-Date)"
    $SmtpSubject = "Enterprise Admins Script - Logfile Error"
    Send-MailMessage -Body $SmtpBody -BodyAsHtml -From $SmtpSender -To $LogEmail -Subject $SmtpSubject -SmtpServer $SmtpServer -Attachments $LogFile
}

Function LogWrite {
    Param ([string]$Logstring)
    Add-Content $Logfile -value $logstring -ErrorAction Stop    
    Write-Host $logstring
}

# Get the members of the Enterprise Admins Group and log the number found
function Get-EAMembers() {
    try {
        $results = Get-ADGroupMember -Identity $Group
        # Annotate Logfile with Time, Date and a starting entry
        logwrite("$(Get-Date) There were $($results.count) accounts found in the Enterprise Admins Group")
        logwrite("Accounts Found: $($results.SamAccountName)")
        logwrite("---------------------------------------------------")
        return($results)
    }
    Catch {
        logwrite("$(Get-Date) Unable to Obtain the Group Membership")
        logwrite($Error[0])
        logwrite("Script ended in error at $(Get-Date)")
        return($null)
    }
}

logwrite("$(get-Date) Initial Check")
$members = Get-EAMembers

# Iterate through each member
foreach ($member in $members) {
    $SName = $member.SamAccountNAme
    switch ($SName) {
        # Check to see if it is a known service account, if it is, continue to the next $member
        "svc_serviceshub" { Continue }
        "Admin_Veeam" { Continue }
        "svc_pdqdeploy" { Continue }
        # If it is NOT a known and required service account
        default {
            # Set $UnexpectedUser=1 if we find any acocunt other than the three we expected. 
            # This will force a re-run of Get-EAMembers once we have removed all the ones we identify as unexpected.
            $UnexpectedUser = 1

            # Get the Users email address so we can email them to let them know (in case they are still working)
            Try {
                $User = get-aduser -identity $SName -properties EmailAddress | Select EmailAddress 
            }
            # If the get-aduser cmdlet fails, log and move to next record.
            Catch {
                LogWrite("$Time2 Unable to obtain an AD User record for $SName")
                logwrite($error[0])
                Continue
            }

            # If the email address is empty, remove the account, log the details and record the missing email address            
            if ($null -eq $User.EmailAddress) {
                try {
                    remove-adgroupmember -Identity "Enterprise Admins" -Members $SName -Confirm:$False
                    $message = "$Time2 The SU Account for $SName was removed from Enterprise Admins. There was no email address for the user in AD"
                    LogWrite($Message)
                }
                Catch {
                    Logwrite("An error occurred whilst trying to remove $SName")
                    logwrite($error[0])
                }
            }
            # If you have a user in EA, you have found them in AD and they have an email address, send the email and log the details
            else {
                try {
                    $Email = $User.EmailAddress
                    remove-adgroupmember -Identity "Enterprise Admins" -Members $SName -Confirm:$False
                    $SmtpBody = "$(Get-Date) The SU Account for $SName was found in Enterprise Admins. It was removed by script" 
                    LogWrite($SmtpBody)
                    Send-MailMessage -Body $SmtpBody -BodyAsHtml -From $SmtpSender -To $Email -Subject $SmtpSubject -SmtpServer $SmtpServer
                    $SmtpBody = "" # clear the $SmtpBody variable for use elsewhere in the script.
                }
                Catch {
                    Logwrite("$(Get-Date) An error occurred whilst trying to remove $SName")
                    logwrite($error[0])
                }
            }
        }
    }
}
# If there are more than three members in EA get the membership again and check that all have been removed
if ($UnexpectedUser -eq 1) {
    logwrite("---------------------------------------------------")
    logwrite("$(get-Date) Post Changes Check - Unexpected users where found. Please review and ensure all have been removed")
    $members = Get-EAMembers
}
# if $UnexpectedUser -ne 1 then assume there are only the known three and don't rerun the check
else {
    logwrite("$(get-date) No unexpected accounts found - No changes were made to the EA Group")
}

# Here we create the email body using an introductory line with the date and the contents of the logfile
# whenever I attempted to concatenate anything with Get-Content all CR/LF were removed from the results
# so I do the concatentaion, write it out to a temporary file contained in $EmailBody and read the contents of that for the email.
# in order to use it for the email body I have to convert it to a single string with line breaks. 
# ToString() and Out-String() both stripped the cr/lf creating one long single string which was unreadable
# so I loop through the array of strings and add a newline (`n) to the end of each one and then add the next line.
@("Report for Enterprise Admins check run at $(Get-Date)`n`n") + (get-content $LogFile) | set-content $EmailBody
if (test-path -Path $emailbody) {
    $temp = get-content $EmailBody
    for ($i = 0; $i -le $temp.count; $i++) {
        $SMTPBody += $temp[$i] + "`n"
    }
    Remove-Item -Path $EmailBody
}
else {
    $SMTPBody = "Report for Enterprise Admins check that completed at $(Get-Date)`n`nThere was an error retrieving the text of the log file please review the attachment"
}
$SmtpSubject = "Enterprise Admins Script - Log"

# send the log file as an attachment and in the email body

try {
    Send-MailMessage -Body $SmtpBody -From $SmtpSender -To $LogEmail -Subject $SmtpSubject -SmtpServer $SmtpServer -Attachments $LogFile
    logwrite("$(Get-Date) Log file sent to $LogEmail")
    logwrite("---------------------------------------------------")
}
Catch {
    logwrite("$(Get-Date) An error occurred sending the Log")
    logwrite("The error reported was $_")
    logwrite("---------------------------------------------------")
}
#>
