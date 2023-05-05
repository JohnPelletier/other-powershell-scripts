
##
## This module can sync an active directory user group to Alteryx Server user group. The APIs to do this are public and no keys are given here. You have to supply them for this to work
## You also have to give the right name of the AD group and the Server user group that you care about.
## I've already shared this code with the SA team. I left the company, so I can't maintain it, so this is my own fork of it that has no IP except sample code to help boost Alteryx Server sales
## Incidentally there is a new way to sync these groups using SCIM, released sometime in 2023.
## So this code is only good for showing how to access AD groups and how to get a bearer token with an API key and secret in OAuth2 using simple Auth
##


Import-Module ActiveDirectory



###########
Function Get-ADGroupList(
    $AD_Group
) {
    $list = ""
    $members = Get-ADGroup $AD_Group | Get-ADGroupMember
    $members | format-table #| select samaccountname, name 

    $members | ForEach-Object {

        #$_.name
        #here is where I can insert an API call to add users to a group
        $list += $_.samaccountname
    }
    return $list
}

##########



#this code retrieves a bearer token given a client key and secret
Function Get-BearerToken {
    [cmdletbinding()]
    Param (
    $Uri = 'http://localhost/webapi/oauth2/token',
    $client_id,
    $client_secret
    )

    $Text = $client_id + ':' + $client_secret
    
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $EncodedText =[Convert]::ToBase64String($Bytes)

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Basic " + $EncodedText)
    
    $headers.Add("Content-Type", "application/x-www-form-urlencoded")

    $body = "grant_type=client_credentials&scope=user&resource=http%3A%2F%2Flocalhost%2Fwebapi%2Fv3%0A"

    $response = Invoke-RestMethod $Uri -Method 'POST' -Headers $headers -Body $body
    return $response #| ConvertTo-Json

}

#this gets all collections known in the system and the retun value is a nicely formatted table
Function Get-All {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $UriBase = 'http://localhost/webapi/v3',
    $endpoint
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $bearerToken)

    $response = Invoke-RestMethod ($UriBase + "/" + $endpoint) -Method 'GET' -Headers $headers
    return $response 
}

#this gets all collections known in the system and the retun value is a nicely formatted table
Function Post-Object {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $UriBase = 'http://localhost/webapi/v3',
    $endpoint,
    $body
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $bearerToken)
    $headers.Add("Content-type", "application/json")

    $response = Invoke-RestMethod ($UriBase + "/" + $endpoint) -Method 'POST' -Headers $headers -Body $body
    return $response 
}

#this gets all collections known in the system and the retun value is a nicely formatted table
Function Delete-Object {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $UriBase = 'http://localhost/webapi/v3',
    $endpoint,
    $body
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Authorization", "Bearer " + $bearerToken)
    $headers.Add("Content-type", "application/json")

    $response = Invoke-RestMethod ($UriBase + "/" + $endpoint) -Method 'DELETE' -Headers $headers -Body $body
    return $response 
}

#this gets all collections known in the system and the retun value is a nicely formatted table
Function Get-CollectionsAll {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $UriBase = 'http://localhost/webapi/v3'
    )

    $response = Get-All $bearerToken $UriBase "collections"
    return $response 
}

#this gets all users known in the system and the retun value is a nicely formatted table
Function Get-UsersAll {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $UriBase = 'http://localhost/webapi/v3'
    )

    $response = Get-All $bearerToken $UriBase "users?active=true&verbose=false"
    return $response 
}

#this gets all users known in the system and the retun value is a nicely formatted table

#replace http:localhost with your own Alteryx Server installation's URL

Function Post-GroupUser {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $userGroup,
    $user,
    $UriBase = 'http://localhost/webapi/v3'
    )

    $query = "usergroups/" + $userGroup + "/users"
    $body = '["' + $user + '"]'
    $response = Post-Object $bearerToken $UriBase $query $body
    return $response 
}

Function Remove-GroupUser {
[cmdletbinding()]
    Param (
    $bearerToken,
    $userGroup,
    $user,
    $UriBase = 'http://localhost/webapi/v3'
    )

    $query = "usergroups/" + $userGroup + "/users/"+ $user
    $response = Delete-Object $bearerToken $UriBase $query
    return $response 
}

#this gets all users known in the system and the retun value is a nicely formatted table
Function Get-User {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $user,
    $UriBase = 'http://localhost/webapi/v3'
    )

    $query = "users/" + $user
    $response = Get-All $bearerToken $UriBase $query
    return $response 
}


#search is defined as something like 'email=john.somebody@company.com'
Function Get-UserBySearch {
[cmdletbinding()]
    Param (
    $bearerToken,
    $search,
    $UriBase = 'http://localhost/webapi/v3'
    )

    $query = "users/?" + $search
    $response = Get-All $bearerToken $UriBase $query
    return $response 
}

#this gets all user groups known in the system and the retun value is a nicely formatted table
Function Get-UserGroupsAll {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $UriBase = 'http://localhost/webapi/v3'
    )

    $response = Get-All $bearerToken $UriBase "usergroups"
    return $response 
}

Function Get-UserGroupSids {
[cmdletbinding()]
    Param (
    $bearerToken,
    $userGroup
    )

    #Find the user group
    $serverGroups = Get-UserGroupsAll $bearerToken
    $serverGroup = $serverGroups | Where-Object { $_.name -eq $userGroup } 

    #Get a list of member objects from the group
    $members = Get-UserGroup $bearerToken $serverGroup.id 
    $ugs = $members.members

    #Get the sidAccountNames of each member of the Server user group
    $sids_ug = $ugs | ForEach-Object -MemberName activeDirectoryObject | ForEach-Object -MemberName sidAccountName

    return $sids_ug
}

#this gets all user groups known in the system and the retun value is a nicely formatted table
Function Get-UserGroup {
 [cmdletbinding()]
    Param (
    $bearerToken,
    $userGroup,
    $UriBase = 'http://localhost/webapi/v3'
    )

    $query = "usergroups/" + $userGroup
    $response = Get-All $bearerToken $UriBase $query
    return $response 
}


Function Send-Email-ToUserGroup {
[cmdletbinding()]
    Param (
    $bearerToken,
    $userGroup,
    $subject,
    $body)

    #Get the sidAccountNames of each member of the Server user group
    $sids_ug = Get-UserGroupSids $bearerToken $userGroup

    #Create a list of recipient addresses to which we'll send an email
    $recipients = $sids_ug | ForEach-Object { "$_@company.com" } 

    #send the email
    Send-MailMessage -From 'John<somebody@company.com>' `
         -To $recipients `
         -Subject $subject `
         -Body $body `
         -Priority High `
         -DeliveryNotificationOption OnSuccess, OnFailure -SmtpServer 'smtp.domainname.com' 

}


#
#DEMO SCRIPT
#
# THIS SCRIPT ALLOWS YOU TO PERIODICALLY POLL YOUR AD SERVER AND MAKE AN ALTERYX SERVER CUSTOM GROUP TO MATCH IT
#
#                                                                insert real key and secret here below
$response = Get-BearerToken http://localhost/webapi/oauth2/token <api key> <api secret>
$bearerToken = $response.access_token

#--------------------------------------

$AD_Group = "Some Team" #AD GROUP THAT YOU'RE POLLING
$userGroup = 'UserGroupABC' #SERVER USER GROUP YOU'RE SYNC'ING TO IT

#------------------

##  Get the Server User Group you want to match to the AD group
$ug = Get-UserGroupsAll $bearerToken | Where-Object -Property Name -EQ $userGroup

##  Get the users from that Server User Group
$sids_ug = Get-UserGroupSids $bearerToken $userGroup

##  Get the AD group users you want to match in the Server User Group
$sids_ad = Get-ADGroup $AD_Group | Get-ADGroupMember | ForEach-Object -MemberName SamAccountName

# magic formula to get separate lists of sids to add and sids to remove from the User Group 
$sidsToAdd    = $sids_ad | ?{$sids_ug -notcontains $_}
$sidsToRemove = $sids_ug | ?{$sids_ad -notcontains $_}

########################################################################
# Add users to user group if they're newly added to the AD group       #
########################################################################
if ($sidsToAdd.Count -gt 0) {
    Write-Output "To Add: "
    $sidsToAdd | ForEach-Object { 
        #$sids_ug += $_ 
        $user = Get-UserBySearch $bearerToken "email=$_@company.com"
     
        #Post-GroupUser $bearerToken $ug.id $user.id #need to test this tomorrow...see if it works
            #this seems to work but I think the API is buggy, see OneNote notes
            #uncomment the above when the bug is fixed
            $user.email
    }
    Write-Output ""
} else { Write-Output "No new members in the AD group to add to the user group." }


############################################################################
# Remove users from user group if they're newly removed from the AD group  #
############################################################################
if ($sidsToRemove.Count -gt 0) {
    Write-Output "To Remove:"
    $sidsToRemove | ForEach-Object {
        $user = Get-UserBySearch $bearerToken "email=$_@company.com" 
        Remove-GroupUser $bearerToken $ug.id $user.id
        $user.email
    }
    Write-Output ""
} else { Write-Output "No members to remove from the user group." }

