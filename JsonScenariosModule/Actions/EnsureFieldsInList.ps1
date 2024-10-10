function EnsureFieldsInList {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The identity of the list.")]
        [string] $ListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "Array of field internal names to be ensured.")]
        [string[]] $FieldInternalNames,

        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts for adding items.")]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Attempts = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Interval between retry attempts in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $RetryAfterMs = 3000,

        [Parameter(Mandatory = $false, HelpMessage = "Short delay between item additions in milliseconds.")]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ShortDelay = 300
    )

    # Retrieve the list
    $list = Get-PnPList -Identity $ListIdentity -ErrorAction SilentlyContinue
    if ($null -eq $list) {
        Write-Warning "List with URL, ID, or Name $ListIdentity not found"
        exit
    }

    # Retrieve the fields already present in the list
    $existingFields = $list.Fields
    $ctx = Get-PnPContext
    $ctx.Load($existingFields)
    $ctx.ExecuteQuery()

    foreach ($fieldInternalName in $FieldInternalNames) {
        # Check if the field is already present in the list
        $fieldExists = $existingFields | Where-Object { $_.InternalName -eq $fieldInternalName }
    
        if ($null -ne $fieldExists) {
            Write-Warning "Field $fieldInternalName already exists in List $ListIdentity"
            continue
        }
    
        # Retrieve the field
        $field = Get-PnPField -Identity $fieldInternalName -ErrorAction SilentlyContinue
        if ($null -eq $field) {
            Write-Warning "Field with internal name $fieldInternalName not found"
            continue
        }
    
        # Add the field to the list with retries
        $retryCount = 0
        while ($true) {
            try {
                Start-Sleep -Milliseconds $ShortDelay  # Wait for a while before next field addition
                Add-PnPField -Field $field -List $list -ErrorAction Stop
                Write-Host "Field $fieldInternalName added to List $ListIdentity" -ForegroundColor Green
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

    Write-Host "Fields for list $ListIdentity created!" -ForegroundColor Green
}




















