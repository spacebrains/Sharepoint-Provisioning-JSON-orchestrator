function SetLookupFieldsFromChoiceFieldsBatch {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identifier (ID, Title, or Url) of the list where the items to be updated are located.")]
        [string] $ListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "./Schemes/SetLookupFieldsFromChoiceFieldsLookupListMapping.schema.json")]
        [PSCustomObject] $LookupListMapping,

        [Parameter(Mandatory = $true, HelpMessage = "./Schemes/SetLookupFieldsFromChoiceFieldsMappingData.schema.json")]
        [PSCustomObject[]] $MappingData,
        
        [Parameter(Mandatory = $false, HelpMessage = "Optional. The identifier of the content type to filter the items to be updated. If not specified, all items in the list will be updated.")]
        [string] $ContentTypeIdentity,
        [Parameter(Mandatory = $false, HelpMessage = "Optional. If true, includes active posts, otherwise all posts")]
        [bool] $ActiveOnly = $false
    )

    Write-Host "Starting to process items in list $ListIdentity..." -ForegroundColor Green
    if ($ActiveOnly) {
        Write-Host "Only active ideas will be processed!" -ForegroundColor Green
    }
    
    # Retrieve all list items matching ContentTypeIdentity if provided
    $list = Get-PnPList -Identity $ListIdentity
    $listContentTypes = Get-PnPContentType -List $list
    $contentTypeId = ($listContentTypes | Where-Object { $_.Name -eq $ContentTypeIdentity }).Id.StringValue

    $listItems = Get-PnpListItem -List $ListIdentity -PageSize 5000
    if ($ContentTypeIdentity) { 
        $listItems = $listItems | Where-Object { $_.FieldValues.FSObjType -eq 0 -and $_.FieldValues.ContentTypeId.StringValue -eq $contentTypeId }
        if ($ActiveOnly) {
            $listItems = $listItems | Where-Object { $_.FieldValues.FileDirRef.EndsWith("ArchivedIdeas") -eq $false }
        }

    }
    else {
        $listItems = $listItems | Where-Object { $_.FieldValues.FSObjType -eq 0 }
        if ($ActiveOnly) {
            $listItems = $listItems | Where-Object { $_.FieldValues.FileDirRef.EndsWith("ArchivedIdeas") -eq $false }
        }
    } 
  

    if ($ActiveOnly) {
        Write-Host "Loaded $($listItems.Count) active ideas from the list." -ForegroundColor Green
    }
    else {
        Write-Host "Loaded $($listItems.Count)  ideas from the list." -ForegroundColor Green
    }

    # Load all items from each lookup list and store them in a dictionary
    $refItems = @{}
    foreach ($entry in $LookupListMapping.PSObject.Properties) {
        $lookupField = $entry.Name
        $lookupList = $entry.Value
    
        $allItemsInList = Get-PnPListItem -List $lookupList -PageSize 5000
        $refItems[$lookupField] = @{}
        foreach ($item in $allItemsInList) {
            $refItems[$lookupField][$item['Title']] = $item
        }
    }

    Write-Host "Loaded reference items for lookup fields." -ForegroundColor Green


    # Update list items using the mapping data
    foreach ($item in $listItems) {
        $updateValues = @{}
        Write-Host "Processing item with ID: $($item.Id)" -ForegroundColor Green

        foreach ($itemChoiceField in $item.FieldValues.Keys) {
         
            try {
                $correspondingMapping = $MappingData | Where-Object { $_.choiceField -eq $itemChoiceField }
                if ($correspondingMapping) {
                
                    # If there's a mapping with a specific choiceValue, use it
                    $specificMapping = $correspondingMapping | Where-Object { $_.choiceValue -eq $item[$itemChoiceField] -and $null -ne $item[$itemChoiceField] }
                    if ($specificMapping) {
                        $lookupField = $specificMapping.lookupField
                        $lookupValue = $specificMapping.lookupValue                
                        $refItem = $refItems[$lookupField][$lookupValue]
                        if ($refItem) {
                            $updateValues[$lookupField] = $refItem.Id
                            Write-Host "Updated field $lookupField using specific mapping to value: $lookupValue" -ForegroundColor Green
                            continue
                        }                        
                    }

                    # If there's no mapping with a specific choiceValue but there's a general mapping for the choiceField, use it for auto-update
                    $generalMapping = $correspondingMapping | Where-Object { -not $_.choiceValue }
                    if ($generalMapping) {                    
                        $lookupField = $generalMapping.lookupField
                        $lookupValue = $item[$itemChoiceField]
                        if ($null -ne $lookupValue ) {
                            $refItem = $refItems[$lookupField][$lookupValue]
                            if ($refItem) {
                                $updateValues[$lookupField] = $refItem.Id
                                Write-Host "Updated field $lookupField using general mapping to value: $lookupValue" -ForegroundColor Green
                            }
                        }
                    }
                    else {
                        Write-warning "The $($itemChoiceField) field was not mapped with lookup for idea $($item.Id)."
                    }
                }
            }
            catch {
                Write-warning  $_.Exception
                Write-warning "The $($lookupField) field was not updated for idea $($item.Id)."
            }
        }

        # Update the list item if there are any values to update
        if ($updateValues.Keys.Count -gt 0) {
            $updateValues["_ModerationStatus"] = 0
            
            Set-PnPListItem -List $ListIdentity -Identity $item.Id -Values $updateValues 
            Write-Host "Batched update and published for item ID: $($item.Id)" -ForegroundColor Green
        }
     
    }
}
