$repoRoot = Split-Path $PSScriptRoot -Parent
$bootstrapPath = Join-Path $repoRoot "bootstrap.ps1"

. $bootstrapPath

function Get-BootstrapExceptionMessage
{
    param (
        [Parameter(Mandatory)]
        [scriptblock] $Action
    )

    try
    {
        & $Action
        return $null
    }
    catch
    {
        return $_.Exception.Message
    }
}

Describe "PowerShell 7.4 executable validation" {
    It "rejects an older PowerShell 7 runtime" {
        $candidate = Join-Path $TestDrive "pwsh-7.3.cmd"
        Set-Content -Path $candidate -Encoding Ascii -Value "@echo 7.3.9"

        Test-PowerShell7Executable $candidate | Should Be $false
    }

    It "accepts the minimum PowerShell runtime" {
        $candidate = Join-Path $TestDrive "pwsh-7.4.cmd"
        Set-Content -Path $candidate -Encoding Ascii -Value "@echo 7.4.0"

        Test-PowerShell7Executable $candidate | Should Be $true
    }
}

Describe "PowerShell 7.4 discovery" {
    It "returns the first candidate that launches PowerShell 7.4 or newer" {
        Mock Get-PowerShell7Candidates { @("invalid-pwsh.exe", "valid-pwsh.exe") }
        Mock Test-PowerShell7Executable { $Path -eq "valid-pwsh.exe" }

        Resolve-PowerShell7Executable | Should Be "valid-pwsh.exe"
    }

    It "returns null when no candidate launches PowerShell 7.4 or newer" {
        Mock Get-PowerShell7Candidates { @("invalid-pwsh.exe") }
        Mock Test-PowerShell7Executable { $false }

        Resolve-PowerShell7Executable | Should Be $null
    }

}

Describe "PowerShell 7 installation" {
    It "passes the stable package arguments to WinGet" {
        $capturePath = Join-Path $TestDrive "winget-arguments.txt"
        $wingetPath = Join-Path $TestDrive "winget.cmd"
        $previousCapturePath = $env:MACHINESETUP_WINGET_CAPTURE

        try
        {
            $env:MACHINESETUP_WINGET_CAPTURE = $capturePath
            Set-Content -Path $wingetPath -Encoding Ascii -Value @"
@echo off
echo %* > "%MACHINESETUP_WINGET_CAPTURE%"
exit /b 0
"@

            Invoke-WinGetPowerShellInstall $wingetPath | Should Be 0
            (Get-Content $capturePath -Raw).Trim() | Should Be "install --id Microsoft.PowerShell --exact --source winget --silent --accept-package-agreements --accept-source-agreements"
        }
        finally
        {
            $env:MACHINESETUP_WINGET_CAPTURE = $previousCapturePath
        }
    }

    It "requires WinGet when PowerShell 7 is absent" {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq "winget.exe" }

        Get-BootstrapExceptionMessage { Install-PowerShell7 } | Should Match "WinGet is unavailable.*App Installer"
    }

    It "accepts a successful WinGet installation" {
        Mock Get-Command { [pscustomobject] @{ Source = "winget.exe"; Path = "winget.exe" } } -ParameterFilter { $Name -eq "winget.exe" }
        Mock Invoke-WinGetPowerShellInstall { 0 }

        { Install-PowerShell7 } | Should Not Throw
    }

    It "accepts the WinGet already-installed result" {
        Mock Get-Command { [pscustomobject] @{ Source = "winget.exe"; Path = "winget.exe" } } -ParameterFilter { $Name -eq "winget.exe" }
        Mock Invoke-WinGetPowerShellInstall { -1978335135 }

        { Install-PowerShell7 } | Should Not Throw
    }

    It "surfaces WinGet installation failures" {
        Mock Get-Command { [pscustomobject] @{ Source = "winget.exe"; Path = "winget.exe" } } -ParameterFilter { $Name -eq "winget.exe" }
        Mock Invoke-WinGetPowerShellInstall { 37 }

        Get-BootstrapExceptionMessage { Install-PowerShell7 } | Should Match "exit code 37"
    }
}

Describe "Bootstrap orchestration" {
    It "uses an existing PowerShell 7 runtime without reinstalling it" {
        Mock Resolve-PowerShell7Executable { "C:\PowerShell\pwsh.exe" }
        Mock Install-PowerShell7 {}
        Mock Invoke-DownloadedSetup {}

        Invoke-MachineSetupBootstrap -SetupArguments @("-IsForWork", "-DetectOnly")

        Assert-MockCalled Install-PowerShell7 0
        Assert-MockCalled Invoke-DownloadedSetup 1 -ParameterFilter {
            $PowerShellPath -eq "C:\PowerShell\pwsh.exe" -and
            $SetupArguments.Count -eq 2 -and
            $SetupArguments[0] -eq "-IsForWork" -and
            $SetupArguments[1] -eq "-DetectOnly"
        }
    }

    It "installs and re-resolves PowerShell 7 when it is absent" {
        $script:resolveCalls = 0
        Mock Resolve-PowerShell7Executable {
            $script:resolveCalls++
            if ($script:resolveCalls -eq 1) { return $null }
            return "C:\PowerShell\pwsh.exe"
        }
        Mock Install-PowerShell7 {}
        Mock Invoke-DownloadedSetup {}

        Invoke-MachineSetupBootstrap

        Assert-MockCalled Install-PowerShell7 1
        Assert-MockCalled Resolve-PowerShell7Executable 2
        Assert-MockCalled Invoke-DownloadedSetup 1
    }

    It "fails when installed PowerShell 7 cannot be launched" {
        Mock Resolve-PowerShell7Executable { $null }
        Mock Install-PowerShell7 {}
        Mock Invoke-DownloadedSetup {}

        Get-BootstrapExceptionMessage { Invoke-MachineSetupBootstrap } | Should Match "pwsh.exe could not be launched"
        Assert-MockCalled Invoke-DownloadedSetup 0 -Scope It
    }
}

Describe "Bootstrap process status" {
    It "preserves the setup exit code when bootstrap is invoked as a process" {
        $fixturePath = Join-Path $TestDrive "bootstrap-entry-point.ps1"
        $escapedBootstrapPath = $bootstrapPath -replace "'", "''"
        Set-Content -Path $fixturePath -Encoding Utf8 -Value @"
. '$escapedBootstrapPath'
function Invoke-MachineSetupBootstrap
{
    `$exception = New-Object System.Exception('fixture failure')
    `$exception.Data['ExitCode'] = 23
    throw `$exception
}
Invoke-BootstrapEntryPoint -ExitProcess
"@
        $currentPowerShellPath = (Get-Process -Id $PID).Path

        & $currentPowerShellPath -NoProfile -File $fixturePath

        $LASTEXITCODE | Should Be 23
    }
}

Describe "PowerShell setup invocation" {
    BeforeAll {
        $powerShellPath = (Get-Command pwsh.exe -CommandType Application).Source
    }

    It "forwards setup arguments in order" {
        $outputPath = Join-Path $TestDrive "arguments.txt"
        $setupPath = Join-Path $TestDrive "capture-arguments.ps1"
        Set-Content -Path $setupPath -Encoding Utf8 -Value @'
param (
    [string] $OutputPath,
    [Parameter(ValueFromRemainingArguments)]
    [string[]] $Values
)
[IO.File]::WriteAllLines($OutputPath, $Values)
'@

        Invoke-PowerShellSetup -PowerShellPath $powerShellPath -SetupScript $setupPath -SetupArguments @("-OutputPath", $outputPath, "first", "two words") | Should Be 0
        @(Get-Content $outputPath) -join "|" | Should Be "first|two words"
    }

    It "returns the child exit code" {
        $setupPath = Join-Path $TestDrive "fail.ps1"
        Set-Content -Path $setupPath -Encoding Utf8 -Value "exit 23"

        Invoke-PowerShellSetup -PowerShellPath $powerShellPath -SetupScript $setupPath | Should Be 23
    }
}

Describe "Downloaded setup lifecycle" {
    BeforeEach {
        Mock Invoke-WebRequest {}
        Mock Expand-Archive {
            $archiveRoot = Join-Path $DestinationPath "MachineSetup-main"
            New-Item -Path $archiveRoot -ItemType Directory | Out-Null
            Set-Content -Path (Join-Path $archiveRoot "setup.ps1") -Value "# fixture"
        }
    }

    It "forwards arguments and removes the temporary directory after success" {
        Mock Invoke-PowerShellSetup { 0 }

        Invoke-DownloadedSetup -PowerShellPath "pwsh.exe" -SetupArguments @("-DetectOnly") -TempRoot $TestDrive

        Assert-MockCalled Invoke-PowerShellSetup 1 -ParameterFilter {
            $SetupArguments.Count -eq 1 -and $SetupArguments[0] -eq "-DetectOnly"
        }
        Test-Path (Join-Path $TestDrive "MachineSetup") | Should Be $false
    }

    It "surfaces child failure and removes the temporary directory" {
        Mock Invoke-PowerShellSetup { 19 }

        Get-BootstrapExceptionMessage { Invoke-DownloadedSetup -PowerShellPath "pwsh.exe" -TempRoot $TestDrive } | Should Match "exit code 19"
        Test-Path (Join-Path $TestDrive "MachineSetup") | Should Be $false
    }
}
