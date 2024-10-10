function GetFunctionHashValue {
    param (
        [Parameter(Mandatory = $true)]
        [string] $FilePath
    )

    try {
        $fileContent = Get-Content -Path $FilePath -Raw

        # Remove everything before the function definition
        $fileContent = ($fileContent -split '(?=[Ff]unction \w+ {)')[-1]
        $fileContent = $fileContent -replace '\s+$', ''        

        $hasher = [System.Security.Cryptography.MD5]::Create()
        $hashBytes = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($fileContent))
        return [BitConverter]::ToString($hashBytes) -replace '-'
    }
    catch {
        Write-Error "Failed to compute hash for $FilePath."
        return $null
    }
}
