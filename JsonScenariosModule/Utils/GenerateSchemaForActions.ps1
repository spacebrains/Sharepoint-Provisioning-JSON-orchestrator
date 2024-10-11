# This function creates a JSON schema for the given function, detailing its parameters, types, and other attributes.
function GenerateSchemaForActions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ActionsFolderPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputFolderPath
    )

    # Initialize base schema
    $baseSchema = @{
        '$schema'    = "http://json-schema.org/draft-07/schema#"
        'type'       = "object"
        'properties' = @{
            'attempts'     = @{ 'type' = "integer" }
            'retryAfterMs' = @{ 'type' = "integer" }
            'shortDelay'   = @{ 'type' = "integer" }
            'actions'      = @{
                'type'  = "array"
                'items' = @{}
            }
        }
        'required'   = @("actions")
    }
    $baseSchema.properties.actions.items.oneOf = @()

    # Add the section action type
    $sectionAction = @{
        type       = "object"
        properties = @{
            "type" = @{
                "type" = "string"
                "enum" = @("Section")
            }
            "path" = @{
                "description" = "Path to the configuration file."
                "type"        = "string"
            }
        }
        required   = @("type", "path")
    }
    $baseSchema.properties.actions.items.oneOf += $sectionAction

    # Add the comment action type
    $commentAction = @{
        type       = "object"
        properties = @{
            "type"    = @{
                "type" = "string"
                "enum" = @("Comment")
            }
            "comment" = @{
                "description" = "Text of comment"
                "type"        = "string"
            }
        }
        required   = @("type", "comment")
    }
    $baseSchema.properties.actions.items.oneOf += $commentAction

    # Iterate over each function in Actions folder
    Get-ChildItem -Path $ActionsFolderPath -Filter *.ps1 -Recurse | ForEach-Object {

        # Import the function
        . $_.FullName

        # Extract function name from the path
        $FunctionName = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)

        # Retrieve the function details
        $functionInfo = Get-Command $FunctionName -ErrorAction SilentlyContinue
        if (-not $functionInfo) {
            Write-Error "Function $FunctionName not found."
            return
        }

        # Filter out ootb parameters
        $excludedParameters = @(
            "PipelineVariable",
            "OutBuffer",
            "OutVariable",
            "InformationVariable",
            "WarningVariable",
            "ErrorVariable",
            "InformationAction",
            "WarningAction",
            "ErrorAction",
            "Debug",
            "Verbose", 
            "ProgressAction"
        )
        $parameters = $functionInfo.Parameters.Values | Where-Object { $_.Name -notin $excludedParameters }

        # Initialize the JSON schema
        $jsonSchema = @{
            type       = "object"
            properties = @{
                "type" = @{
                    "type" = "string"
                    "enum" = @($FunctionName)
                }
            }
            required   = @("type")
        }

        # List to store required parameters
        $requiredParameters = New-Object System.Collections.ArrayList

        # Process each parameter to determine its type, description, and other attributes
        foreach ($param in $parameters) {
            ProcessParameter -param $param -jsonSchema $jsonSchema -requiredParameters $requiredParameters
        }

        $jsonSchema.required += $requiredParameters

        # Convert the hashtable to JSON
        $baseSchema.properties.actions.items.oneOf += $jsonSchema
    }

    # Convert to JSON and save
    $jsonContent = $baseSchema | ConvertTo-Json -Depth 100
    $jsonContent = $jsonContent -replace '\\\\n', "\n"
    $outputPath = Join-Path $OutputFolderPath "json-scenarios.scheme.json"
    Set-Content -Path $outputPath -Value $jsonContent

    Write-Host "Schema saved to $outputPath" -ForegroundColor Green
}


# Helper function to process each parameter and update the JSON schema accordingly.
function ProcessParameter {
    param (
        $param,
        $jsonSchema,
        $requiredParameters
    )

    # Determine the base type and potential wrappers like array or nullable
    $baseType, $structure = GetBaseTypeAndStructure -typeName $param.ParameterType.FullName

    # Define type based on base and structure
    $type, $pattern, $itemsType = GetFullTypeDetails -baseType $baseType -structure $structure

    # Construct the property schema
    $propertyDetails = @{
        type        = $type
        description = "No description."
    }

    # Retrieve the description
    $paramAttributes = $param.Attributes | Where-Object { $_.GetType().Name -eq "ParameterAttribute" }
    if ($paramAttributes -and $paramAttributes.HelpMessage) {
        if ($paramAttributes.HelpMessage.EndsWith(".schema.json")) {
            # If HelpMessage is a schema link, set the $ref property and exit early
            $propertyDetails = @{
                '$ref' = $paramAttributes.HelpMessage
            }
 
            # Set the property and exit
            $propertyName = ($param.Name.Substring(0, 1).ToLower() + $param.Name.Substring(1))
            $jsonSchema.properties[$propertyName] = $propertyDetails
            return
        }
        else {
            $propertyDetails.description = $paramAttributes.HelpMessage
        }
    }

    # Check for ValidateRange attribute
    $rangeAttribute = $param.Attributes | Where-Object { $_.GetType().Name -eq "ValidateRangeAttribute" }
    if ($rangeAttribute) {
        $propertyDetails.minimum = $rangeAttribute.MinRange
        $propertyDetails.maximum = $rangeAttribute.MaxRange
    }

    # Check for ValidatePattern attribute
    $patternAttribute = $param.Attributes | Where-Object { $_.GetType().Name -eq "ValidatePatternAttribute" }
    if ($patternAttribute) {
        $propertyDetails.pattern = $patternAttribute.RegexPattern
    }
    elseif ($baseType -eq "System.Guid") {
        $propertyDetails.pattern = "^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$"
    }


    # Handle enum values
    if ($param.Attributes.ValidValues) {
        if ($type -eq "integer") {
            # Convert strings to integers if the base type is integer
            $propertyDetails.enum = $param.Attributes.ValidValues | ForEach-Object { [int]$_ }
        }
        else {
            $propertyDetails.enum = $param.Attributes.ValidValues
        }
    }

    if ($pattern) {
        $propertyDetails.pattern = $pattern
    }
    
    if ($itemsType) {
        $propertyDetails.items = @{ type = $itemsType }
    }

    # Make sure the property name starts with a lowercase letter
    $propertyName = ($param.Name.Substring(0, 1).ToLower() + $param.Name.Substring(1))
    $jsonSchema.properties[$propertyName] = $propertyDetails
    if ($paramAttributes -and $paramAttributes.Mandatory -eq $true) {
        $requiredParameters.Add($propertyName)
    }
}

# Determines the base type and potential structures (like Array or Nullable) of a given type.
function GetBaseTypeAndStructure {
    param (
        [string]$typeName
    )

    # Regex patterns
    $arrayPattern = '^(.*)\[\]$'
    $nullablePattern = '^System\.Nullable`1\[\[(.*?)(?:,.*?)*\]\]$'

    # Check for array
    if ($typeName -match $arrayPattern) {
        return $matches[1], 'Array'
    }
    # Check for nullable
    elseif ($typeName -match $nullablePattern) {
        return $matches[1], 'Nullable'
    }
    else {
        return $typeName, $null
    }
}


# Determines the full type, including potential patterns, based on the base type and structure.
function GetFullTypeDetails {
    param (
        [string]$baseType,
        [string]$structure
    )

    # Extract the primary type name (without assembly details)
    $primaryType = ($baseType -split ',')[0]

    # Determine the base type
    switch ($primaryType) {
        "System.Boolean" { $type = "boolean" }
        "System.Int32" { $type = "integer" }
        "System.String" { $type = "string" }
        "System.Guid" {
            $type = "string"
        }
        "System.Double" { $type = "integer" }
        "System.Management.Automation.PSObject" { $type = "object" }
    }

    # Modify the base type if there's a structure (like Array or Nullable)
    switch ($structure) {
        'Array' {
            $itemsType = $type
            $type = 'array'
        }
        'Nullable' {
            $type = $type
        }
    }

    return $type, $pattern, $itemsType
}

$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    
# Define constants
$ActionsFolderPath = Join-Path (Split-Path $scriptPath) "Actions"  
$OutputFolderPath = Split-Path $scriptPath 

# Run the function
GenerateSchemaForActions -ActionsFolderPath $ActionsFolderPath -OutputFolderPath $OutputFolderPath