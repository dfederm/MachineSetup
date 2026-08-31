$repoRoot = Split-Path $PSScriptRoot -Parent
$operationsFile = Join-Path $repoRoot "config\terminal-settings.patch.json"
Import-Module (Join-Path $repoRoot "lib\JsonSettings.psm1") -Force -Global

$getTargetDir = {
    $pkg = Get-AppxPackage Microsoft.WindowsTerminal
    if ($pkg) { return "$env:LocalAppData\Packages\$($pkg.PackageFamilyName)\LocalState" }
    return $null
}

$initializeSettings = {
    param (
        [Parameter(Mandatory)]
        [string] $TargetFile
    )

    $terminalCommand = Get-Command wt.exe -ErrorAction SilentlyContinue
    if (-not $terminalCommand)
    {
        throw "Windows Terminal was installed, but wt.exe is unavailable. Launch Windows Terminal once, then rerun MachineSetup."
    }

    try
    {
        & $terminalCommand -w new -- cmd.exe /d /c exit | Out-Null
    }
    catch
    {
        throw "Windows Terminal settings could not be initialized automatically: $($_.Exception.Message). Launch Windows Terminal once, then rerun MachineSetup."
    }

    for ($attempt = 0; $attempt -lt 40; $attempt++)
    {
        if ((Test-Path $TargetFile) -and (Get-Item $TargetFile).Length -gt 0)
        {
            return
        }
        Start-Sleep -Milliseconds 250
    }

    throw "Windows Terminal did not create settings '$TargetFile' after it was launched. Launch Windows Terminal once, then rerun MachineSetup."
}.GetNewClosure()

@{
    Name        = "Windows Terminal"
    Description = "Install Windows Terminal and configure settings"
    Category    = "Apps"
    DependsOn   = @("codedir")
    Detect      = {
        if (-not (Test-WinGetPackage "Microsoft.WindowsTerminal")) { return $false }

        $targetDir = & $getTargetDir
        if (-not $targetDir) { return $false }

        $targetFile = Join-Path $targetDir "settings.json"
        if (-not (Test-Path $targetFile)) { return $false }
        if ((Get-Item $targetFile).Length -eq 0) { return $false }

        try
        {
            return Test-JsonSettingsFile -Path $targetFile -OperationsPath $operationsFile
        }
        catch
        {
            Write-Warning "Windows Terminal settings '$targetFile' could not be validated: $($_.Exception.Message)"
            return $false
        }
    }.GetNewClosure()
    Install     = {
        if (-not (Install-WinGetPackage "Microsoft.WindowsTerminal")) { throw "Failed to install Microsoft.WindowsTerminal" }

        $targetDir = & $getTargetDir
        if (-not $targetDir)
        {
            throw "Windows Terminal package directory was not found after installation."
        }

        $targetFile = Join-Path $targetDir "settings.json"
        if (-not (Test-Path $targetFile))
        {
            & $initializeSettings $targetFile
        }
        if ((Get-Item $targetFile).Length -eq 0)
        {
            throw "Windows Terminal settings '$targetFile' are empty. Delete the file, launch Windows Terminal once, then rerun MachineSetup."
        }

        Update-JsonSettingsFile -Path $targetFile -OperationsPath $operationsFile | Out-Null
    }.GetNewClosure()
}
