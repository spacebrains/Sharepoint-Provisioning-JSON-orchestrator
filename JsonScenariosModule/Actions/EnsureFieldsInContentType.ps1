

function EnsureFieldsInContentType {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The content Type Identity.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "Array of field internal names to be ensured.")]
        [string[]] $FieldInternalNames,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate whether to update child content types.")]
        [bool] $UpdateChildren = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts for adding fields.")]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Attempts = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Interval between retry attempts in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $RetryAfterMs = 3000,

        [Parameter(Mandatory = $false, HelpMessage = "Short delay between field additions in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ShortDelay = 300
    )

    # Retrieve the content type
    $contentType = Get-PnPContentType -Identity $ContentTypeIdentity -ErrorAction SilentlyContinue
    if ($null -eq $contentType) {
        Write-Warning "Content Type with ID or Name $ContentTypeIdentity not found"
        exit
    }

    # Retrieve the fields already present in the content type
    $existingFields = $contentType.Fields
    $ctx = Get-PnPContext
    $ctx.Load($existingFields)
    $ctx.ExecuteQuery()

    # Retrieve all fields that need to be ensured in one request
    $fieldsToEnsure = Get-PnPField | Where-Object { $FieldInternalNames -contains $_.InternalName }

    $fieldsAddedCount = 0

    foreach ($fieldInternalName in $FieldInternalNames) {
        # Check if the field is already present in the content type
        $fieldExists = $existingFields | Where-Object { $_.InternalName -eq $fieldInternalName }

        if ($null -ne $fieldExists) {
            Write-Warning "Field $fieldInternalName already exists in Content Type $ContentTypeIdentity" 
            continue
        }

        # Find the retrieved field from the $fieldsToEnsure list
        $field = $fieldsToEnsure | Where-Object { $_.InternalName -eq $fieldInternalName }
        if ($null -eq $field) {
            Write-Warning "Field with internal name $fieldInternalName not found"
            continue
        }

        # Add the field to the content type with retries
        $retryCount = 0
        while ($true) {
            try {
                # Start-Sleep -Milliseconds $ShortDelay  # Wait for a short delay before next field addition
                # Add-PnPFieldToContentType -Field $field -ContentType $contentType -UpdateChildren:$UpdateChildren -ErrorAction Stop
                                
                Start-Sleep -Milliseconds $ShortDelay  # Wait for a short delay before next field addition
                Add-PnPFieldToContentType -Field $field -ContentType $contentType -ErrorAction Stop
                $fieldsAddedCount++  # Increment the counter
                Write-Host "Field $fieldInternalName added to Content Type $ContentTypeIdentity" -ForegroundColor Green
                break
            }
            catch {
                if (++$retryCount -ge $Attempts) {
                    Write-Error "Failed to add field after $Attempts attempts."
                    throw
                }
                else {
                    Write-Warning "Failed to add field. Attempt $retryCount of $Attempts."
                    Start-Sleep -Milliseconds $RetryAfterMs  # Wait for a while before retrying
                }
            }
        }
    }

    if ($fieldsAddedCount -gt 0) {
        Write-Host "$fieldsAddedCount fields added to Content Type $ContentTypeIdentity!" -ForegroundColor Green
    }
}























































































