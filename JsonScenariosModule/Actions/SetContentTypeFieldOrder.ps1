function SetContentTypeFieldOrder {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the content type.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "The order of fields in the content type.")]
        [string[]] $FieldOrder
    )
    
    try {
        # Get the content type
        $ContentType = Get-PnPContentType -Identity $ContentTypeIdentity -ErrorAction Stop
        
        # Get the FieldLinks and reorder them
        $FieldLinks = Get-PnPProperty -ClientObject $ContentType -Property "FieldLinks"
        $FieldLinks.Reorder($FieldOrder)
        
        # Update the content type with the new order
        $ContentType.Update($True)
        Invoke-PnPQuery

        Write-Host "Field order for content type '$ContentTypeIdentity' has been updated successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Error updating field order for content type '$ContentTypeIdentity': $_"
    }
}
