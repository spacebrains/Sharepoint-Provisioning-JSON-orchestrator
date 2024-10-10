

function EnsureLookupField {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The display name of the field.")]
        [string]$DisplayName,

        [Parameter(Mandatory = $true, HelpMessage = "The internal name of the field.")]
        [string]$InternalName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the lookup list.")]
        [string]$LookupListIdentity,

        [Parameter(Mandatory = $true, HelpMessage = "The internal name of the field in the lookup list.")]
        [string]$LookupField,

        [Parameter(Mandatory = $false, HelpMessage = "The group the field belongs to.")]
        [string]$Group,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the field is required.")]
        [bool]$Required,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to enforce unique values for the field.")]
        [bool]$EnforceUniqueValues,

        [Parameter(Mandatory = $false, HelpMessage = "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json")]
        [string]$FieldFormatter,

        [Parameter(Mandatory = $false, HelpMessage = "The GUID for the field.")]
        [ValidatePattern("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$")]
        [guid]$FieldId = [guid]::NewGuid(),

        [Parameter(Mandatory = $false, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the field allows multiple values.")]
        [bool]$AllowMultipleValues
    )

    # Check for field existence
    if ($ListIdentity) {
        $existingField = Get-PnPField -List $ListIdentity -Identity $InternalName -ErrorAction SilentlyContinue
    }
    else {
        $existingField = Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue
    }

    if ($existingField) {
        Write-Warning "Lookup field with name $InternalName already exists!"
        return
    }

    # Retrieve the list by its identifier
    $lookupList = Get-PnPList -Identity $LookupListIdentity -ErrorAction SilentlyContinue

    # Check if the list exists
    if ($null -eq $lookupList) {
        Write-Error "Lookup list with identity $LookupListIdentity does not exist!"
        return
    }

    # Get the GUID of the list
    $lookupListId = $lookupList.Id

    # Create the field schema XML
    $fieldSchema = "<Field Type='Lookup' ID='{$FieldId}' Name='$InternalName' StaticName='$InternalName' DisplayName='$DisplayName' List='{$lookupListId}' ShowField='$LookupField' Required='$($Required.ToString().ToUpper())' EnforceUniqueValues='$($EnforceUniqueValues.ToString().ToUpper())' Group='$Group'></Field>"

    if ($ListIdentity) {
        $createdField = Add-PnPFieldFromXml -FieldXml $fieldSchema -List $ListIdentity
    }
    else {
        $createdField = Add-PnPFieldFromXml -FieldXml $fieldSchema
    }

    if ($FieldFormatter -or $AllowMultipleValues) {
        if ($FieldFormatter) {
            $createdField.CustomFormatter = $FieldFormatter | ConvertTo-Json -Depth 50
            $createdField.Update()
        }
        if ($AllowMultipleValues) {
            $createdField.AllowMultipleValues = $AllowMultipleValues
            $createdField.Update()  
        }
        
        Invoke-PnPQuery
    }

    Write-Host "Lookup field $InternalName created!" -ForegroundColor Green
}










































