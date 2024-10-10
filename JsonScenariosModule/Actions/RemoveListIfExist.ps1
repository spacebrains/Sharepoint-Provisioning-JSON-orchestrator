# TODO: Should be tested

function RemoveListIfExist {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identity of the list.")]
        [string]$ListIdentity
    )

    $List = Get-PnPList -Identity $ListIdentity -ErrorAction SilentlyContinue
    
    if ($List) {
        # If the list exists, delete it
        Remove-PnPList -Identity $List -Force
    }
    else {
        Write-Warning "List does not exist!"
    }
}
