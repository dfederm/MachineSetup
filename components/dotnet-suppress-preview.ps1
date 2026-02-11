@{
    Name        = "Suppress .NET Preview Message"
    Description = "Suppress .NET SDK Preview messages"
    Category    = "Dev"
    Detect      = {
        [Environment]::GetEnvironmentVariable("SuppressNETCoreSdkPreviewMessage", "User") -eq "true"
    }
    Install     = {
        Set-EnvironmentVariable -Name "SuppressNETCoreSdkPreviewMessage" -Value "true"
    }
}
