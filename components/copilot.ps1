$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceDir = Join-Path $repoRoot "config\agents"
$canonicalSkillDir = Join-Path $sourceDir "skills\clean-local-branches"
$legacySkillDir = "$env:USERPROFILE\.copilot\skills\clean-local-branches"

$mappings = @(
    @{
        Source = Join-Path $sourceDir "AGENTS.md"
        Target = "$env:USERPROFILE\.copilot\copilot-instructions.md"
    }
    @{
        Source = Join-Path $sourceDir "AGENTS.md"
        Target = "$env:USERPROFILE\.config\opencode\AGENTS.md"
    }
    @{
        Source = Join-Path $sourceDir "skills"
        Target = "$env:USERPROFILE\.agents\skills"
    }
    @{
        Source = Join-Path $sourceDir "harnesses\copilot\lsp-config.json"
        Target = "$env:USERPROFILE\.copilot\lsp-config.json"
    }
)

$testLegacySkillMatchesCanonical = {
    if (-not (Test-Path -LiteralPath $legacySkillDir -PathType Container))
    {
        return $false
    }

    $legacyItem = Get-Item -LiteralPath $legacySkillDir -Force
    if ($legacyItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
    {
        return $false
    }

    $sourceFiles = @(Get-ChildItem -LiteralPath $canonicalSkillDir -File -Recurse)
    $legacyFiles = @(Get-ChildItem -LiteralPath $legacySkillDir -File -Recurse)
    if ($sourceFiles.Count -ne $legacyFiles.Count)
    {
        return $false
    }

    foreach ($sourceFile in $sourceFiles)
    {
        $relativePath = [System.IO.Path]::GetRelativePath($canonicalSkillDir, $sourceFile.FullName)
        $legacyFile = Join-Path $legacySkillDir $relativePath
        if (-not (Test-Path -LiteralPath $legacyFile -PathType Leaf) -or
            (Get-FileHash -LiteralPath $sourceFile.FullName).Hash -ne
                (Get-FileHash -LiteralPath $legacyFile).Hash)
        {
            return $false
        }
    }

    return $true
}.GetNewClosure()

@{
    Name        = "Agent assets"
    Description = "Deploy shared agent instructions and skills with harness-specific adapters"
    Category    = "Dev"
    Detect      = {
        (Test-FileDeployment $mappings) -and
            -not (& $testLegacySkillMatchesCanonical)
    }.GetNewClosure()
    Install     = {
        Install-FileDeployment $mappings
        if (& $testLegacySkillMatchesCanonical)
        {
            Remove-Item -LiteralPath $legacySkillDir -Recurse -Force
        }
        elseif (Test-Path -LiteralPath $legacySkillDir)
        {
            Write-Warning "Preserving non-matching legacy skill directory: $legacySkillDir"
        }
    }.GetNewClosure()
}
