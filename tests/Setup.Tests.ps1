$setupPath = Join-Path (Split-Path $PSScriptRoot -Parent) "setup.ps1"

Describe "Setup runtime requirements" {
    It "requires PowerShell 7" {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($setupPath, [ref] $tokens, [ref] $errors)

        @($errors).Count | Should Be 0
        $ast.ScriptRequirements.RequiredPSVersion.Major | Should Be 7
    }

    It "throws when one or more components fail" {
        $content = Get-Content $setupPath -Raw

        $content | Should Match 'if \(\$failed -gt 0\)\s*\{\s*Write-Error "\$failed component\(s\) failed"\s*throw "Machine setup failed\."'
    }
}
