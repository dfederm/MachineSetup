@{
    Name        = "Opt Out .NET Telemetry"
    Description = "Opt out of .NET CLI telemetry"
    Category    = "Telemetry"
    Detect      = {
        [Environment]::GetEnvironmentVariable("DOTNET_CLI_TELEMETRY_OPTOUT", "User") -eq "1"
    }
    Install     = {
        Set-EnvironmentVariable -Name "DOTNET_CLI_TELEMETRY_OPTOUT" -Value "1"
    }
}
