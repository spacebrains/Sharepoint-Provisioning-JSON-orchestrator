[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, HelpMessage = "The URL of the SharePoint site where the operations will be executed.")]
    [string]$SiteUrl,

    [Parameter(Mandatory = $true, HelpMessage = "The client ID of the application. Neccessary for authentication.")]
    [string]$ClientId,

    [Parameter(Mandatory = $false)][System.Management.Automation.PSCredential]
    $Credentials = [System.Management.Automation.PSCredential]::Empty
)

$JsonPath = "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\configuration.json"

$ErrorActionPreference = "Stop"
Write-Output "Connect to SharePoint..."

if ($Credentials -eq [System.Management.Automation.PSCredential]::Empty) {
    Write-Warning("Credentials is not provided. Sign in, please!")
    Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Interactive
}
else {
    Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Credentials $Credentials 
}

$ErrorActionPreference = "Continue"

$modulePath = "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\JsonScenariosModule\JsonScenariosModule.psm1"
Import-Module $modulePath -Force

RunJsonScenariosOrchestrator -JsonPath $JsonPath