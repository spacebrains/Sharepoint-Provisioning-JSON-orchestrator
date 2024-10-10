Function SetIndexedFieldsInList {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The list title or ID.")]
        [string] $ListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "Array of field internal names to be indexed.")]
        [string[]] $IndexedFieldInternalNames,

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts for indexing fields.")]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Attempts = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Interval between retry attempts in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $RetryAfterMs = 3000,
        
        [Parameter(Mandatory = $false, HelpMessage = "Short delay between field updates in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ShortDelay = 300
    )

    # Function to update the index status of a field
    function UpdateIndexStatus {
        param(
            [Parameter(Mandatory = $true)]
            $field,

            [Parameter(Mandatory = $true)]
            [bool] $shouldBeIndexed
        )

        $retryCount = 0
        while ($true) {
            try {
                Start-Sleep -Milliseconds $ShortDelay  # Wait a bit

                # Check if field's current indexed state matches desired state
                if ($field.Indexed -eq $shouldBeIndexed) {
                    Write-Host "Field $($field.InternalName) indexed state is already set to $($shouldBeIndexed) in List $ListIdentity" -ForegroundColor DarkGreen
                    return
                }

                # Set or unset the field as indexed
                $field.Indexed = $shouldBeIndexed
                $field.UpdateAndPushChanges($true)
                $ctx.ExecuteQuery()

                Write-Host "Field $($field.InternalName) indexed state set to $($shouldBeIndexed) in List $ListIdentity" -ForegroundColor Green
                return
            }
            catch {
                if (++$retryCount -ge $Attempts) {
                    Write-Error "Failed to update indexed state of field $($field.InternalName) after $Attempts attempts."
                    return
                }
                else {
                    Write-Warning "Failed to update indexed state of field $($field.InternalName). Attempt $retryCount of $Attempts."
                    Start-Sleep -Milliseconds $RetryAfterMs  # Wait a while before retrying
                }
            }
        }
    }

    # Retrieve the list
    $list = Get-PnPList -Identity $ListIdentity -ErrorAction SilentlyContinue
    if ($null -eq $list) {
        Write-Warning "List with Title or ID $ListIdentity not found"
        return
    }

    # Retrieve all fields within the list
    $listFields = $list.Fields
    $ctx = Get-PnPContext
    $ctx.Load($listFields)
    $ctx.ExecuteQuery()

    # Get currently indexed fields
    $indexedFields = $listFields | Where-Object { $_.Indexed -eq $true }

    # Iterate through each field to be indexed
    foreach ($fieldName in $IndexedFieldInternalNames) {
        $field = $listFields | Where-Object { $_.InternalName -eq $fieldName }
        if ($null -ne $field) {
            UpdateIndexStatus $field $true
        }
    }

    # Iterate through each currently indexed field to unindex if not in the list
    foreach ($field in $indexedFields) {
        if ($IndexedFieldInternalNames -notcontains $field.InternalName) {
            UpdateIndexStatus $field $false
        }
    }
}






























