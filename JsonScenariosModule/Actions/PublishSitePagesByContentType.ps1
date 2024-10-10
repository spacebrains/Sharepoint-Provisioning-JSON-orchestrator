function PublishSitePagesByContentType {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identifier of the content type of the items to be published.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts for publishing pages.")]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Attempts = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Interval between retry attempts in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $RetryAfterMs = 3000,

        [Parameter(Mandatory = $false, HelpMessage = "Short delay between page publishing in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ShortDelay = 300
    )

    Write-Host "Starting to process items in Site Pages for publishing..." -ForegroundColor Green

    # Retrieve all list items matching ContentTypeIdentity from the Site Pages library
    $query = "<View Scope='Recursive'><Query><Where><And><Eq><FieldRef Name='ContentType' /><Value Type='Computed'>$ContentTypeIdentity</Value></Eq><Neq><FieldRef Name='FSObjType' /><Value Type='Integer'>1</Value></Neq></And></Where></Query></View>" 
    $listItems = Get-PnpListItem -List "Site Pages" -Query $query -PageSize 5000

    Write-Host "Loaded $($listItems.Count) items from Site Pages." -ForegroundColor Green

    # Publish the pages one by one
    foreach ($item in $listItems) {
        $fullPath = $item.FieldValues['FileRef']
        $relativePath = ($fullPath -split 'SitePages/', 2)[1]

        $currentAttempt = 1
        $isPublished = $false

        while ($currentAttempt -le $Attempts -and -not $isPublished) {
            try {
                Set-PnPPage -Identity $relativePath -Publish
                Write-Host "Published page: $relativePath" -ForegroundColor Green
                $isPublished = $true
            }
            catch {
                Write-Warning "Failed to publish page: $relativePath. Attempt $currentAttempt of $Attempts."
                if ($currentAttempt -lt $Attempts) {
                    Start-Sleep -Milliseconds $RetryAfterMs
                }
            }
            $currentAttempt++
        }

        # Short delay before the next publishing
        Start-Sleep -Milliseconds $ShortDelay
    }
}
