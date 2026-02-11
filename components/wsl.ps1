@{
    Name        = "WSL"
    Description = "Install Windows Subsystem for Linux"
    Category    = "System"
    Detect      = {
        $wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
        if (-not $wsl) { return $false }
        wsl --list > $null 2>&1
        return $LASTEXITCODE -eq 0
    }
    Install     = {
        wsl --install
        Write-Warning "WSL requires a reboot to finish installation. Please reboot before attempting to use it."
    }
}
