New-RegistryComponent `
    -Name "Disable Multi-Display Taskbar" `
    -Description "Disable showing taskbar on all displays" `
    -Category "Taskbar" `
    -RestartExplorer `
    -Values @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "MMTaskbarEnabled"; Data = 0; Type = "DWord" }
    )
