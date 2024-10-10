function AddListItemsWithLookups {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "./Schemes/AddListItemsWithLookupsData.schema.json")]
        [PSCustomObject[]] $Data,
        
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

    # Assign a GUID to refId for items that do not have refId set
    $Data = $Data | ForEach-Object {
        $itemData = $_
        if ($null -eq $itemData.refId) {
            $itemData = $itemData | Select-Object *, @{Name = 'refId'; Expression = { [guid]::NewGuid().ToString() } }
        }
        return $itemData
    }

    # Create items without setting references and store their IDs
    $createdItems = @{}
    foreach ($itemData in $Data) {
        $listIdentity = $itemData.listIdentity
        $refId = $itemData.refId

        # Convert PSCustomObject to hashtable and skip reference values for now
        $fieldValuesObject = $itemData.fieldValues
        $fieldValues = @{}
        $fieldValuesObject.PSObject.Properties | ForEach-Object {
            $value = $_.Value
            if ($value -is [string] -and $value -match "^ref:") {
                # Skip reference values for now
            }
            elseif ($value -is [array]) {
                $newValue = @()
                foreach ($element in $value) {
                    if ($element -is [string] -and $element -match "^ref:") {
                        # Skip reference values for now
                    }
                    else {
                        $newValue += $element
                    }
                }
                $fieldValues[$_.Name] = $newValue
            }
            else {
                $fieldValues[$_.Name] = $value
            }
        }

        # Add retry logic for creating list item
        $retryCount = 0
        while ($true) {
            try {
                Start-Sleep -Milliseconds $ShortDelay
                $params = @{
                    List   = $listIdentity
                    Values = $fieldValues
                }
                if ($itemData.contentType) {
                    $params.ContentType = $itemData.contentType
                }
                $createdItem = Add-PnPListItem @params
                Write-Host "Item $($createdItem.Id) created successfully" -ForegroundColor Green
                break
            }
            catch {
                if (++$retryCount -ge $Attempts) {
                    Write-Host "Failed to create item $($itemData | ConvertTo-Json -Depth 100) after $Attempts attempts." -ForegroundColor Red
                    throw
                }
                else {
                    Write-Host "Failed to create item $($itemData | ConvertTo-Json -Depth 100). Attempt $retryCount of $Attempts." -ForegroundColor Red
                    Start-Sleep -Milliseconds $RetryAfterMs
                }
            }
        }

        $createdItems[$refId] = $createdItem.Id
    }

    # Now update the items to set the reference fields
    foreach ($itemData in $Data) {
        $listIdentity = $itemData.listIdentity
        $fieldValuesObject = $itemData.fieldValues
        $fieldValues = @{}
        $fieldValuesObject.PSObject.Properties | ForEach-Object {
            $value = $_.Value
            if ($value -is [string] -and $value -match "^ref:") {
                $fieldValues[$_.Name] = $createdItems[$value -replace "^ref:"]
            }
            elseif ($value -is [array]) {
                $newValue = @()
                $referenceReplaced = $false
                foreach ($element in $value) {
                    if ($element -is [string] -and $element -match "^ref:") {
                        $newValue += $createdItems[$element -replace "^ref:"]
                        $referenceReplaced = $true
                    }
                    else {
                        $newValue += $element
                    }
                }
                if ($referenceReplaced) {
                    $fieldValues[$_.Name] = $newValue
                }
            }
        }

        $itemId = $createdItems[$itemData.refId]

        # Add retry logic for updating list item
        $retryCount = 0
        while ($true) {
            try {
                Start-Sleep -Milliseconds $ShortDelay
                Set-PnPListItem -List $listIdentity -Identity $itemId -Values $fieldValues
                Write-Host "Item $itemId updated successfully in $listIdentity" -ForegroundColor Green
                break
            }
            catch {
                if (++$retryCount -ge $Attempts) {
                    Write-Host "Failed to update item $itemId after $Attempts attempts." -ForegroundColor Red
                    throw
                }
                else {
                    Write-Host "Failed to update item $itemId. Attempt $retryCount of $Attempts." -ForegroundColor Red
                    Start-Sleep -Milliseconds $RetryAfterMs
                }
            }
        }
    }
}










