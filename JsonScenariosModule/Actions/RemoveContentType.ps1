
function RemoveContentType {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The content Type Identity.")]
        [string] $ContentTypeIdentity
    )

 
    $contentType = Get-PnPContentType -Identity $ContentTypeIdentity -ErrorAction SilentlyContinue
    if ($null -eq $contentType) {
        Write-Warning "Content Type with ID or Name $ContentTypeIdentity not found"
        return
    }

    Remove-PnPContentType -Identity $ContentTypeIdentity -Force
    Write-Host "Content Type $ContentTypeIdentity has been removed" -ForegroundColor Green
}

