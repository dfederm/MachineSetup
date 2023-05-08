param (
    [switch] $InstallCommsApps
)

Import-Module "$PSScriptRoot\lib\Console.psm1"
Import-Module "$PSScriptRoot\lib\Environment.psm1"
Import-Module "$PSScriptRoot\lib\Registry.psm1"

# TODO: Bootstrap!

Write-Header "Gathering information"

$CodeDir = $env:CodeDir;
if ($CodeDir)
{
    Write-Message "CodeDir already set to $CodeDir"
}
else
{
    $CodeDir = Read-Host "Where is your code directory located?"
}

Write-Host

if (-not $InstallCommsApps)
{
    $InstallCommsApps = $Host.UI.PromptForChoice(
        "",
        "Do you need communication apps, eg. Telegram, Teams?",
        @("&Yes", "&No"),
        -1)
}

Write-Header "Configuring registry and environment variables"

if (-not (Test-Path $CodeDir))
{
    New-Item -Path $CodeDir -ItemType Directory
}

Write-Message "Configuring CodeDir"

Set-EnvironmentVariable -Name "CodeDir" -Value $CodeDir
Set-EnvironmentVariable -Name "NUGET_PACKAGES" -Value "$CodeDir\.nuget"
Set-EnvironmentVariable -Name "NUGET_HTTP_CACHE_PATH" -Value "$CodeDir\.nuget\.http"

# TODO: Should be scripts dir. Need bootstrapping!
# Add-PathVariable -Path "C:\Users\david\OneDrive\Code\Scripts"

# TODO: Should be scripts dir. Need bootstrapping!
# Write-Message "Configuring cmd Autorun"
# Set-RegistryValue -Path "HKCU:\Software\Microsoft\Command Processor" -Name "Autorun" -Data "`"C:\Users\david\OneDrive\Code\Scripts\\init.cmd`"" -Type ExpandString

Write-Message "Showing file extensions in Explorer"
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Data 0 -Type DWord > $null

Write-Message "Showing hidden files and directories in Explorer"
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Data 1 -Type DWord > $null

Write-Message "Restore classic context menu"
$restartExplorer = Set-RegistryValue -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
if ($restartExplorer)
{
    # Restart explorer to apply the change
    Stop-Process -Name explorer -Force
}

# TODO: Need admin
# Write-Message "Enable Developer Mode"
# Set-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Data 1 -Type DWord

# TODO: Need admin
# Write-Message "Enable Remote Desktop"
# Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Data 0 -Type DWord
# Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# TODO: Need admin
# Write-Message "Enable Long Paths"
# Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Data 1 -Type DWord

Write-Message "Installing Azure Artifacts Credential Provider"
Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx" | Out-Null

Write-Message "Force NuGet to use auth dialogs"
Set-EnvironmentVariable -Name "NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO" -Value "true"

Write-Message "Opting out of .NET Telemetry"
Set-EnvironmentVariable -Name "DOTNET_CLI_TELEMETRY_OPTOUT" -Value 1

# TODO: Need admin
# Write-Message "Excluding CodeDir from Defender"
# Add-MpPreference -ExclusionPath $CodeDir

# TODO: Need admin
<#
Write-Header "Uninstalling Bloatware Appx"
$BloatwareApps = @(
    "Microsoft.549981C3F5F10" # Cortana
    "Microsoft.BingWeather"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.MixedReality.Portal"
)
foreach ($appName in $BloatwareApps)
{
    Write-Message "Uninstalling $appName"
    $app = Get-AppxPackage -AllUsers $appName
    Remove-AppxPackage -Package $app -AllUsers
}
#>

<#
Write-Header "Installing applications via WinGet"
$InstallApps = @(
    "7zip.7zip"
    "Git.Git"
    "icsharpcode.ILSpy"
    "KirillOsenkov.MSBuildStructuredLogViewer"
    "Microsoft.DotNet.SDK.7"
    "Microsoft.NuGet"
    "Microsoft.PowerShell"
    "Microsoft.PowerToys"
    "Microsoft.RemoteDesktopClient"
    "Microsoft.SQLServerManagementStudio"
    "Microsoft.VisualStudioCode"
    "Microsoft.VisualStudio.2022.Enterprise"
    "Microsoft.VisualStudio.2022.Enterprise.Preview"
    "Microsoft.WindowsTerminal"
    "Notepad++.Notepad++"
    "NuGet Package Explorer"
    "OpenJS.NodeJS"
    "Regex Hero"
    "SourceGear.DiffMerge"
    "WinDirStat.WinDirStat"
)
if ($InstallCommsApps)
{
    $InstallApps += @(
        "Telegram.TelegramDesktop"
        "Microsoft.Teams"
    )
}
foreach ($appName in $InstallApps)
{
    Write-Message "Installing $appName"
    winget install $appName --silent --no-upgrade --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0)
    {
        Write-Message "$appName installed successfully"
    }
    # 0x8A150061 (APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED)
    elseif ($LASTEXITCODE -eq -1978335135)
    {
        Write-Message "$appName already installed"
    }
    else
    {
        Write-Error "$appName failed to install! winget exit code $LASTEXITCODE"
    }
}
#>

# After installing apps, the Path will have changed
Update-PathVariable

Write-Header "Setting git config and aliases"
git config --global core.editor "`"$env:ProgramFiles\Notepad++\notepad++.exe`" -multiInst -notabbar -nosession -noPlugin"
git config --global core.autocrlf true
git config --global core.fscache true
git config --global core.longpaths true
git config --global fetch.prune true
git config --global pull.rebase true
git config --global push.default current
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved zebra
git config --global alias.amend "commit --amend --date=now --no-edit"
git config --global alias.sync "pull --rebase origin main"

# TODO: Need bootstrapping!
# Write-Header "Copying Terminal settings"
# copy /y "%~dp0\..\WindowsTerminal\settings.json" "%LocalAppData%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" >NUL

Write-Header "Installing SlnGen"
dotnet tool install --global Microsoft.VisualStudio.SlnGen.Tool --add-source https://api.nuget.org/v3/index.json --ignore-failed-sources

# TODO: Need bootstrapping! Also, this probably wouldn't work?
# init now to avoid the need to restart the console
# Write-Header "Running init"
# call "%~dp0\init.cmd"

Write-Header "Done!"
