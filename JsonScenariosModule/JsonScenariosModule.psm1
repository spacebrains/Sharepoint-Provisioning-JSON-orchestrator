# Import all the functions from the Actions directory
Get-ChildItem -Path "$($PSScriptRoot)\Actions" -Filter *.ps1 -Recurse | ForEach-Object {
    . $_.FullName
}

# Import the RunJsonScenariosOrchestrator function
. "$($PSScriptRoot)\RunJsonScenariosOrchestrator.ps1"

# Import the RunJsonScenariosOrchestrator function
. "$($PSScriptRoot)\Utils\GetFunctionHashValue.ps1"