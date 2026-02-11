@{
    Name        = "NuGet Auth Dialog"
    Description = "Force NuGet to use auth dialogs"
    Category    = "Dev"
    Scope       = "work"
    Detect      = {
        [Environment]::GetEnvironmentVariable("NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO", "User") -eq "true"
    }
    Install     = {
        Set-EnvironmentVariable -Name "NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO" -Value "true"
    }
}
