$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceFile = Join-Path $repoRoot "config\terminal-settings.json"

$getTargetDir = {
    $pkg = Get-AppxPackage Microsoft.WindowsTerminal
    if ($pkg) { return "$env:LocalAppData\Packages\$($pkg.PackageFamilyName)\LocalState" }
    return $null
}

# Determine the desired settings content, preferring VS Canary over Insiders when available
$getSettingsContent = {
    $content = Get-Content $sourceFile -Raw
    $canaryBat = "$env:ProgramFiles\Microsoft Visual Studio\18\Canary\Common7\Tools\VsDevCmd.bat"
    if (Test-Path $canaryBat)
    {
        $content = $content -replace '\\Insiders\\', '\Canary\'
    }
    return $content
}.GetNewClosure()

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

        $expectedContent = & $getSettingsContent
        $actualContent = Get-Content $targetFile -Raw
        return $expectedContent -eq $actualContent
    }.GetNewClosure()
    Install     = {
        if (-not (Install-WinGetPackage "Microsoft.WindowsTerminal")) { throw "Failed to install Microsoft.WindowsTerminal" }

        $targetDir = & $getTargetDir
        if (-not $targetDir)
        {
            Write-Warning "Windows Terminal package directory not found, skipping settings deployment"
            return
        }

        $targetFile = Join-Path $targetDir "settings.json"
        $content = & $getSettingsContent
        $targetParent = Split-Path $targetFile -Parent
        if (-not (Test-Path $targetParent)) { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
        Set-Content -Path $targetFile -Value $content -NoNewline
    }.GetNewClosure()
}
