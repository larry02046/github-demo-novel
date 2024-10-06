$sharepath  = '.\Transcripts'
$datetime   = get-Date -f 'ddMMyyyy_HHmmss'
$filename   = "Transcript_SR_${datetime}.txt"
$Transcript = Join-Path -Path $sharepath -ChildPath $filename

Start-Transcript -path $Transcript -NoClobber

Write-Host "Connecting to Microsoft Graph..."
try {
    # Connect to Microsoft Graph
    Connect-MgGraph -Scopes "User.Read.All", "GroupMember.ReadWrite.All" -NoWelcome
    Write-Host "Successfully connected to Microsoft Graph."
}
catch {
    Write-Error $error
    exit (0)
}

# Define the timeframe for newly created users (e.g., last 1 day)
$timeframe = (Get-Date).AddDays(-8)
Write-Host "Retrieving users created after $timeframe"

# Get users created in the last 1 days



$newUsers = Get-MgUser -Filter "accountEnabled eq true and OnPremisesSyncEnabled ne true and createdDateTime ge $($timeframe.ToString('yyyy-MM-ddTHH:mm:ssZ'))" -Property Displayname, UserPrincipalName, Id -ConsistencyLevel eventual -CountVariable CountVar | Select-Object DisplayName, UserPrincipalName, Id
$newUsers

if ($newUsers.Count -gt 0) {
    Write-Host "Found $($newUsers.Count) new users."
    }
    else {
        Write-Host "No new users found."
        exit
    }



# Try to add the user to the group
# Get current group members

$groupMembers = Get-MgGroupMember -GroupId 9f252386-5efe-4144-8ac2-8dca893464b1

# Check if the user is already a member of the group
$isMember = $groupMembers | Where-Object { $_.Id -eq $user.Id }

If ($isMember) {
    Write-Host "Cannot add $($user.UserPrincipalName) because they are already the member of the group."
    } else {
        foreach ($user in $newUsers) {
        Try {
            Write-Host "Adding user - $($user.UserPrincipalName) - to 'NewStarter' Group"
            # Add each new user to the group
            New-MgGroupMember -GroupId 9f252386-5efe-4144-8ac2-8dca893464b1 -DirectoryObjectId $user.Id
            Write-Host "$($user.UserPrincipalName) successfully added to 'NewStarter' group."
        }
        catch {
            Write-error $error
        }
    }
}

Stop-Transcript