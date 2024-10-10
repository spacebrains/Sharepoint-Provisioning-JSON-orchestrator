function ChangeTitleAreaInSitePages {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The List Identity where the pages are located.")]
        [string] $ListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "The layout type to be applied to the title area.")]
        [ValidateSet("FullWidthImage", "NoImage", "ColorBlock", "CutInShape")]
        [string] $LayoutType,

        [Parameter(Mandatory = $false, HelpMessage = "Content Type Identity to filter pages.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts.")]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Attempts = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Interval between retry attempts in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $RetryAfterMs = 3000,

        [Parameter(Mandatory = $false, HelpMessage = "Short delay between operations in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ShortDelay = 300,
        
        [Parameter(Mandatory = $false, HelpMessage = "Optional. If true, includes active posts, otherwise all posts")]
        [bool] $ActiveOnly = $false
    )

    # Retrieve pages from the list
    $list = Get-PnPList -Identity $ListIdentity
    $listContentTypes = Get-PnPContentType -List $list
    $contentTypeId = ($listContentTypes | Where-Object { $_.Name -eq $ContentTypeIdentity }).Id.StringValue

    $pages = Get-PnpListItem -List $ListIdentity -PageSize 5000
    if ($ContentTypeIdentity) { 
        $pages = $pages | Where-Object { $_.FieldValues.FSObjType -eq 0 -and $_.FieldValues.ContentTypeId.StringValue -eq $contentTypeId }
        if ($ActiveOnly) {
            $pages = $pages | Where-Object { $_.FieldValues.FileDirRef.EndsWith("ArchivedIdeas") -eq $false }
        }

    }
    else {
        $pages = $pages | Where-Object { $_.FieldValues.FSObjType -eq 0 }
        if ($ActiveOnly) {
            $pages = $pages | Where-Object { $_.FieldValues.FileDirRef.EndsWith("ArchivedIdeas") -eq $false }
        }
    } 

    

    if ($ActiveOnly) {
        Write-Host "Loaded $($pages.Count) active ideas from the list." -ForegroundColor Green
    }
    else {
        Write-Host "Loaded $($pages.Count)  ideas from the list." -ForegroundColor Green
    }


    foreach ($page in $pages) {
        $retryCount = 0
        while ($retryCount -lt $Attempts) {
            try {
                # Retrieve the client-side page
                $clientSidePage = Get-PnPClientSidePage -Identity $page.FieldValues.FileLeafRef

                # Check if the layout type is already set to the desired value
                if ($clientSidePage.PageHeader.LayoutType -ne $LayoutType) {
                    # Set the layout type
                    $clientSidePage.PageHeader.LayoutType = $LayoutType
                    $clientSidePage.Save()
                    Write-Host "Page header layout type '$LayoutType' applied to page $($page.FieldValues.FileLeafRef)" -ForegroundColor Green
                }
                else {
                    Write-Host "Page $($page.FieldValues.FileLeafRef) already has the layout type '$LayoutType'" -ForegroundColor Yellow
                }
                break
            }
            catch {
                $retryCount++
                if ($retryCount -ge $Attempts) {
                    Write-Error "Failed to apply page header layout type '$LayoutType' to page $($page.FieldValues.FileLeafRef) after $Attempts attempts."                    
                }
                else {
                    Write-Warning "Failed to apply page header layout type '$LayoutType'. Attempt $retryCount of $Attempts. Retrying in $($RetryAfterMs)ms..."
                    Start-Sleep -Milliseconds $RetryAfterMs
                }
            }
        }

        Start-Sleep -Milliseconds $ShortDelay
    }
}






