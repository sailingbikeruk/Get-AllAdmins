$groups = 'Enterprise Admins'
[int]$LastCount=Get-Content "e:\scripts\ian\csv\EACount.txt"
$SmtpSender = "no-reply@graftonplc.com" 
$SmtpSubject = "MFA Users weekly Report"
$SmtpServer = "graf-a-exht01.graftonplc.net"
$graftonplcEmail = "Ian.davies@graftonplc.com"

foreach($Group in $Groups){
        $members = Get-ADGroupMember -Identity $group -Recursive | Select -ExpandProperty SamAccountName    
        If($LastCount -eq $Members.count)
        {
            $Message = "$Group contains $($members.count) members - this is the same as the previous check"
        }
        if($members.count -lt $LastCount)
        {
            $Difference = $LastCount - $members.count
            $Message = "$Group contains $($members.count) members - this has decreased by $Difference since the previous check"
        }
        if($members.count -gt $lastcount)
        {            
            $Difference = $Members.count - $LastCount        
            $Message = "$Group contains $($members.count) members - this has Increased by $Difference since the previous check"        
        }   
}
write-host $Message -ForegroundColor Red
$OutputInt = $members.count
$OutputInt
[string]$OutputStr=$OutputInt
set-content e:\scripts\ian\csv\EACount.txt $OutputStr
Send-MailMessage -Body $Message -BodyAsHtml -From $SmtpSender -To $graftonplcEmail -Subject $SmtpSubject -SmtpServer $SmtpServer
