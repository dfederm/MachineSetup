New-RegistryComponent `
    -Name "Show Hidden Files" `
    -Description "Show hidden files and directories in Explorer" `
    -Category "Explorer" `
    -Values @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Hidden"; Data = 1; Type = "DWord" }
    )
