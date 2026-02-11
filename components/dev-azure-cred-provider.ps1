@{
    Name        = "Azure Artifacts Credential Provider"
    Description = "Install Azure Artifacts Credential Provider for NuGet"
    Category    = "Dev"
    Scope       = "work"
    Detect      = {
        $pluginDir = Join-Path $env:USERPROFILE ".nuget\plugins\netcore\CredentialProvider.Microsoft"
        Test-Path $pluginDir
    }
    Install     = {
        Write-Message "Installing Azure Artifacts Credential Provider"
        Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx" | Out-Null
    }
}
