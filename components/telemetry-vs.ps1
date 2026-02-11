New-RegistryComponent `
    -Name "Opt Out VS Telemetry" `
    -Description "Opt out of Visual Studio telemetry" `
    -Category "Telemetry" `
    -Values @(
        @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\17.0\SQM"; Name = "OptIn"; Data = 0; Type = "DWord" }
    )
