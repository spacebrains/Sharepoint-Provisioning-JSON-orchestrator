function RemoveFieldsFromSiteColumns {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Array of field internal names to be removed.")]
        [string[]] $FieldInternalNames,

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

    # Get all fields in the site columns
    $allFields = Get-PnPField -ErrorAction SilentlyContinue

    foreach ($fieldInternalName in $FieldInternalNames) {
        # Check if the field exists in the retrieved list of fields
        $existedField = $allFields | Where-Object { $_.InternalName -eq $fieldInternalName }

        if ($null -eq $existedField) {
            Write-Warning "Field with internal name $fieldInternalName not found"
            continue
        }

        # Remove the field from site columns with retries
        $attemptCount = 0
        while ($attemptCount -lt $Attempts) {
            try {
                Remove-PnPField -Identity $existedField.InternalName -Force -ErrorAction Stop
                Write-Host "Field $fieldInternalName removed from Site Columns" -ForegroundColor Green
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

    Write-Host "$($FieldInternalNames.Count) Fields removed from Site Columns" -ForegroundColor Green
}














