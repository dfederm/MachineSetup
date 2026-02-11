@{
    Name        = "Visual Studio Code"
    Description = "Install VSCode and add context menu entries to Explorer"
    Category    = "Dev"
    Detect      = {
        if (-not (Test-WinGetPackage "Microsoft.VisualStudioCode")) { return $false }
        Test-RegistryValue -Path "Registry::HKEY_CLASSES_ROOT\*\shell\VSCode" -Data "Open w&ith Code"
    }
    Install     = {
        if (-not (Install-WinGetPackage "Microsoft.VisualStudioCode")) { throw "Failed to install Microsoft.VisualStudioCode" }

        $VsCodeExe = "$Env:LocalAppData\Programs\Microsoft VS Code\Code.exe"

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
