Function EnsureYesNoField {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The display name of the field.")]
        [string]$DisplayName,

        [Parameter(Mandatory = $true, HelpMessage = "The internal name of the field.")]
        [string]$InternalName,

        [Parameter(Mandatory = $false, HelpMessage = "The group the field belongs to.")]
        [string]$Group,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the field is required.")]
        [bool]$Required,

        [Parameter(Mandatory = $false, HelpMessage = "The default value for the field.")]
        [bool]$DefaultValue,

        [Parameter(Mandatory = $false, HelpMessage = "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json")]
        [string]$FieldFormatter,

        [Parameter(Mandatory = $false, HelpMessage = "The GUID for the field.")]
        [ValidatePattern("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$")]
        [guid]$FieldId = [guid]::NewGuid(),

        [Parameter(Mandatory = $false, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity
    )

    # Check for field existence
    if ($ListIdentity) {
        $existingField = Get-PnPField -List $ListIdentity -Identity $InternalName -ErrorAction SilentlyContinue
    }
    else {
        $existingField = Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue
    }

    if ($existingField) {
        Write-Warning "Yes/No field with name $InternalName already exists!" 
        return
    }

    $fieldSchema = "<Field Type='Boolean' ID='{$FieldId}' Name='$InternalName' StaticName='$InternalName' DisplayName='$DisplayName' Group='$Group'><Default>$($(if($DefaultValue){1}else{0}))</Default></Field>"

    if ($ListIdentity) {
        $createdField = Add-PnPFieldFromXml -FieldXml $fieldSchema -List $ListIdentity
    }
    else {
        $createdField = Add-PnPFieldFromXml -FieldXml $fieldSchema
    }


    if ($FieldFormatter) {
        $createdField.CustomFormatter = $FieldFormatter | ConvertTo-Json -Depth 50
        $createdField.Update()
        Invoke-PnPQuery
    }

    Write-Host "Yes/No field $InternalName created!" -ForegroundColor Green
}











