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
        $workFiles = Get-ChildItem -Path $workBinDir -Recurse -File
        foreach ($file in $workFiles)
        {
            $relativePath = $file.FullName.Substring($workBinDir.Length)
            $targetPath = Join-Path $binDir $relativePath
            if (-not (Test-Path $targetPath)) { return $false }
            if ((Get-Content $file.FullName -Raw) -ne (Get-Content $targetPath -Raw)) { return $false }
        }
        return $true
    }.GetNewClosure()
    Install     = {
        $binDir = $env:BinDir
        if (-not $binDir)
        {
            throw "BinDir is not set. Install the BinDir component first."
        }

        if (-not (Test-Path $workBinDir)) { return }

        Copy-Item -Path "$workBinDir\*" -Destination $binDir -Recurse -Force
    }.GetNewClosure()
}
