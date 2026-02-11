New-RegistryComponent `
    -Name "Remove Task View Button" `
    -Description "Remove Task View button from the taskbar" `
    -Category "Taskbar" `
    -RestartExplorer `
    -Values @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowTaskViewButton"; Data = 0; Type = "DWord" }
    )
