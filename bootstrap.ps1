$ErrorActionPreference = "Stop"
$script:MinimumPowerShellVersion = [version] "7.4"

function Get-PowerShell7Candidates
{
    $candidates = @()
    $command = Get-Command pwsh.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command)
    {
        $candidates += $command.Source
    }

    if ($env:LOCALAPPDATA)
    {
        $candidates += Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\pwsh.exe"
    }

    if ($env:ProgramFiles)
    {
        $candidates += Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe"
    }

    return $candidates | Where-Object { $_ } | Select-Object -Unique
}

function Test-PowerShell7Executable
{
    param (
        [Parameter(Mandatory)]
        [string] $Path
    )

    try
    {
        $versionOutput = & $Path -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
        if ($LASTEXITCODE -ne 0)
        {
            return $false
        }

        $version = $null
        return [version]::TryParse([string] ($versionOutput | Select-Object -Last 1), [ref] $version) -and
            $version -ge $script:MinimumPowerShellVersion
    }
    catch
    {
        return $false
    }
}

function Resolve-PowerShell7Executable
{
    foreach ($candidate in Get-PowerShell7Candidates)
    {
        if (Test-PowerShell7Executable $candidate)
        {
            return $candidate
        }
    }

    return $null
}

function Invoke-WinGetPowerShellInstall
{
    param (
        [Parameter(Mandatory)]
        [string] $WinGetPath
    )

    & $WinGetPath install --id Microsoft.PowerShell --exact --source winget --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    return $LASTEXITCODE
}

function Install-PowerShell7
{
    $winget = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $winget)
    {
        throw "PowerShell 7.4 or newer is not installed and WinGet is unavailable. Install or register Microsoft App Installer, then run MachineSetup again."
    }

    $wingetPath = if ($winget.Source) { $winget.Source } else { $winget.Path }
    $exitCode = Invoke-WinGetPowerShellInstall $wingetPath

    # APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED
    if ($exitCode -ne 0 -and $exitCode -ne -1978335135)
    {
        throw "WinGet failed to install Microsoft.PowerShell (exit code $exitCode)."
    }
}

function Invoke-PowerShellSetup
{
    param (
        [Parameter(Mandatory)]
        [string] $PowerShellPath,
        [Parameter(Mandatory)]
        [string] $SetupScript,
        [object[]] $SetupArguments = @()
    )

    & $PowerShellPath -NoProfile -File $SetupScript @SetupArguments
    return $LASTEXITCODE
}

function Invoke-DownloadedSetup
{
    param (
        [Parameter(Mandatory)]
        [string] $PowerShellPath,
        [object[]] $SetupArguments = @(),
        [string] $TempRoot = [System.IO.Path]::GetTempPath()
    )

    $tempDir = Join-Path $TempRoot "MachineSetup"
    $zipPath = Join-Path $tempDir "bundle.zip"

    try
    {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $tempDir -ItemType Directory | Out-Null

        $previousProgressPreference = $ProgressPreference
        try
        {
            $ProgressPreference = "SilentlyContinue"
            Invoke-WebRequest -Uri "https://github.com/dfederm/MachineSetup/archive/refs/heads/main.zip" -OutFile $zipPath
        }
        finally
        {
            $ProgressPreference = $previousProgressPreference
        }

        Expand-Archive -LiteralPath $zipPath -DestinationPath $tempDir
        $setupScripts = @(Get-ChildItem -Path $tempDir -Filter setup.ps1 -File -Recurse)
        if ($setupScripts.Count -ne 1)
        {
            throw "Expected exactly one setup.ps1 in the downloaded MachineSetup archive, but found $($setupScripts.Count)."
        }

        $exitCode = Invoke-PowerShellSetup -PowerShellPath $PowerShellPath -SetupScript $setupScripts[0].FullName -SetupArguments $SetupArguments
        if ($exitCode -ne 0)
        {
            $exception = New-Object System.Exception("MachineSetup setup failed with exit code $exitCode.")
            $exception.Data["ExitCode"] = $exitCode
            throw $exception
        }
    }
    finally
    {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-MachineSetupBootstrap
{
    param (
        [object[]] $SetupArguments = @()
    )

    $powerShellPath = Resolve-PowerShell7Executable
    if (-not $powerShellPath)
    {
        Install-PowerShell7
        $powerShellPath = Resolve-PowerShell7Executable
    }

    if (-not $powerShellPath)
    {
        throw "PowerShell 7.4 or newer was installed, but pwsh.exe could not be launched. Verify the PowerShell app execution alias and run MachineSetup again."
    }

    Invoke-DownloadedSetup -PowerShellPath $powerShellPath -SetupArguments $SetupArguments
}

function Invoke-BootstrapEntryPoint
{
    param (
        [object[]] $SetupArguments = @(),
        [switch] $ExitProcess
    )

    try
    {
        Invoke-MachineSetupBootstrap -SetupArguments $SetupArguments
    }
    catch
    {
        $exitCode = $_.Exception.Data["ExitCode"]
        if ($ExitProcess -and $null -ne $exitCode)
        {
            exit $exitCode
        }

        throw
    }
}

if ($MyInvocation.InvocationName -ne ".")
{
    Invoke-BootstrapEntryPoint -SetupArguments $args -ExitProcess:([bool] $PSCommandPath)
}
