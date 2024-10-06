

$sharepath  = 'C:\temp\transcripts'
$datetime   = get-Date -f 'ddMMyyyy_HHmmss'
$filename   = "Transcript_SR_${datetime}.txt"
$Transcript = Join-Path -Path $sharepath -ChildPath $filename

Start-Transcript -path $Transcript -NoClobber


# Connect to Microsoft Graph

Write-Host "Connecting to MS Graph"
Try {
    Connect-MgGraph -Scopes "User.Read.All","GroupMember.ReadWrite.All" -Nowelcome
}
Catch {
    Write-Error $error
    exit (0)
}

# Define the timeframe for newly created users (e.g., last 1 day)
$timeframe = (Get-Date).AddDays(-20)
Write-Host "Getting users created after $timeframe"

# Get users created in the last 1 days
$newUsers = Get-MgUser -Filter "accountEnabled eq true and OnPremisesSyncEnabled ne true and createdDateTime ge $($timeframe.ToString('yyyy-MM-ddTHH:mm:ssZ'))" -Property Displayname,UserprincipalName,Id -ConsistencyLevel eventual -CountVariable CountVar | Select-Object Displayname,UserprincipalName,Id
$newUsers

foreach ($user in $newUsers) {
    try {
        Write-Host "Adding user - $($user.Displayname) - to NewStarter Group"
        New-MgGroupMember -GroupId 9f252386-5efe-4144-8ac2-8dca893464b1 -DirectoryObjectId $user.Id
        Write-Host "$($user.Displayname) added to group"
    }
    Catch {
        Write-error $error
    }
}

Stop-Transcript

