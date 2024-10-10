# TODO: Should be tested

function EnsureCalculatedField {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The display name of the field.")]
        [string]$DisplayName,

        [Parameter(Mandatory = $true, HelpMessage = "The internal name of the field.")]
        [string]$InternalName,

        [Parameter(Mandatory = $true, HelpMessage = "The formula for the calculated field.")]
        [string]$Formula,

        [Parameter(Mandatory = $true, HelpMessage = "The result type of the calculated field.")]
        [ValidateSet("Text", "DateTime", "Number", "Currency", "Boolean")]
        [string]$ResultType,

        [Parameter(Mandatory = $false, HelpMessage = "The group the field belongs to.")]
        [string]$Group,

        [Parameter(Mandatory = $false, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity,

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
        Write-Warning "Calculated field with name $InternalName already exists!"
        return
    }

    $params = @{
        DisplayName  = $DisplayName
        InternalName = $InternalName
        Type         = "Calculated"
        Group        = $Group
        Id           = $FieldId
        Formula      = $Formula
        ResultType   = $ResultType
    }

    # Create the field using PnP
    if ($ListIdentity) {
        $createdField = Add-PnPField @params -List $ListIdentity   
    }
    else {
        $createdField = Add-PnPField @params
    }

    if ($FieldFormatter) {
        $createdField.CustomFormatter = $FieldFormatter | ConvertTo-Json -Depth 50
        $createdField.Update()
        Invoke-PnPQuery
    }

    Write-Host "Calculated field $InternalName created!" -ForegroundColor Green
}
