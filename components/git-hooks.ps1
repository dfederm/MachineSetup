$source = Join-Path (Split-Path $PSScriptRoot -Parent) "config\git\hooks"
$target = Join-Path $env:USERPROFILE ".config\git\machinesetup-hooks"
$mappings = @(@{ Source = $source; Target = $target })

@{
    Name        = "Git hooks"
    Description = "Deploy user-level Git hooks and configure the global hooks path"
    Category    = "Dev"
    DependsOn   = @("git")
    Detect      = {
        (git config --global --get core.hooksPath 2>$null) -eq $target -and
            (Test-FileDeployment $mappings)
    }.GetNewClosure()
    Install     = {
        Install-FileDeployment $mappings
        git config --global core.hooksPath $target
        if ($LASTEXITCODE -ne 0)
        {
            throw "Failed to configure global Git hooks path"
        }
    }.GetNewClosure()
}
