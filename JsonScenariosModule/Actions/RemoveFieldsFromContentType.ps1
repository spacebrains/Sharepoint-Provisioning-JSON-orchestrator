function RemoveFieldsFromContentType {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The content Type Identity.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "Array of field internal names to be removed.")]
        [string[]] $FieldInternalNames,

        [Parameter(Mandatory = $false, HelpMessage = "Do not update child content types.")]
        [bool] $DoNotUpdateChildren = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts for removing fields.")]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Attempts = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Interval between retry attempts in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $RetryAfterMs = 3000,

        [Parameter(Mandatory = $false, HelpMessage = "Short delay between field removals in milliseconds.")]
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

    foreach ($fieldInternalName in $FieldInternalNames) {
        # Check if the field is present in the content type
        $existedField = $existingFields | Where-Object { $_.InternalName -eq $fieldInternalName }

        if ($null -eq $existedField) {
            Write-Warning "Field $fieldInternalName does not exist in Content Type $ContentTypeIdentity"
            continue
        }

        # Remove the field from the content type with retries
        $attemptCount = 0
        while ($attemptCount -lt $Attempts) {
            try {
                Remove-PnPFieldFromContentType -Field $fieldInternalName -ContentType $contentType -DoNotUpdateChildren:$DoNotUpdateChildren -ErrorAction Stop
                Write-Host "Field $fieldInternalName removed from Content Type $ContentTypeIdentity" -ForegroundColor Green
                break
            }
            catch {
                $attemptCount++
                if ($attemptCount -ge $Attempts) {
                    Write-Error "Failed to remove field $fieldInternalName after $Attempts attempts."
                    throw
                }
                else {
                    Write-Warning "Failed to remove field $fieldInternalName. Attempt $attemptCount of $Attempts. Retrying in $($RetryAfterMs)ms..."
                    Start-Sleep -Milliseconds $RetryAfterMs
                }
            }
        }

        # Short delay before the next field removal
        Start-Sleep -Milliseconds $ShortDelay
    }

    Write-Host "$($FieldInternalNames.Count) Fields removed from Content Type $ContentTypeIdentity" -ForegroundColor Green
}








