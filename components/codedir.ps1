@{
    Name        = "CodeDir"
    Description = "Configure CodeDir environment variable and NuGet paths"
    Category    = "System"
    Detect      = {
        $codeDir = [Environment]::GetEnvironmentVariable("CodeDir", "User")
        if (-not $codeDir) { return $false }
        if (-not (Test-Path $codeDir)) { return $false }
        $nugetPkgs = [Environment]::GetEnvironmentVariable("NUGET_PACKAGES", "User")
        $nugetHttp = [Environment]::GetEnvironmentVariable("NUGET_HTTP_CACHE_PATH", "User")
        return ($nugetPkgs -eq "$codeDir\.nuget") -and ($nugetHttp -eq "$codeDir\.nuget\.http")
    }
    Install     = {
        $codeDir = $env:CodeDir
        if (-not $codeDir)
        {
            $codeDir = Read-Host "Where is your code directory located?"
        }

        if (-not (Test-Path $codeDir))
        {
            New-Item -Path $codeDir -ItemType Directory > $null
        }

        Set-EnvironmentVariable -Name "CodeDir" -Value $codeDir
        Set-EnvironmentVariable -Name "NUGET_PACKAGES" -Value "$codeDir\.nuget"
        Set-EnvironmentVariable -Name "NUGET_HTTP_CACHE_PATH" -Value "$codeDir\.nuget\.http"
    }
}
