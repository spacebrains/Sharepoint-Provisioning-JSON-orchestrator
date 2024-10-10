# TODO: Should be tested

Function EnsureTaxonomyField {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The display name of the field.")]
        [string]$DisplayName,

        [Parameter(Mandatory = $true, HelpMessage = "The internal name of the field.")]
        [string]$InternalName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the term group.")]
        [string]$TermGroupName,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the term set.")]
        [string]$TermSetName,

        [Parameter(Mandatory = $false, HelpMessage = "The group the field belongs to.")]
        [string]$Group,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to indicate if the field is required.")]
        [bool]$Required,

        [Parameter(Mandatory = $false, HelpMessage = "Flag to enforce unique values for the field.")]
        [bool]$EnforceUniqueValues,

        [Parameter(Mandatory = $false, HelpMessage = "The default value for the field.")]
        [string]$DefaultValue,

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
        Write-Warning "Taxonomy field with name $InternalName already exists!"
        return
    }

    # Create the field using PnP
    $termSetPath = "$TermGroupName|$TermSetName"
    if ($ListIdentity) {
        $createdField = Add-PnPTaxonomyField -List $ListIdentity -DisplayName $DisplayName -InternalName $InternalName -TermSetPath $termSetPath -Group $Group -Required:$Required -Id $FieldId
    }
    else {
        $createdField = Add-PnPTaxonomyField -DisplayName $DisplayName -InternalName $InternalName -TermSetPath $termSetPath -Group $Group -Required:$Required -Id $FieldId
    }

    if ($EnforceUniqueValues -or $DefaultValue -or $FieldFormatter -Or $MinValue -Or $MaxValue) {
        if ($EnforceUniqueValues) {
            $createdField.Indexed = $true
            $createdField.EnforceUniqueValues = $true
        }

        if ($DefaultValue) {
            $createdField.DefaultValue = $DefaultValue
        }

        if ($FieldFormatter) {
            $createdField.CustomFormatter = $FieldFormatter | ConvertTo-Json -Depth 50
        }
        
        $createdField.Update()
        Invoke-PnPQuery
    }

    Write-Host "Taxonomy field $InternalName created!" -ForegroundColor Green
}
