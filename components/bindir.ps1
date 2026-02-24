$repoRoot = Split-Path $PSScriptRoot -Parent
$repoBinDir = Join-Path $repoRoot "bin"

@{
    Name        = "BinDir"
    Description = "Configure BinDir, deploy bin files, add to PATH, and set cmd Autorun"
    Category    = "System"
    Detect      = {
        $binDir = [Environment]::GetEnvironmentVariable("BinDir", "User")
        if (-not $binDir) { return $false }
        if (-not (Test-Path $binDir)) { return $false }
        # Check PATH contains BinDir
        $path = [Environment]::GetEnvironmentVariable("Path", "User")
        $regex = "^$([regex]::Escape($binDir.TrimEnd('\')))\\?"
        $onPath = ($path -split ';' | Where-Object { $_ -Match $regex }).Count -gt 0
        if (-not $onPath) { return $false }
        # Check all repo bin files are deployed with matching content
        return Test-FileDeployment @(@{ Source = $repoBinDir; Target = $binDir })
    }.GetNewClosure()
    Install     = {
        $binDir = $env:BinDir
        if (-not $binDir)
        {
            $binDir = Read-Host "Where is your bin directory located?"
        }

        if (-not (Test-Path $binDir))
        {
            New-Item -Path $binDir -ItemType Directory > $null
        }

        Install-FileDeployment @(@{ Source = $repoBinDir; Target = $binDir })

        Set-EnvironmentVariable -Name "BinDir" -Value $binDir
        Add-PathVariable -Path $binDir

        Write-Message "Configuring cmd Autorun"
        Set-RegistryValue -Path "HKCU:\Software\Microsoft\Command Processor" -Name "Autorun" -Data "`"$binDir\init.cmd`"" -Type ExpandString > $null
    }.GetNewClosure()
}
