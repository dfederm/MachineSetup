$markerFile = "$env:LocalAppData\MachineSetup\.defender-exclusion"

@{
    Name        = "Defender Exclusion for CodeDir"
    Description = "Exclude CodeDir from Windows Defender scanning"
    Category    = "System"
    DependsOn   = @("codedir")
    Detect      = {
        $codeDir = [Environment]::GetEnvironmentVariable("CodeDir", "User")
        if (-not $codeDir) { return $false }
        # Reading Defender exclusions requires elevation, so use a marker file instead
        if (-not (Test-Path $markerFile)) { return $false }
        return (Get-Content $markerFile -Raw).Trim() -eq $codeDir
    }.GetNewClosure()
    Install     = {
        $codeDir = [Environment]::GetEnvironmentVariable("CodeDir", "User")
        if (-not $codeDir)
        {
            throw "CodeDir is not set. Install the CodeDir component first."
        }

        Write-Message "Excluding CodeDir from Defender"
        Invoke-Elevated "Add-MpPreference -ExclusionPath '$codeDir'"

        $markerDir = Split-Path $markerFile
        if (-not (Test-Path $markerDir)) { New-Item -ItemType Directory -Path $markerDir -Force > $null }
        Set-Content -Path $markerFile -Value $codeDir
    }.GetNewClosure()
}
