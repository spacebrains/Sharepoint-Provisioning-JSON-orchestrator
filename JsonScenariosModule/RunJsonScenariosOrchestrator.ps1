function RunJsonScenariosOrchestrator {
    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $true, HelpMessage = "The file path that contains the JSON actions and parameters to be executed.")]
        [string]$JsonPath
    )

    # ---------------
    # VALIDATION BLOCK
    # ---------------
    

    if ([string]::IsNullOrEmpty($JsonPath)) {
        Write-Error "JsonPath is not provided!" -ErrorAction Stop
    }

    if (-Not (Test-Path -Path $JsonPath -PathType Leaf)) {
        Write-Error "The file at path $JsonPath does not exist!" -ErrorAction Stop
    }

    try {
        $jsonContent = Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to parse JSON content from $JsonPath. Please check the file format." -ErrorAction Stop
    }

    # ---------------------
    # DEFAULT VALUES BLOCK
    # ---------------------
    
    # Set the default values for retryAfterMs and shortDelay if not provided
    $retryAfterMs = if ($null -ne $jsonContent.retryAfterMs) { $jsonContent.retryAfterMs } else { 3000 } # Default value
    $shortDelay = if ($null -ne $jsonContent.shortDelay) { $jsonContent.shortDelay } else { 300 } # Default value
    $maxAttempts = if ($null -ne $jsonContent.attempts) { $jsonContent.attempts } else { 3 } # Default value
  
    # ---------------
    # ACTIONS BLOCK
    # ---------------

    # Initialize success flag
    $success = $true

    # Iterate through each action in the JSON content
    foreach ($action in $jsonContent.actions) {
        Write-Host "$($action.type) is processing!" -ForegroundColor Cyan
        Write-Host ($action | ConvertTo-Json -Depth 100) -ForegroundColor DarkCyan

        # reset success flag
        $success = $true

        $functionName = $action.type
        $arguments = @{}

        # Check if the action type is 'Section'
        if ($functionName -eq "Section") {
            # Construct the path for the section configuration file
            $sectionPath = $action.path -replace "/", '\'
            $baseDirectory = [System.IO.Path]::GetDirectoryName($JsonPath)
            $sectionJsonPath = [System.IO.Path]::Combine($baseDirectory, $sectionPath)
            $sectionJsonPath = [System.IO.Path]::GetFullPath($sectionJsonPath)
        
            # Execute the orchestrator for the section
            $result = RunJsonScenariosOrchestrator -JsonPath $sectionJsonPath
            if ($result -eq "failed") {
                Write-Host "Aborting due to failure in a nested section." -ForegroundColor Red
                return "failed"
            }
            continue
        }

        # Check if the action type is 'Comment'
        if ($functionName -eq "Comment") {
            $comment = $action.comment
            Write-Host "Comment: $comment" -ForegroundColor Magenta
            continue
        }
        
        # Retrieve function information
        $functionInfo = Get-Command -Name $functionName -CommandType Function
        if (-not $functionInfo) {
            Write-Host "Function $functionName not found!" -ForegroundColor Red
            continue
        }
        
        # Forming the argument list for the function
        $arguments = @{}
        $action.PSObject.Properties | Where-Object { $_.Name -ne "type" } | ForEach-Object {
            if ($null -ne $_.Value) {
                # Convert the first letter of the property name to uppercase (to match function parameter naming convention)
                $paramName = $_.Name.Substring(0, 1).ToUpper() + $_.Name.Substring(1)
                $arguments[$paramName] = $_.Value
            }
        }
        
        # Check if the function has its own retry logic by inspecting its parameters
        $hasInternalRetryLogic = ($functionInfo.Parameters.ContainsKey("RetryAfterMs") -and
            $functionInfo.Parameters.ContainsKey("ShortDelay") -and
            $functionInfo.Parameters.ContainsKey("Attempts"))
        
        # Execute the action with retries if there's no internal retry logic in the function
        if (-not $hasInternalRetryLogic) {
            $attempts = 0
            while ($attempts -lt $maxAttempts) {
                try {
                    # Invoke the function
                    $ErrorActionPreference = "Stop"
                    & $functionName @arguments
                    $ErrorActionPreference = "Continue"
                    break
                }
                catch {
                    $attempts++
                    $success = $false
                    Write-Host "Attempt $attempts of $($maxAttempts) failed for action $functionName. Retrying in $($retryAfterMs)ms..." -ForegroundColor Red
                    Write-Host "$_" -ForegroundColor Red
                    Start-Sleep -Milliseconds $retryAfterMs
                }
            }
        }
        else {
            # If the function has internal retry logic, simply call the function
            try {     
                # Invoke the function
                $ErrorActionPreference = "Stop"
                & $functionName @arguments
                $ErrorActionPreference = "Continue"
            }
            catch {
                $success = $false
                Write-Host "Action $functionName failed." -ForegroundColor Red
                Write-Host "$_" -ForegroundColor Red
            }
        }
        
        # Log the result of the action
        if ($attempts -eq $maxAttempts) {
            Write-Host "Action $functionName failed after $($maxAttempts) attempts."  -ForegroundColor Red
        }
      
        
        # If the action failed, break out of the loop
        if (-not $success) {
            break
        }
        
        # Pause before processing the next action
        Start-Sleep -Milliseconds $shortDelay
    }
     
    if (-not $success) {
        return "failed"
    }
}
