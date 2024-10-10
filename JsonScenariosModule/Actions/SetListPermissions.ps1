

function SetListPermissions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity,
    
        [Parameter(Mandatory = $true, HelpMessage = "Choose a group title or provide a custom one:\n\n{{AssociatedOwnerGroup}}: Default owner group.\n{{AssociatedMemberGroup}}: Default member group.\n{{AssociatedVisitorGroup}}: Default visitor group.")]
        [string]$GroupTitle,
        
        [Parameter(Mandatory = $true, HelpMessage = "Choose a permission level:\n\nFull Control: Has full control.\nDesign: Can view, add, update, delete, approve, and customize.\nEdit: Can add, edit and delete lists; can view, add, update and delete list items and documents.\nContribute: Can view, add, update, and delete list items and documents.\nRead: Can view pages and list items and download documents.\n\nYou can also provide a custom permission level.")]
        [string[]]$Permissions
    )

    $List = Get-PnPList -Identity $ListIdentity -ErrorAction SilentlyContinue 
      
    if (-not $List) {
        Write-Warning "List does not exist!"
        return
    }
    
    switch ($GroupTitle) {
        "{{AssociatedOwnerGroup}}" { $Group = Get-PnPGroup -AssociatedOwnerGroup -ErrorAction SilentlyContinue }
        "{{AssociatedMemberGroup}}" { $Group = Get-PnPGroup -AssociatedMemberGroup -ErrorAction SilentlyContinue }
        "{{AssociatedVisitorGroup}}" { $Group = Get-PnPGroup -AssociatedVisitorGroup -ErrorAction SilentlyContinue }
        default { $Group = Get-PnPGroup -Identity $GroupTitle -ErrorAction SilentlyContinue }   
    }

    if (-not $GroupTitle) {
        Write-Warning "Group does not exist!"
        return
    }
    

    # Get the current permissions for the group on the list
    $currentPermissions = Get-PnPListPermissions -Identity $List -PrincipalId $Group.Id | ForEach-Object { $_.Name } -ErrorAction SilentlyContinue

    # Permissions to remove
    $permissionsToRemove = $currentPermissions | Where-Object { $_ -notin $Permissions }

    # Permissions to add
    $permissionsToAdd = $Permissions | Where-Object { $_ -notin $currentPermissions }

    # Remove unnecessary permissions
    foreach ($perm in $permissionsToRemove) {
        Set-PnPListPermission -Identity $List -Group $Group -RemoveRole $perm -ErrorAction SilentlyContinue
    }

    # Add new permissions
    foreach ($perm in $permissionsToAdd) {
        Set-PnPListPermission -Identity $List -Group $Group -AddRole $perm -ErrorAction SilentlyContinue
    }
}





























































