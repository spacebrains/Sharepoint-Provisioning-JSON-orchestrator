function EnsureUserField {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The display name of the field.")]
        [string]$DisplayName,

        [Parameter(Mandatory = $true, HelpMessage = "The internal name of the field.")]
        [string]$InternalName,

        [Parameter(Mandatory = $false, HelpMessage = "The group the field belongs to.")]
        [string]$Group,

        [Parameter(Mandatory = $false, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the field is required.")]
        [bool]$Required,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the field allows multiple users.")]
        [bool]$AllowMultipleValues,

        [Parameter(Mandatory = $false, HelpMessage = "The GUID for the field.")]
        [ValidatePattern("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$")]
        [guid]$FieldId = [guid]::NewGuid(),

        [Parameter(Mandatory = $false, HelpMessage = "Flag to enforce unique values for the field.")]
        [bool]$EnforceUniqueValues,

        [Parameter(Mandatory = $false, HelpMessage = "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json")]
        [string]$FieldFormatter,

        [Parameter(Mandatory = $true, HelpMessage = "User selection mode.")]
        [ValidateSet("PeopleOnly", "PeopleAndGroups")]
        [string]$UserSelectionMode
    )

    # Check for field existence
    if ($ListIdentity) {
        $existingField = Get-PnPField -List $ListIdentity -Identity $InternalName -ErrorAction SilentlyContinue
    }
    else {
        $existingField = Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue
    }
    
    $SelectionModeAttribute = "User"
    if ($AllowMultipleValues) {
        $SelectionModeAttribute = "UserMulti" 
    }

    if ($existingField) {
        Write-Warning "$SelectionModeAttribute field with name $InternalName already exists!"
        return
    }

    # Create the field using PnP
    $FieldSchema = "<Field Type='$SelectionModeAttribute' DisplayName='$DisplayName' List='UserInfo' Required='$($Required.ToString().ToUpper())' EnforceUniqueValues='$($EnforceUniqueValues.ToString().ToUpper())' Mult='$($AllowMultipleValues.ToString().ToUpper())' ShowField='ImnName' UserSelectionMode='$UserSelectionMode' ID='{$FieldId}' StaticName='$InternalName' Name='$InternalName' Group='$Group' ColName='int1' RowOrdinal='0' Indexed='$($EnforceUniqueValues.ToString().ToUpper())' />" 
 
    if ($ListIdentity) {
        $createdField = Add-PnPFieldFromXml -List $ListIdentity -FieldXml $FieldSchema
    }
    else {
        $createdField = Add-PnPFieldFromXml -FieldXml $FieldSchema
    }
 
    # Update the field with additional settings, if applicable
    if ($FieldFormatter) {
        $createdField = Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue
        $createdField.CustomFormatter = $FieldFormatter | ConvertTo-Json -Depth 50
 
        $createdField.Update()
        Invoke-PnPQuery
    }

    Write-Host "$SelectionModeAttribute field $InternalName created!" -ForegroundColor Green
}




















