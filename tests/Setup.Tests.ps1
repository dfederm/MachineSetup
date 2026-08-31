$setupPath = Join-Path (Split-Path $PSScriptRoot -Parent) "setup.ps1"
$jsonSettingsPath = Join-Path (Split-Path $PSScriptRoot -Parent) "lib\JsonSettings.psm1"

Describe "Setup runtime requirements" {
    It "requires PowerShell 7.4" {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($setupPath, [ref] $tokens, [ref] $errors)

        @($errors).Count | Should Be 0
        $ast.ScriptRequirements.RequiredPSVersion | Should Be ([version] "7.4")
    }

    It "keeps the JSON settings module on the same PowerShell baseline" {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($jsonSettingsPath, [ref] $tokens, [ref] $errors)

        @($errors).Count | Should Be 0
        $ast.ScriptRequirements.RequiredPSVersion | Should Be ([version] "7.4")
    }

    It "throws when one or more components fail" {
        $content = Get-Content $setupPath -Raw

        $content | Should Match 'if \(\$failed -gt 0\)\s*\{\s*Write-Error "\$failed component\(s\) failed"\s*throw "Machine setup failed\."'
    }
}
