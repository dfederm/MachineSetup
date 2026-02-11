New-RegistryComponent `
    -Name "Long Paths" `
    -Description "Enable long path support in Windows" `
    -Category "Dev" `
    -Values @(
        @{ Path = "HKLM:\System\CurrentControlSet\Control\FileSystem"; Name = "LongPathsEnabled"; Data = 1; Type = "DWord" }
    )
