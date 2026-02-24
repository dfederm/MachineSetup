$repoRoot = Split-Path $PSScriptRoot -Parent
$workBinDir = Join-Path $repoRoot "work\bin"

@{
    Name        = "BinDir (Work)"
    Description = "Deploy work-specific bin files to BinDir"
    Category    = "System"
    Scope       = "work"
    DependsOn   = @("bindir")
    Detect      = {
        $binDir = [Environment]::GetEnvironmentVariable("BinDir", "User")
        if (-not $binDir) { return $false }
        if (-not (Test-Path $workBinDir)) { return $true }
        return Test-FileDeployment @(@{ Source = $workBinDir; Target = $binDir })
    }.GetNewClosure()
    Install     = {
        $binDir = $env:BinDir
        if (-not $binDir)
        {
            throw "BinDir is not set. Install the BinDir component first."
        }

        if (-not (Test-Path $workBinDir)) { return }

        Install-FileDeployment @(@{ Source = $workBinDir; Target = $binDir })
    }.GetNewClosure()
}
