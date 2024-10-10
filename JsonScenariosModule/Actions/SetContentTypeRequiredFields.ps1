

function SetContentTypeRequiredFields {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The content Type Identity.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "Array of field internal names to be set as required.")]
        [string[]] $RequiredFieldInternalNames,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate whether to update child content types.")]
        [bool] $UpdateChildren = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts for updating fields.")]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Attempts = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Interval between retry attempts in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $RetryAfterMs = 3000,

        [Parameter(Mandatory = $false, HelpMessage = "Short delay between field updates in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ShortDelay = 300
    )

    # Retrieve the content type
    $contentType = Get-PnPContentType -Identity $ContentTypeIdentity -ErrorAction SilentlyContinue
    if ($null -eq $contentType) {
        Write-Warning "Content Type with ID or Name $ContentTypeIdentity not found"
        return
    }

    # Retrieve all fields within the content type
    $contentTypeFields = $contentType.Fields
    $ctx = Get-PnPContext
    $ctx.Load($contentTypeFields)
    $ctx.ExecuteQuery()

    # Iterate through each field in the content type
    foreach ($field in $contentTypeFields) {
        $retryCount = 0
        while ($true) {
            try {
                Start-Sleep -Milliseconds $ShortDelay  # Wait for a short delay before the next update
    
                # Get the field link for the field within the content type
                $fieldLink = $contentType.FieldLinks.GetById($field.Id)
                $ctx.Load($fieldLink)
                $ctx.ExecuteQuery()
    
                # Check the current Required value of the field
                $currentRequiredValue = $fieldLink.Required
    
                # Set the Required attribute based on whether the field is in the RequiredFields list
                $isRequired = $RequiredFieldInternalNames -contains $field.InternalName
    
                # If the current Required value is already the desired value, output a warning and continue
                if ($currentRequiredValue -eq $isRequired) {
                    Write-Host "Field $($field.InternalName) already set to required: $($isRequired) in Content Type $ContentTypeIdentity" -ForegroundColor DarkGreen
                    break
                }
    
                # Update the Required attribute and commit changes
                $fieldLink.Required = $isRequired
                $contentType.Update($(If ($UpdateChildren) { 1 } else { 0 }))
                $ctx.ExecuteQuery()
    
                Write-Host "Field $($field.InternalName) set to required: $($isRequired) in Content Type $ContentTypeIdentity" -ForegroundColor Green
                break
            }
            catch {
                if (++$retryCount -ge $Attempts) {
                    Write-Error "Failed to update field $($field.InternalName) after $Attempts attempts."
                    throw
                }
                else {
                    Write-Warning "Failed to update field $($field.InternalName). Attempt $retryCount of $Attempts."
                    Start-Sleep -Milliseconds $RetryAfterMs  # Wait a while before retrying
                }
            }
        }
    }
}


































































































