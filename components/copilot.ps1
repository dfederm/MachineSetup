$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceDir = Join-Path $repoRoot "config\copilot"
$targetDir = "$env:USERPROFILE\.copilot"

$mappings = @(
    @{ Source = $sourceDir; Target = $targetDir }
)

@{
    Name        = "Copilot"
    Description = "Deploy user-level Copilot instructions and skills"
    Category    = "Dev"
    Detect      = { Test-FileDeployment $mappings }.GetNewClosure()
    Install     = { Install-FileDeployment $mappings }.GetNewClosure()
}
