New-RegistryComponent `
    -Name "Opt Out Windows Telemetry" `
    -Description "Opt out of Windows telemetry" `
    -Category "Telemetry" `
    -Values @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Data = 0; Type = "DWord" }
    )
