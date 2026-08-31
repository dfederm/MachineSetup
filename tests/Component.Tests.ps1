$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Component.psm1"

Describe "Component defaults" {
    BeforeEach {
        Remove-Module Component -ErrorAction SilentlyContinue
        Import-Module $modulePath -Force -DisableNameChecking
    }

    It "defaults a component without dependencies to an empty dependency list" {
        Set-Content -Path (Join-Path $TestDrive "fixture.ps1") -Value '@{ Name = "Fixture"; Detect = {}; Install = {} }'

        $component = @(Get-AllComponents $TestDrive)[0]

        @($component.DependsOn).Count | Should Be 0
    }

    It "preserves declared dependencies" {
        Set-Content -Path (Join-Path $TestDrive "fixture.ps1") -Value '@{ Name = "Fixture"; DependsOn = @("first", "second"); Detect = {}; Install = {} }'

        $component = @(Get-AllComponents $TestDrive)[0]

        @($component.DependsOn) -join "," | Should Be "first,second"
    }
}
