param (
    [switch] $IsForWork,
    [switch] $InstallCommsApps,
    [string[]] $Components,
    [switch] $DetectOnly
)

$ErrorActionPreference = "Stop"

# Import modules
Import-Module "$PSScriptRoot\lib\Console.psm1" -Force
Import-Module "$PSScriptRoot\lib\Elevation.psm1" -Force
Import-Module "$PSScriptRoot\lib\Environment.psm1" -Force
Import-Module "$PSScriptRoot\lib\Firewall.psm1" -Force
Import-Module "$PSScriptRoot\lib\Registry.psm1" -Force
Import-Module "$PSScriptRoot\lib\WinGet.psm1" -Force
Import-Module "$PSScriptRoot\lib\Component.psm1" -Force -DisableNameChecking

# Gather preferences
if (-not $PSBoundParameters.ContainsKey('IsForWork'))
{
    $IsForWorkChoice = $Host.UI.PromptForChoice(
        "",
        "Is this for work?",
        @("&No", "&Yes"),
        -1)
    $IsForWork = $IsForWorkChoice -eq 1
}

if (-not $PSBoundParameters.ContainsKey('InstallCommsApps'))
{
    $InstallCommsAppsChoice = $Host.UI.PromptForChoice(
        "",
        "Do you need communication apps, eg. Signal, Teams?",
        @("&Yes", "&No"),
        -1)
    $InstallCommsApps = $InstallCommsAppsChoice -eq 0
}

Write-Header "Machine Setup"

# Load all components and filter by scope
Write-Message "Loading components..."
$componentsDir = Join-Path $PSScriptRoot "components"
$allComponents = Get-AllComponents $componentsDir

# Filter to specific components if requested
if ($Components)
{
    $Components = $Components | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $allComponents = $allComponents | Where-Object { $_.Id -in $Components }
    $missing = $Components | Where-Object { $_ -notin $allComponents.Id }
    if ($missing) { Write-Warning "Unknown component(s): $($missing -join ', ')" }
}

$activeComponents = $allComponents | Where-Object {
    $scope = if ($_.Scope) { $_.Scope } else { "common" }
    switch ($scope) {
        "common"    { $true }
        "work"      { $IsForWork }
        "comms"     { $InstallCommsApps }
        "work-comms" { $IsForWork -and $InstallCommsApps }
        default     { $true }
    }
}

# Sort by dependencies
$activeComponents = Sort-ComponentsByDependency $activeComponents

# Detect current state
Write-Message "Detecting current state..."
$toInstall = @()
$alreadyInstalled = @()
foreach ($component in $activeComponents)
{
    $detected = Invoke-ComponentDetect $component
    if ($detected -eq $true)
    {
        $alreadyInstalled += $component
        Write-Host "    ✓ " -ForegroundColor DarkGreen -NoNewLine
        Write-Host $component.Name -ForegroundColor DarkGray
    }
    else
    {
        $toInstall += $component
        Write-Host "    ○ " -ForegroundColor DarkYellow -NoNewLine
        Write-Host $component.Name -ForegroundColor Gray
    }
}

if ($alreadyInstalled.Count -gt 0)
{
    Write-Message "$($alreadyInstalled.Count) component(s) already installed"
}

if ($toInstall.Count -eq 0)
{
    Write-Header "Everything is already set up!"
    return
}

if ($DetectOnly)
{
    Write-Header "$($toInstall.Count) component(s) need install:"
    foreach ($component in $toInstall)
    {
        Write-Message $component.Name
    }
    return
}

# Install components
Write-Header "Installing $($toInstall.Count) component(s)..."
$succeeded = 0
$failed = 0

foreach ($component in $toInstall)
{
    $result = Invoke-ComponentInstall $component
    if ($result) { $succeeded++ } else { $failed++ }
}

# Summary
Write-Header "Setup Complete"
Write-Success "$succeeded component(s) installed successfully"
if ($failed -gt 0)
{
    Write-Error "$failed component(s) failed"
}
