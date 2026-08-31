$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Elevation.psm1"

Describe "Elevated PowerShell host" {
    BeforeEach {
        Remove-Module Elevation -ErrorAction SilentlyContinue
        Import-Module $modulePath -Force
    }

    InModuleScope Elevation {
        It "starts the elevated child with the PowerShell 7 executable from PSHOME" {
            $script:startedExecutable = $null
            Mock Test-Elevated { $false }
            Mock Set-Content {}
            Mock Remove-Item {}
            Mock Start-Process {
                $script:startedExecutable = $FilePath
                return [pscustomobject] @{ ExitCode = 0 }
            }

            Invoke-Elevated -ScriptBlock '$true' | Should Be $true

            $script:startedExecutable | Should Be (Join-Path $PSHOME "pwsh.exe")
        }
    }
}
