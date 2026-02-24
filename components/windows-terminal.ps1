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

        return Test-FileDeployment @(@{ Source = $sourceFile; Target = (Join-Path $targetDir "settings.json") })
    }.GetNewClosure()
    Install     = {
        if (-not (Install-WinGetPackage "Microsoft.WindowsTerminal")) { throw "Failed to install Microsoft.WindowsTerminal" }

        $targetDir = & $getTargetDir
        if (-not $targetDir)
        {
            Write-Warning "Windows Terminal package directory not found, skipping settings deployment"
            return
        }

        Install-FileDeployment @(@{ Source = $sourceFile; Target = (Join-Path $targetDir "settings.json") })
    }.GetNewClosure()
}
