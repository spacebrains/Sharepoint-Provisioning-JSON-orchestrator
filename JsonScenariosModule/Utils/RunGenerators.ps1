$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    
# Define constants
$ActionsFolderPath = Join-Path (Split-Path $scriptPath) "Actions"  
$OutputFolderPath = Split-Path $scriptPath 

# Load the GenerateSchemaForActions function
. (Join-Path $scriptPath "GenerateSchemaForActions.ps1")

# Run the function
GenerateSchemaForActions -ActionsFolderPath $ActionsFolderPath -OutputFolderPath $OutputFolderPath