function ReflectLookups {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identity of the source list from which the lookup values are taken.")]
        [string] $ListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "The identity of the target list to which the lookup values will be reflected.")]
        [string] $TargetListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "Internal name of the lookup fields in the source list that need to be reflected to the target list.")]
        [string] $LookupFieldInternalNames,

        [Parameter(Mandatory = $true, HelpMessage = "Internal name of the lookup field in the target list that will store the reflected lookup value from the source list.")]
        [string] $TargetLookupFieldName,

        [Parameter(Mandatory = $false, HelpMessage = "Content type identity of the items in the source list.")]
        [string] $ContentTypeIdentity,

        [Parameter(Mandatory = $false, HelpMessage = "Content type identity of the items in the target list.")]
        [string] $TargetContentTypeIdentity
    )

    $list = Get-PnPList -Identity $ListIdentity
    $listContentTypes = Get-PnPContentType -List $list
    $contentTypeId = ($listContentTypes | Where-Object { $_.Name -eq $ContentTypeIdentity }).Id.StringValue

    $listItems = Get-PnpListItem -List $ListIdentity -PageSize 5000
    if ($ContentTypeIdentity) { 
        $sourceListItems = $listItems | Where-Object { $_.FieldValues.FSObjType -eq 0 -and $_.FieldValues.ContentTypeId.StringValue -eq $contentTypeId }
    }
    else {
        $sourceListItems = $listItems | Where-Object { $_.FieldValues.FSObjType -eq 0 }
    } 
  
  
    foreach ($sourceListItem in $sourceListItems) {
        # Extract the lookup value from the source item
        $lookupValue = $sourceListItem[$LookupFieldInternalNames]

        if ($null -ne $lookupValue) {
            $targetListItemId = $lookupValue.LookupId         
            $fieldValues = @{
                $TargetLookupFieldName = $sourceListItem.Id
            }
            Set-PnPListItem -List $TargetListIdentity -Id $targetListItemId -Values $fieldValues          
            Write-Host "Comment item with ID '$($targetListItemId)' updated!" -ForegroundColor Green
        }
        else {
            Write-Host "Idea has not associated comment item!" -ForegroundColor Green
        }
    }
}





