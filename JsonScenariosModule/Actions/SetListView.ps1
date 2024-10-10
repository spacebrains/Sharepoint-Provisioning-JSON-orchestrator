

function SetListView {
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The identity of the list.")]
        [string] $ListIdentity,
        
        [Parameter(Mandatory = $false, HelpMessage = "The name of the view. If not specified, the default view will be used.")]
        [string] $ViewName,
        
        [Parameter(Mandatory = $false, HelpMessage = "Fields to be included in the view.")]
        [string[]] $Fields = @(),
        
        [Parameter(Mandatory = $false, HelpMessage = "./Schemes/Aggregations.schema.json")]
        [PSCustomObject[]] $Aggregations = @(),
        
        [Parameter(Mandatory = $false, HelpMessage = "Number of rows to be displayed in a page.")]
        [Nullable[int]] $RowLimit = 30,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specifies whether the view is the default view.")]
        [Nullable[bool]] $IsDefault,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specifies whether the view is a personal view.")]
        [Nullable[bool]] $IsPersonal,
        
        [Parameter(Mandatory = $false, HelpMessage = "The OrderBy fields for sorting.")]
        [string[]] $OrderByFields = @(),
        
        [Parameter(Mandatory = $false, HelpMessage = "The GroupBy fields for grouping.")]
        [string[]] $GroupByFields = @(),

        [Parameter(Mandatory = $false, HelpMessage = "Specifies whether to append fields to the view or overwrite them.")]
        [Nullable[bool]] $AppendFields = $false
    )
    
    # Get the list
    $list = Get-PnPList -Identity $ListIdentity -ErrorAction Stop
    
    # If ViewName is not specified, use the default view
    if (-not $ViewName) {
        Get-PnPProperty -ClientObject $list.DefaultView -Property Title
        $ViewName = $list.DefaultView.Title
    }
        
    # Check if the view already exists
    $view = Get-PnPView -List $list -Identity $ViewName -ErrorAction SilentlyContinue
        
    # If appending fields, get the current fields and append the new ones, avoiding duplicates
    if ($AppendFields -and $null -ne $view) {
        $Fields = $view.ViewFields + ($Fields | Where-Object { $_ -notin $view.ViewFields })
    }
        
    
    # Construct the Aggregations string
    $aggregationsString = -join ($Aggregations | ForEach-Object {
            "<FieldRef Name='$($_.fieldInternalName)' Type='$($_.type)' />"
        })
    
    # Construct the OrderBy and GroupBy strings
    $orderByString = if ($OrderByFields) {
        "<OrderBy>" + 
        ($OrderByFields | ForEach-Object { "<FieldRef Name='$_' />" }) + 
        "</OrderBy>"
    }
    
    $groupByString = if ($GroupByFields) {
        "<GroupBy>" + 
        ($GroupByFields | ForEach-Object { "<FieldRef Name='$_' />" }) + 
        "</GroupBy>"
    }
    
    # Combine OrderBy and GroupBy strings to form the ViewQuery
    $viewQuery = $orderByString + $groupByString

    if ($null -eq $view) {
        # Create a new view
        Write-Warning "Creating view $ViewName in list $ListIdentity"
        Add-PnPView -List $list -Title $ViewName -Fields $Fields -Aggregations $aggregationsString -RowLimit $RowLimit -SetAsDefault:$IsDefault -Personal:$IsPersonal -Query $viewQuery
    }
    else {
        # Update the existing view
        Write-Warning "Updating view $ViewName in list $ListIdentity"
        $values = @{
            RowLimit    = [UInt32]$RowLimit
            DefaultView = $IsDefault
            ViewQuery   = $viewQuery
        }
        if ($aggregationsString) {
            $values["Aggregations"] = $aggregationsString
        }
        Set-PnPView -List $list -Identity $ViewName -Fields $Fields -Values $values
    }
    
    Write-Host "View $ViewName in list $ListIdentity has been set successfully" -ForegroundColor Green
}



























































































