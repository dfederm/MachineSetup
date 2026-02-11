New-RegistryComponent `
    -Name "Show File Extensions" `
    -Description "Show file extensions in Explorer" `
    -Category "Explorer" `
    -Values @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "HideFileExt"; Data = 0; Type = "DWord" }
    )
