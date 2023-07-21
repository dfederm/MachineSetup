param (
    [switch] $IsForWork,
    [switch] $InstallCommsApps
)

Import-Module "$PSScriptRoot\lib\Console.psm1"
Import-Module "$PSScriptRoot\lib\Elevation.psm1"
Import-Module "$PSScriptRoot\lib\Environment.psm1"
Import-Module "$PSScriptRoot\lib\Firewall.psm1"
Import-Module "$PSScriptRoot\lib\Registry.psm1"

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

$BinDir = $env:BinDir;
if ($BinDir)
{
    Write-Message "BinDir already set to $BinDir"
}
else
{
    $BinDir = Read-Host "Where is your bin directory located?"
}

Write-Host

if (-not $PSBoundParameters.ContainsKey('IsForWork'))
{
    $IsForWorkChoice = $Host.UI.PromptForChoice(
        "",
        "Is this for work?",
        @("&No", "&Yes"),
        -1)
    $IsForWork = $IsForWorkChoice -eq 1
}

Write-Host

if (-not $PSBoundParameters.ContainsKey('InstallCommsApps'))
{
    $InstallCommsAppsChoice = $Host.UI.PromptForChoice(
        "",
        "Do you need communication apps, eg. Telegram, Teams?",
        @("&Yes", "&No"),
        -1)
    $InstallCommsApps = $InstallCommsAppsChoice -eq 0
}

Write-Header "Configuring registry and environment variables"

Write-Message "Configuring CodeDir"

if (-not (Test-Path $CodeDir))
{
    New-Item -Path $CodeDir -ItemType Directory > $null
}

Set-EnvironmentVariable -Name "CodeDir" -Value $CodeDir
Set-EnvironmentVariable -Name "NUGET_PACKAGES" -Value "$CodeDir\.nuget"
Set-EnvironmentVariable -Name "NUGET_HTTP_CACHE_PATH" -Value "$CodeDir\.nuget\.http"

Write-Message "Configuring BinDir"

if (-not (Test-Path $BinDir))
{
    New-Item -Path $BinDir -ItemType Directory > $null
}

Copy-Item -Path "$PSScriptRoot\bin\*" -Destination $BinDir -Recurse -Force
Set-EnvironmentVariable -Name "BinDir" -Value $BinDir
Add-PathVariable -Path $BinDir

Write-Message "Configuring cmd Autorun"
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Command Processor" -Name "Autorun" -Data "`"$BinDir\init.cmd`"" -Type ExpandString > $null

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

Write-Message "Disabling Edge tabs showing in Alt+Tab"
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "MultiTaskingAltTabFilter" -Data 3 -Type DWord > $null

Write-Message "Enable Developer Mode"
Set-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Data 1 -Type DWord -Elevate > $null

Write-Message "Enable Remote Desktop"
Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Data 0 -Type DWord -Elevate > $null
Enable-FirewallRuleGroup -DisplayGroup "Remote Desktop"

Write-Message "Enable Long Paths"
Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Data 1 -Type DWord -Elevate > $null

if ($IsForWork)
{
    Write-Message "Installing Azure Artifacts Credential Provider (NuGet)"
    Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-artifacts-credprovider.ps1) } -AddNetfx" | Out-Null

    Write-Message "Force NuGet to use auth dialogs"
    Set-EnvironmentVariable -Name "NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO" -Value "true"
}

Write-Message "Opting out of Windows Telemetry"
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Data 0 -Type DWord -Elevate > $null

Write-Message "Opting out of VS Telemetry"
Set-RegistryValue -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\17.0\SQM" -Name "OptIn" -Data 0 -Type DWord -Elevate > $null

Write-Message "Opting out of .NET Telemetry"
Set-EnvironmentVariable -Name "DOTNET_CLI_TELEMETRY_OPTOUT" -Value 1

Write-Message "Excluding CodeDir from Defender"
# Unfortunately only admins can view exclusions, so this can't avoid elevation.
$DefenderExclusionBlock = {
    Add-MpPreference -ExclusionPath $CodeDir
}
Invoke-Elevated ($ExecutionContext.InvokeCommand.ExpandString($DefenderExclusionBlock))

Write-Header "Uninstalling Bloatware Appx"
$UninstallBloatwareBlock = {
    $BloatwareApps = @(
        "Microsoft.549981C3F5F10" # Cortana
        "Microsoft.BingWeather"
        "Microsoft.GetHelp"
        "Microsoft.Getstarted"
        "Microsoft.MixedReality.Portal"
    )
    foreach ($appName in $BloatwareApps)
    {
        $app = Get-AppxPackage -AllUsers $appName
        if ($app)
        {
            Write-Message "Uninstalling $appName"
            Remove-AppxPackage -Package $app -AllUsers
        }
    }
}
Invoke-Elevated ($ExecutionContext.InvokeCommand.ExpandString($UninstallBloatwareBlock))

Write-Header "Installing applications via WinGet"
$InstallApps = @(
    "7zip.7zip"
    "AntibodySoftware.WizTree"
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
    "REALiX.HWiNFO"
    "Regex Hero"
    "SourceGear.DiffMerge"
    "Sysinternals Suite"
)
if ($InstallCommsApps)
{
    if ($IsForWork)
    {
        $InstallApps += @(
            "Microsoft.Teams"
        )
    }
    else
    {
        $InstallApps += @(
            "Telegram.TelegramDesktop"
        )
    }
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

# After installing apps, the Path will have changed
Update-PathVariable

Write-Header "Installing WSL"
wsl --list >NUL
if ($LASTEXITCODE -eq 0)
{
    Write-Debug "WSL already installed"
}
else
{
    wsl --install
    Write-Warning "WSL requires a reboot to finish installation. Please reboot before attempting to use it."
}

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

if ($IsForWork)
{
    Write-Debug "Enable WAM integration for Git (promptless auth)"
    # See: https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/windows-broker.md
    git config --global credential.msauthUseBroker true
    git config --global credential.msauthUseDefaultAccount true
}

Write-Header "Copying Windows Terminal settings"
Copy-Item -Path "$BinDir\terminal\settings.json" -Destination "$env:LocalAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

Write-Header "Installing SlnGen"
dotnet tool install --global Microsoft.VisualStudio.SlnGen.Tool --add-source https://api.nuget.org/v3/index.json --ignore-failed-sources > $null

Write-Header "Done!"
