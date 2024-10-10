

function SetDefaultContentTypeToList {
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
    $contentTypeInList = Get-PnPContentType -List $ListIdentity -Identity $contentType.Name -ErrorAction SilentlyContinue

    if ($null -eq $contentTypeInList) {
        Write-Warning "Content Type $ContentTypeIdentity is not associated with List $ListIdentity"
        return
    }

    # Set the specified content type as the default for the list
    Set-PnPDefaultContentTypeToList -List $ListIdentity -ContentType $contentTypeInList
    Write-Host "Content Type $ContentTypeIdentity set as default for List $ListIdentity" -ForegroundColor Green
}









































