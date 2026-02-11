New-RegistryComponent `
    -Name "Dark Mode" `
    -Description "Enable dark mode for system and apps" `
    -Category "Explorer" `
    -Values @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "SystemUsesLightTheme"; Data = 0; Type = "DWord" }
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "AppsUseLightTheme"; Data = 0; Type = "DWord" }
    )
