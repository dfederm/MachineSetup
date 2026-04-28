@{
    Name        = "Visual Studio Code"
    Description = "Install VSCode and add context menu entries to Explorer"
    Category    = "Dev"
    Detect      = {
        if (-not (Test-WinGetPackage "Microsoft.VisualStudioCode")) { return $false }
        $VsCodeExe = @(
            "$Env:LocalAppData\Programs\Microsoft VS Code\Code.exe",
            "$Env:ProgramFiles\Microsoft VS Code\Code.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $VsCodeExe) { return $false }

        # Verify each parent label, icon, and command subkey is present and pointing
        # at the current Code.exe. Checking only the parent label allows the install
        # to silently leave \command subkeys missing, breaking the menu entries.
        $expectedFileCommand = "`"$VsCodeExe`" `"%1`""
        $expectedDirCommand = "`"$VsCodeExe`" `"%V`""
        $entries = @(
            @{ Path = "Registry::HKEY_CLASSES_ROOT\*\shell\VSCode";                  Command = $expectedFileCommand },
            @{ Path = "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode";          Command = $expectedDirCommand },
            @{ Path = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode"; Command = $expectedDirCommand },
            @{ Path = "Registry::HKEY_CLASSES_ROOT\Drive\shell\VSCode";              Command = $expectedDirCommand }
        )
        foreach ($entry in $entries)
        {
            if (-not (Test-RegistryValue -Path $entry.Path -Data "Open w&ith Code")) { return $false }
            if (-not (Test-RegistryValue -Path $entry.Path -Name "Icon" -Data $VsCodeExe)) { return $false }
            if (-not (Test-RegistryValue -Path "$($entry.Path)\command" -Data $entry.Command)) { return $false }
        }
        return $true
    }
    Install     = {
        if (-not (Install-WinGetPackage "Microsoft.VisualStudioCode")) { throw "Failed to install Microsoft.VisualStudioCode" }

        # VS Code may be installed per-user or per-machine (eg via winget --scope machine)
        $VsCodeExe = @(
            "$Env:LocalAppData\Programs\Microsoft VS Code\Code.exe",
            "$Env:ProgramFiles\Microsoft VS Code\Code.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if (-not $VsCodeExe) { throw "Could not find Code.exe" }

        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\*\shell\VSCode" -Data "Open w&ith Code" -Elevate > $null
        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\*\shell\VSCode" -Name "Icon" -Data $VsCodeExe -Elevate > $null
        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\*\shell\VSCode\command" -Data "`"$VsCodeExe`" `"%1`"" -Elevate > $null

        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode" -Data "Open w&ith Code" -Elevate > $null
        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode" -Name "Icon" -Data $VsCodeExe -Elevate > $null
        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode\command" -Data "`"$VsCodeExe`" `"%V`"" -Elevate > $null

        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode" -Data "Open w&ith Code" -Elevate > $null
        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode" -Name "Icon" -Data $VsCodeExe -Elevate > $null
        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode\command" -Data "`"$VsCodeExe`" `"%V`"" -Elevate > $null

        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\VSCode" -Data "Open w&ith Code" -Elevate > $null
        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\VSCode" -Name "Icon" -Data $VsCodeExe -Elevate > $null
        Set-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\VSCode\command" -Data "`"$VsCodeExe`" `"%V`"" -Elevate > $null
    }
}
