function SetListRating {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "The type of rating for the list.")]
        [ValidateSet("Likes", "Ratings", "None")]
        [string]$RatingType
    )

    $Ctx = Get-PnPContext

    $List = $Ctx.Web.Lists.GetByTitle($ListIdentity)
    $Ctx.Load($List)
    $Ctx.ExecuteQuery()

    # Define rating site columns IDs
    $AverageRatingFieldID = [guid]"5a14d1ab-1513-48c7-97b3-657a5ba6c742"
    $RatingCountFieldID = [guid]"b1996002-9167-45e5-a4df-b2c41c6723c7"
    $RatedByFieldID = [guid]"4D64B067-08C3-43DC-A87B-8B8E01673313"
    $RatingsFieldID = [guid]"434F51FB-FFD2-4A0E-A03B-CA3131AC67BA"
    $LikesCountFieldID = [guid]"6E4D832B-F610-41a8-B3E0-239608EFDA41"
    $LikedByFieldID = [guid]"2CDCD5EB-846D-4f4d-9AAF-73E8E73C7312"

    # Load all list fields
    $Ctx.Load($List.Fields)
    $Ctx.ExecuteQuery()

    # Check and add necessary columns
    $SiteColumnsToAdd = @($AverageRatingFieldID, $RatingCountFieldID, $RatedByFieldID, $RatingsFieldID, $LikesCountFieldID, $LikedByFieldID)
    foreach ($FieldID in $SiteColumnsToAdd) {
        $SiteColumn = $List.ParentWeb.AvailableFields.GetById($FieldID)
        $Ctx.Load($SiteColumn)
        $Ctx.ExecuteQuery()
    
        $ListField = $List.Fields | Where-Object { $_.ID -eq $SiteColumn.Id }
        if ($NULL -eq $ListField) {
            $List.Fields.Add($SiteColumn)
        }
    }

    $Ctx.ExecuteQuery()

    # Set rating settings for the list's root folder
    $RootFolder = $List.RootFolder
    $RootFolderProperties = $RootFolder.Properties
    $Ctx.Load($RootFolder)
    $Ctx.Load($RootFolderProperties)
    $RootFolderProperties["Ratings_VotingExperience"] = if ($RatingType -eq "None") { "" } else { $RatingType }
    $RootFolder.Update()
    $Ctx.ExecuteQuery()
}
