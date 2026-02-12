$bloatwareApps = @(
    "Microsoft.549981C3F5F10" # Cortana
    "Microsoft.BingNews"
    "Microsoft.BingWeather"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MixedReality.Portal"
    "MicrosoftTeams" # Teams Personal only (not Work/School)
    "MicrosoftWindows.Client.WebExperience" # Widgets
)

@{
    Name        = "Remove Bloatware"
    Description = "Uninstall pre-installed bloatware Appx packages"
    Category    = "System"
    Detect      = {
        foreach ($appName in $bloatwareApps)
        {
            if (Get-AppxPackage -Name $appName -ErrorAction SilentlyContinue)
            {
                return $false
            }
        }
        return $true
    }.GetNewClosure()
    Install     = {
        # Build the app list as a literal string for the elevated block
        $appListStr = ($bloatwareApps | ForEach-Object { "`"$_`"" }) -join ",`n                "
        $UninstallBlock = @"
            foreach (`$appName in @(
                $appListStr
            ))
            {
                `$apps = Get-AppxPackage -AllUsers `$appName
                foreach (`$app in `$apps)
                {
                    Write-Host "Uninstalling `$(`$app.PackageFullName)"
                    Remove-AppxPackage -Package `$app.PackageFullName -AllUsers
                }
            }
"@
        Invoke-Elevated $UninstallBlock
    }.GetNewClosure()
}
