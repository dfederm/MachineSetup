@{
    Name        = "Azure Artifacts Credential Provider"
    Description = "Install Azure Artifacts Credential Provider for NuGet and configure auth dialogs"
    Category    = "Dev"
    Scope       = "work"
    Detect      = {
        $pluginDir = Join-Path $env:USERPROFILE ".nuget\plugins\netcore\CredentialProvider.Microsoft"
        if (-not (Test-Path $pluginDir)) { return $false }
        [Environment]::GetEnvironmentVariable("NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO", "User") -eq "true"
    }
    Install     = {
        $pluginDir = Join-Path $env:USERPROFILE ".nuget\plugins\netcore\CredentialProvider.Microsoft"
        if (-not (Test-Path $pluginDir))
        {
            Write-Message "Installing Azure Artifacts Credential Provider"
            Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx" | Out-Null
        }

        Set-EnvironmentVariable -Name "NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO" -Value "true"
    }
}
