

function EnsureContentTypeInList {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The content Type Identity.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "The list identity.")]
        [string] $ListIdentity
    )

    # Retrieve the list
    $list = Get-PnPList -Identity $ListIdentity -ErrorAction SilentlyContinue
    if ($null -eq $list) {
        Write-Warning "List with identity $ListIdentity not found"
        return
    }

    # Retrieve the ContentType
    $contentType = Get-PnPContentType -Identity $ContentTypeIdentity -ErrorAction SilentlyContinue
    if ($null -eq $contentType) {
        Write-Warning "Content Type with ID or Name $ContentTypeIdentity not found"
        return
    }

    # Check if the ContentType is already present in the list using a single request
    $contentTypeInList = Get-PnPContentType -List $ListIdentity -Identity $contentType.Name -ErrorAction SilentlyContinue

    if ($null -ne $contentTypeInList) {
        Write-Warning "Content Type $ContentTypeIdentity already exists in List $ListIdentity"
    }
    else {
        # If the ContentType is not present in the list, add it
        Add-PnPContentTypeToList -ContentType $contentType.Id -List $list.Id
        Write-Host "Content Type $ContentTypeIdentity added to List $ListIdentity" -ForegroundColor Green
    }
}
























































































