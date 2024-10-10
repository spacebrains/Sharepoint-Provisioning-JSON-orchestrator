function AddFolder {
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The name of the new folder to create.")]
        [string] $Name,

        [Parameter(Mandatory = $true, HelpMessage = "The relative URL of the parent folder where the new folder will be created.")]
        [string] $ParentFolderPath
    )

    try {
        # Construct the full folder path
        $fullFolderPath = "$ParentFolderPath/$Name"

        # Check if the folder already exists
        $existingFolder = Get-PnPFolder -RelativeUrl $fullFolderPath -ErrorAction SilentlyContinue
        if ($existingFolder) {
            Write-Warning "Folder '$fullFolderPath' already exists."
            return
        }

        # Create the folder
        Add-PnPFolder -Name $Name -Folder $ParentFolderPath -ErrorAction Stop
        Write-Host "Folder '$Name' created in '$ParentFolderPath'" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create folder '$Name'. Error: $_"
        throw
    }
}














