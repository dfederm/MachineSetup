@{
    Name        = "XML Language Server"
    Description = "Install Eclipse LemMinX XML language server for LSP support"
    Category    = "Dev"
    DependsOn   = @("bindir")
    Detect      = {
        return Test-Path (Join-Path $env:BinDir "lemminx.exe")
    }
    Install     = {
        $releaseUrl = "https://api.github.com/repos/redhat-developer/vscode-xml/releases/latest"
        $release = Invoke-RestMethod -Uri $releaseUrl -Headers @{ Accept = "application/vnd.github.v3+json" }
        $asset = $release.assets | Where-Object { $_.name -eq "lemminx-win32.zip" } | Select-Object -First 1
        if (-not $asset) { throw "Could not find lemminx-win32.zip in latest release" }

        $tempZip = Join-Path $env:TEMP "lemminx-win32.zip"
        $tempDir = Join-Path $env:TEMP "lemminx-extract"

        try
        {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip
            Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
            $exe = Get-ChildItem -Path $tempDir -Filter "lemminx-win32.exe" -Recurse | Select-Object -First 1
            if (-not $exe) { throw "lemminx-win32.exe not found in archive" }
            Copy-Item -Path $exe.FullName -Destination (Join-Path $env:BinDir "lemminx.exe") -Force
        }
        finally
        {
            Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
