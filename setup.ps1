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
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Data "0" -Type DWord

Print-Message "Showing hidden files and directories in Explorer"
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Data "1" -Type DWord

Print-Message "Restore classic context menu"
Create-RegistryKey -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

Print-Message "Enable Developer Mode"
# TODO: Need admin
#call powershell -Command "Start-process -filepath %ComSpec% -argumentlist @('/c','reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v "AllowDevelopmentWithoutDevLicense" /d 1 /t REG_DWORD /f >NUL') -Verb RunAs"

# TODO: Port more of setup.cmd