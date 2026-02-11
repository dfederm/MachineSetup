New-RegistryComponent `
    -Name "Remove Search from Taskbar" `
    -Description "Remove the search box from the taskbar" `
    -Category "Taskbar" `
    -Values @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarMode"; Data = 0; Type = "DWord" }
    )
