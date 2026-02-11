New-RegistryComponent `
    -Name "Disable Web Search" `
    -Description "Disable web results in Windows search" `
    -Category "Taskbar" `
    -Values @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Data = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "AllowSearchToUseLocation"; Data = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "CortanaConsent"; Data = 0; Type = "DWord" }
    )
