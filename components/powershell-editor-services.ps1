@{
    Name        = "PowerShell Editor Services"
    Description = "Install PowerShell Editor Services language server for LSP support"
    Category    = "Dev"
    DependsOn   = @("powershell", "bindir")
    Detect      = {
        return Test-Path "$env:LOCALAPPDATA\PowerShellEditorServices\PowerShellEditorServices\Start-EditorServices.ps1"
    }
    Install     = {
        $releaseUrl = "https://api.github.com/repos/PowerShell/PowerShellEditorServices/releases/latest"
        $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ Accept = "application/vnd.github.v3+json" }
        $asset = $release.assets | Where-Object { $_.name -like "PowerShellEditorServices.zip" } | Select-Object -First 1
        if (-not $asset) { throw "Could not find PowerShellEditorServices.zip in latest release" }

        $installDir = Join-Path $env:LOCALAPPDATA "PowerShellEditorServices"
        $tempZip = Join-Path $env:TEMP "PowerShellEditorServices.zip"

        try
        {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip

            if (Test-Path $installDir) { Remove-Item -Path $installDir -Recurse -Force }
            Expand-Archive -Path $tempZip -DestinationPath $installDir -Force
        }
        finally
        {
            Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
        }
    }
}
