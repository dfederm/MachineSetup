New-RegistryComponent `
    -Name "Classic Context Menu" `
    -Description "Restore classic context menu in Explorer" `
    -Category "Explorer" `
    -RestartExplorer `
    -Values @(
        @{ Path = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" }
    )
