New-RegistryComponent `
    -Name "Developer Mode" `
    -Description "Enable Developer Mode" `
    -Category "Dev" `
    -Values @(
        @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock"; Name = "AllowDevelopmentWithoutDevLicense"; Data = 1; Type = "DWord" }
    )
