New-RegistryComponent `
    -Name "Disable Edge Alt+Tab" `
    -Description "Disable Edge tabs showing in Alt+Tab" `
    -Category "Taskbar" `
    -Values @(
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "MultiTaskingAltTabFilter"; Data = 3; Type = "DWord" }
    )
