

Function SetListSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity,

        [Parameter(Mandatory = $false, HelpMessage = "Title for the list.")]
        [string]$Title,

        [Parameter(Mandatory = $false, HelpMessage = "Description for the list.")]
        [string]$Description,

        [Parameter(Mandatory = $false, HelpMessage = "Break permissions inheritance from the parent.")]
        [Nullable[bool]]$BreakRoleInheritance,

        [Parameter(Mandatory = $false, HelpMessage = "Copy permissions from the parent when breaking inheritance.")]
        [Nullable[bool]]$CopyRoleAssignments,

        [Parameter(Mandatory = $false, HelpMessage = "Reset permissions inheritance to inherit from the parent.")]
        [Nullable[bool]]$ResetRoleInheritance,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if versioning is enabled.")]
        [Nullable[bool]]$EnableVersioning,

        [Parameter(Mandatory = $false, HelpMessage = "The number of major versions to keep.")]
        [ValidateRange(0, 50000)]
        [Nullable[int]]$MajorVersions,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if minor versioning is enabled.")]
        [Nullable[bool]]$EnableMinorVersions,

        [Parameter(Mandatory = $false, HelpMessage = "The number of minor versions to keep.")]
        [ValidateRange(0, 50000)]
        [Nullable[int]]$MinorVersions,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the Read access level for items in the list. Options are: \n1 (All users have Read access to all items) \n2 (Users have Read access only to items they create).")]
        [ValidateSet(1, 2)]
        [Nullable[int]]$ReadSecurity = $null,
        
        [Parameter(Mandatory = $false, HelpMessage = "Determines the Write permissions for items in the list. Options: \n1 (Write access to all items), \n2 (Write access only to own items), \n4 (No write access, read-only list).")]
        [ValidateSet(1, 2, 4)]
        [Nullable[int]]$WriteSecurity,
        
        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if folder creation is enabled.")]
        [Nullable[bool]]$FolderEnable,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if content types are enabled.")]
        [Nullable[bool]]$EnableContentTypes,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the list is hidden from the user interface.")]
        [Nullable[bool]]$Hidden = $null,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the comments are enabled")]
        [Nullable[bool]]$EnableCommenting,

        [Parameter(Mandatory = $false, HelpMessage = "The type of rating for the list.")]
        [ValidateSet("Likes", "Ratings", "None")]
        [string]$RatingType
    )

    $List = Get-PnPList -Identity $ListIdentity
    
    $parameters = @{
        Identity = $List
    }
    
    if ($Title) { $parameters["Title"] = $Title }
    if ($Description) { $parameters["Description"] = $Description }
    if ($null -ne $BreakRoleInheritance) { $parameters["BreakRoleInheritance"] = $BreakRoleInheritance }
    if ($null -ne $CopyRoleAssignments) { $parameters["CopyRoleAssignments"] = $CopyRoleAssignments }
    if ($null -ne $ResetRoleInheritance) { $parameters["ResetRoleInheritance"] = $ResetRoleInheritance }
    if ($null -ne $EnableVersioning) { $parameters["EnableVersioning"] = $EnableVersioning }
    if ($null -ne $MajorVersions) { $parameters["MajorVersions"] = $MajorVersions }
    if ($null -ne $EnableMinorVersions) { $parameters["EnableMinorVersions"] = $EnableMinorVersions }
    if ($null -ne $MinorVersions) { $parameters["MinorVersions"] = $MinorVersions }
    if ($null -ne $ReadSecurity) { $parameters["ReadSecurity"] = $ReadSecurity }
    if ($null -ne $WriteSecurity) { $parameters["WriteSecurity"] = $WriteSecurity }
    if ($null -ne $FolderEnable) { $parameters["EnableFolderCreation"] = $FolderEnable }
    if ($null -ne $EnableContentTypes) { $parameters["EnableContentTypes"] = $EnableContentTypes }
    if ($null -ne $Hidden) { $parameters["Hidden"] = $Hidden }
    
    if ($parameters.Count -gt 0) {
        $List = Set-PnPList @parameters
    }

    $List = Get-PnPList -Identity $ListIdentity
      
    if ($null -ne $EnableCommenting) {
        $List.DisableCommenting = -not $EnableCommenting 
        $List.Update()
        Invoke-PnPQuery
    }

    if ("" -ne $RatingType) {
        SetListRating -ListIdentity $List.Title -RatingType $RatingType
    }

    Write-Host "List $($List.Title) updated" -ForegroundColor Green
}













































































