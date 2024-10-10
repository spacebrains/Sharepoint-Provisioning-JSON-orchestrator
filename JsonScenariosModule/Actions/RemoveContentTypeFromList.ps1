

function RemoveContentTypeFromList {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The content Type Identity.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "The list identity.")]
        [string] $ListIdentity
    )

    # Check if the specified content type exists
    $contentType = Get-PnPContentType -Identity $ContentTypeIdentity -ErrorAction SilentlyContinue
    if ($null -eq $contentType) {
        Write-Warning "Content Type with ID or Name $ContentTypeIdentity not found"
        return
    }

    # Check if the specified list exists
    $list = Get-PnPList -Identity $ListIdentity -ErrorAction SilentlyContinue
    if ($null -eq $list) {
        Write-Warning "List with ID or Name $ListIdentity not found"
        return
    }

    # Check if the content type is associated with the list
    $contentTypeInList = Get-PnPContentType -List $ListIdentity -Identity $ContentTypeIdentity -ErrorAction SilentlyContinue

    if ($null -eq $contentTypeInList) {
        Write-Warning "Content Type $ContentTypeIdentity is not associated with List $ListIdentity"
        return
    }

    # Remove the specified content type from the list
    Remove-PnPContentTypeFromList -List $ListIdentity -ContentType $ContentTypeIdentity
    Write-Host "Content Type $ContentTypeIdentity removed from List $ListIdentity" -ForegroundColor Green
}










































