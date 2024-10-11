# # TODO: Refactor this function
# Function EnsureTerms {
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true, HelpMessage = "The name of the term group.")]
#         [string] $termGroupName,

#         [Parameter(Mandatory = $true, HelpMessage = "The name of the term set.")]
#         [string] $termSetName,

#         [Parameter(Mandatory = $true, HelpMessage = "Array of term names to be created.")]
#         [string[]] $termNames,

#         [Parameter(Mandatory = $false, HelpMessage = "Maximum number of retry attempts for term creation.")]
#         [int] $maxRetries = 5,

#         [Parameter(Mandatory = $false, HelpMessage = "Interval between retry attempts in milliseconds.")]
#         [int] $retryInterval = 500
#     )

#     # Check if the term group exists
#     $termGroup = Get-PnPTermGroup -Identity $termGroupName -ErrorAction SilentlyContinue

#     if ($null -eq $termGroup) {
#         # finish script
#         Write-Host "Term group not found"
#         exit
#     }

#     # Check if the term set exists
#     $termSet = Get-PnPTermSet -Identity $termSetName -TermGroup $termGroupName -ErrorAction SilentlyContinue

#     if ($null -eq $termSet) {
#         # Create a new term set
#         $termSet = New-PnPTermSet -TermGroup $termGroupName -Name $termSetName
#     }

#     # Get the existing terms
#     $existingTerms = Get-PnPTerm -TermSet $termSetName -TermGroup $termGroupName -ErrorAction SilentlyContinue | ForEach-Object { 
#         $termName = [string]$_.Name.Replace("＆", "&")
#         $termName = $termName -replace '\s+', ' '
#         $termName
#     }
    
#     foreach ($termName in $termNames) {
#         $termName = $termName.Replace("＆", "&")
#         $termName = $termName -replace '\s+', ' '
        
#         if ($termName -notin $existingTerms) {
#             $retryCount = 0
#             while ($true) {
#                 try {
#                     Start-Sleep -Milliseconds $retryInterval  # Wait for a while before next term creation
#                     New-PnPTerm -TermSet $termSetName -TermGroup $termGroupName -Name $termName -ErrorAction Stop
#                     break
#                 }
#                 catch {
#                     if (++$retryCount -ge $maxRetries) {
#                         Write-Error "Failed to create term after $maxRetries attempts."
#                         throw
#                     }
#                     else {
#                         Write-Warning "Failed to create term. Attempt $retryCount of $maxRetries."
#                         Start-Sleep -Milliseconds $retryInterval  # Wait for a while before retrying
#                     }
#                 }
#             }
#         }
#     }

#     Write-Host "Terms for term group $termGroupName and term set $termSetName created!" -ForegroundColor Green
# }
