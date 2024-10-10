

function EnsureContentType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the content type.")]
        [string]$Name,

        [Parameter(Mandatory = $true, HelpMessage = "The ID of the parent content type.\n\nExamples of base content type IDs:\n- Item: 0x01\n- Document: 0x0101\n- Event: 0x0102\n- Task: 0x0108\n- Message: 0x0107\n\nYou can also use IDs of custom content types if you are creating a child content type.")]
        [string]$ParentContentTypeId,

        [Parameter(Mandatory = $false, HelpMessage = "The GUID of the content type in format without dashes.")]
        [ValidatePattern("^[a-fA-F0-9]{32}$")]
        [string]$Id,

        [Parameter(Mandatory = $false, HelpMessage = "The group the content type belongs to.")]
        [string]$Group,

        [Parameter(Mandatory = $false, HelpMessage = "The description of the content type.")]
        [string]$Description
    )

    # Check for the existence of the content type by name
    $existingContentType = Get-PnPContentType | Where-Object { $_.Name -eq $Name }
    
    if ($null -ne $existingContentType) {
        Write-Warning "Content type with name $Name already exists!" 
        return
    }

    # Check for the existence of the parent content type
    $parentContentType = Get-PnPContentType -Identity $ParentContentTypeId -ErrorAction SilentlyContinue
    if ($null -eq $parentContentType) {
        Write-Error "Parent content type with ID $ParentContentTypeId does not exist!"
        return
    }

    # If $Id is provided, use it, otherwise generate a new GUID
    $newGuid = if ($null -ne $Id -and $Id -ne "") { $Id } else { [guid]::NewGuid().ToString("N") }

    # Form the new content type ID
    $newContentTypeId = "$ParentContentTypeId" + "00" + "$newGuid"

    # Create the content type with the new ID
    $createdContentType = Add-PnPContentType -Name $Name -ContentTypeId $newContentTypeId -Group $Group -Description $Description
    
    if ($null -eq $createdContentType) {
        Write-Error "Failed to create content type $Name!"
        return
    }

    Write-Host "Content type $Name created!" -ForegroundColor Green
}
























































































