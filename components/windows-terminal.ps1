$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceFile = Join-Path $repoRoot "config\terminal-settings.json"

$getTargetDir = {
    $pkg = Get-AppxPackage Microsoft.WindowsTerminal
    if ($pkg) { return "$env:LocalAppData\Packages\$($pkg.PackageFamilyName)\LocalState" }
    return $null
}

@{
    Name        = "Windows Terminal"
    Description = "Install Windows Terminal and deploy settings"
    Category    = "Apps"
    Detect      = {
        if (-not (Test-WinGetPackage "Microsoft.WindowsTerminal")) { return $false }

        if (-not (Test-Path $sourceFile)) { return $false }

        $targetDir = & $getTargetDir
        if (-not $targetDir) { return $false }

        $targetFile = Join-Path $targetDir "settings.json"
        if (-not (Test-Path $targetFile)) { return $false }

        return (Get-Content $sourceFile -Raw) -eq (Get-Content $targetFile -Raw)
    }.GetNewClosure()
    Install     = {
        if (-not (Install-WinGetPackage "Microsoft.WindowsTerminal")) { throw "Failed to install Microsoft.WindowsTerminal" }

        $targetDir = & $getTargetDir
        if (-not $targetDir)
        {
            Write-Warning "Windows Terminal package directory not found, skipping settings deployment"
            return
        }

        Copy-Item -Path $sourceFile -Destination "$targetDir\settings.json" -Force
    }.GetNewClosure()
}
