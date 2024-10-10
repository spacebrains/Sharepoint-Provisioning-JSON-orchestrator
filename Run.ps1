[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)][string]
    $SiteUrl,
    [Parameter(Mandatory = $false)][System.Management.Automation.PSCredential]
    $Credentials = [System.Management.Automation.PSCredential]::Empty
)

$JsonPath = "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\configuration.json"

$ErrorActionPreference = "Stop"
Write-Output "Connect to SharePoint..."

if ($Credentials -eq [System.Management.Automation.PSCredential]::Empty) {
    Write-Warning("Credentials is not provided. Sign in, please!")
    Connect-PnPOnline -Url $SiteUrl -Interactive
}
else {
    Connect-PnPOnline -Url $SiteUrl -Credentials $Credentials 
}

$ErrorActionPreference = "Continue"

$modulePath = "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\JsonScenariosModule\JsonScenariosModule.psm1"
Import-Module $modulePath -Force

RunJsonScenariosOrchestrator -SiteUrl $SiteUrl -JsonPath $JsonPath