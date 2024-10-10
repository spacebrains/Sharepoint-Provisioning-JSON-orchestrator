function EnsureDateField {
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

        [Parameter(Mandatory = $true, HelpMessage = "The date format: DateOnly or DateTime.")]
        [ValidateSet("DateOnly", "DateTime")]
        [string]$DateFormat,

        [Parameter(Mandatory = $true, HelpMessage = "The friendly display format: Relative or Disabled.")]
        [ValidateSet("Relative", "Disabled")]
        [string]$FriendlyDisplayFormat,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the field is required.")]
        [bool]$Required,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to enforce unique values for the field.")]
        [bool]$EnforceUniqueValues,

        [Parameter(Mandatory = $false, HelpMessage = "The default value for the field (in ISO format: YYYY-MM-DD or YYYY-MM-DDTHH:mm:ss).")]
        [ValidatePattern("^\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2})?$")]
        [string]$DefaultValue,

        [Parameter(Mandatory = $false, HelpMessage = "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json")]
        [string]$FieldFormatter,

        [Parameter(Mandatory = $false, HelpMessage = "The GUID for the field.")]
        [ValidatePattern("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$")]
        [guid]$FieldId = [guid]::NewGuid()
    )

    # Check for field existence
    if ($ListIdentity) {
        $existingField = Get-PnPField -List $ListIdentity -Identity $InternalName -ErrorAction SilentlyContinue
    }
    else {
        $existingField = Get-PnPField -Identity $InternalName -ErrorAction SilentlyContinue
    }
    
    if ($existingField) {
        Write-Warning "Date field with name $InternalName already exists!"
        return
    }

    $fieldSchema = "<Field Type='DateTime' ID='{$FieldId}' Name='$InternalName' StaticName='$InternalName' DisplayName='$DisplayName' Format='$DateFormat' Required='$($Required.ToString().ToUpper())' EnforceUniqueValues='$($EnforceUniqueValues.ToString().ToUpper())' FriendlyDisplayFormat='$FriendlyDisplayFormat' Group='$Group'/>"

    if ($ListIdentity) {
        $createdField = Add-PnPFieldFromXml -FieldXml $fieldSchema -List $ListIdentity
    }
    else {
        $createdField = Add-PnPFieldFromXml -FieldXml $fieldSchema
    }
    
    if ($DefaultValue -or $FieldFormatter) {
        if ($DefaultValue) {
            $createdField.DefaultValue = $DefaultValue
        }
    
        if ($FieldFormatter) {
            $createdField.CustomFormatter = $FieldFormatter | ConvertTo-Json -Depth 50
        }
    
        $createdField.Update()
        Invoke-PnPQuery
    }

    Write-Host "Date field $InternalName created!" -ForegroundColor Green
}















