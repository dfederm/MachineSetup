New-RegistryComponent `
    -Name "Disable Widgets" `
    -Description "Disable Widgets on the taskbar" `
    -Category "Taskbar" `
    -RestartExplorer `
    -Values @(
        @{ Path = "HKLM:\Software\Policies\Microsoft\Dsh"; Name = "AllowNewsAndInterests"; Data = 0; Type = "DWord" }
    )
