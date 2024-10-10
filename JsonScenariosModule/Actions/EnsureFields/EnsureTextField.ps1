# Successful Runs: 
# Failed Runs: 

function EnsureTextField {
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

        [Parameter(Mandatory = $false, HelpMessage = "Flag to enforce unique values for the field.")]
        [bool]$EnforceUniqueValues,

        [Parameter(Mandatory = $false, HelpMessage = "The default value for the field.")]
        [string]$DefaultValue,

        [Parameter(Mandatory = $false, HelpMessage = "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json")]
        [PSCustomObject]$FieldFormatter,

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
        Write-Warning "Text field with name $InternalName already exists!"
        return
    }

    $params = @{
        DisplayName  = $DisplayName
        InternalName = $InternalName
        Type         = "Text"
        Group        = $Group
        Required     = $Required
        Id           = $FieldId
    }

    # Create the field using PnP
    if ($ListIdentity) {
        $createdField = Add-PnPField @params -List $ListIdentity
    }
    else {
        $createdField = Add-PnPField @params
    }

    if ($EnforceUniqueValues -or $DefaultValue -or $FieldFormatter) {
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

    Write-Host "Text field $InternalName created!" -ForegroundColor Green
}























