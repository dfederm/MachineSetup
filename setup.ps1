Import-Module -DisableNameChecking "$PSScriptRoot\lib\Console.psm1"
Import-Module -DisableNameChecking "$PSScriptRoot\lib\Environment.psm1"
Import-Module -DisableNameChecking "$PSScriptRoot\lib\Registry.psm1"

# TODO: Bootstrap!

Print-Header "Gathering information"

$CodeDir = $env:CodeDir;
if ($CodeDir -eq $null)
{
    $CodeDir = Read-Host "Where is your code directory located?"
}
else
{
    Print-Message "CodeDir already set to $CodeDir"
}

Write-Host
<#
$InstallCommsApps = $Host.UI.PromptForChoice(
    "",
    "Do you need communication apps, eg. Telegram, Teams?",
    @("&Yes", "&No"),
    -1)
#>

Print-Header "Configuring registry and environment variables"

if (-not (Test-Path $CodeDir))
{
    New-Item -Path $CodeDir -ItemType Directory
}

Print-Message "Configuring CodeDir"

Set-EnvironmentVariable -Name "CodeDir" -Value $CodeDir
Set-EnvironmentVariable -Name "NUGET_PACKAGES" -Value "$CodeDir\.nuget"
Set-EnvironmentVariable -Name "NUGET_HTTP_CACHE_PATH" -Value "$CodeDir\.nuget\.http"

# TODO: Should be scripts dir. Need bootstrapping!
# Add-PathVariable -Path "C:\Users\david\OneDrive\Code\Scripts"

# TODO: Should be scripts dir. Need bootstrapping!
# Print-Message "Configuring cmd Autorun"
# Set-RegistryValue -Path "HKCU:\Software\Microsoft\Command Processor" -Name "Autorun" -Data "`"C:\Users\david\OneDrive\Code\Scripts\\init.cmd`"" -Type ExpandString

Print-Message "Showing file extensions in Explorer"
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Data 0 -Type DWord > $null

Print-Message "Showing hidden files and directories in Explorer"
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Data 1 -Type DWord > $null

Print-Message "Restore classic context menu"
$restartExplorer = Set-RegistryValue -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
if ($restartExplorer)
{
    # Restart explorer to apply the change
    Stop-Process -Name explorer -Force
}

# TODO: Need admin
# Print-Message "Enable Developer Mode"
# Set-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Data 1 -Type DWord

# TODO: Need admin
# Print-Message "Enable Remote Desktop"
# Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Data 0 -Type DWord
# Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# TODO: Need admin
# Print-Message "Enable Long Paths"
# Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Data 1 -Type DWord

Print-Message "Installing Azure Artifacts Credential Provider"
Invoke-Expression "& { $(irm https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx" | Out-Null

Print-Message "Force NuGet to use auth dialogs"
Set-EnvironmentVariable -Name "NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO" -Value "true"

Print-Message "Opting out of .NET Telemetry"
Set-EnvironmentVariable -Name "DOTNET_CLI_TELEMETRY_OPTOUT" -Value 1

# TODO: Need admin
# Print-Message "Excluding CodeDir from Defender"
# Add-MpPreference -ExclusionPath $CodeDir

# TODO: Need admin
<#
Print-Message "Uninstalling Bloatware Appx"
$Bloatware = @(
    "Microsoft.549981C3F5F10",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MixedReality.Portal"
)
ForEach-Object { Get-AppxPackage -allusers $_ | Remove-AppxPackage }
#>

# TODO: Port more of setup.cmd