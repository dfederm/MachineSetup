$repoRoot = Split-Path $PSScriptRoot -Parent
$componentPath = Join-Path $repoRoot 'components\windows-terminal.ps1'
$operationsPath = Join-Path $repoRoot 'config\terminal-settings.patch.json'
$jsonModulePath = Join-Path $repoRoot 'lib\JsonSettings.psm1'
$componentModulePath = Join-Path $repoRoot 'lib\Component.psm1'

function global:Test-WinGetPackage {
    param($PackageId)
    return $global:TerminalPackageInstalled
}
function global:Install-WinGetPackage {
    param($PackageId)
    $global:TerminalInstallCalls++
    return $global:TerminalInstallSucceeds
}
function global:Get-AppxPackage {
    param($Name)
    if ($global:TerminalPackageTargetAvailable) {
        return [pscustomobject]@{ PackageFamilyName = $global:TerminalPackageFamily }
    }
    return $null
}
function global:Test-JsonSettingsFile {
    param($Path, $OperationsPath)
    JsonSettings\Test-JsonSettingsFile -Path $Path -OperationsPath $OperationsPath
}
function global:Update-JsonSettingsFile {
    param($Path, $OperationsPath)
    if ($global:TerminalHelperFailure) { throw $global:TerminalHelperFailure }
    JsonSettings\Update-JsonSettingsFile -Path $Path -OperationsPath $OperationsPath
}
function global:Write-Warning {
    param($Message)
    $global:TerminalWarnings++
    $global:TerminalWarningMessages += [string] $Message
}
function global:wt.exe {
    $global:TerminalLaunchCalls++
    if ($global:TerminalLaunchFailure) {
        throw $global:TerminalLaunchFailure
    }
    if ($global:TerminalCreateSettingsOnLaunch) {
        [IO.Directory]::CreateDirectory((Split-Path $global:TerminalTargetFile -Parent)) | Out-Null
        Write-TerminalUtf8Fixture $global:TerminalTargetFile '{}'
    }
}

function Write-TerminalUtf8Fixture
{
    param([string] $Path, [string] $Text)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllBytes($Path, $encoding.GetBytes($Text))
}

function Read-TerminalFixture
{
    param([string] $Path)
    $encoding = New-Object System.Text.UTF8Encoding($false, $true)
    $encoding.GetString([IO.File]::ReadAllBytes($Path)) | ConvertFrom-Json
}

function Get-TerminalExceptionMessage
{
    param([scriptblock] $Action)
    try {
        & $Action
        return $null
    }
    catch {
        return $_.Exception.Message
    }
}

Describe 'Windows Terminal operation manifest' {
    It 'contains exactly the five managed operations and identities' {
        $manifest = Get-Content -LiteralPath $operationsPath -Raw | ConvertFrom-Json
        @($manifest.operations).Count | Should Be 5
        @($manifest.operations | ForEach-Object { $_.operation }) -join ',' | Should Be 'set,set,upsert,upsert,upsert'
        @($manifest.operations[0].path) -join '/' | Should Be 'defaultProfile'
        $manifest.operations[0].value | Should Be '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}'
        @($manifest.operations[1].path) -join '/' | Should Be 'profiles/defaults/startingDirectory'
        $manifest.operations[1].value | Should Be '%CodeDir%'
        @($manifest.operations[2].path) -join '/' | Should Be 'actions'
        $manifest.operations[2].match.id | Should Be 'User.sendInput.8F63D3A9'
        @($manifest.operations[3].path) -join '/' | Should Be 'keybindings'
        $manifest.operations[3].match.keys | Should Be 'shift+enter'
        $manifest.operations[3].value.id | Should Be 'User.sendInput.8F63D3A9'
        @($manifest.operations[4].path) -join '/' | Should Be 'keybindings'
        $manifest.operations[4].match.keys | Should Be 'ctrl+t'
        $manifest.operations[4].value.id | Should Be 'Terminal.OpenNewTab'
    }
}

Describe 'Windows Terminal fixture reconciliation' {
    BeforeEach {
        Remove-Module JsonSettings -ErrorAction SilentlyContinue
        Import-Module $jsonModulePath -Force
        $settings = Join-Path $TestDrive 'settings.json'
    }

    It 'configures a fresh fixture without discarding unrelated settings' {
        Write-TerminalUtf8Fixture $settings @'
{
  "$schema":"https://example.test/schema",
  "theme":"system",
  "profiles":{
    "defaults":{"font":{"size":11}},
    "list":[
      {"name":"Windows PowerShell","guid":"one"},
      {"name":"Generated","guid":"two","source":"Windows.Terminal.VisualStudio"}
    ]
  },
  "actions":[{"id":"Terminal.CopyToClipboard"}],
  "keybindings":[{"keys":"ctrl+c","id":"Terminal.CopyToClipboard"}],
  "schemes":[{"name":"Custom Scheme"}],
  "themes":[{"name":"Custom Theme"}]
}
'@
        Update-JsonSettingsFile $settings $operationsPath | Should Be $true
        $json = Read-TerminalFixture $settings
        $json.theme | Should Be 'system'
        @($json.profiles.list | ForEach-Object { $_.name }) -join ',' | Should Be 'Windows PowerShell,Generated'
        $json.profiles.list[1].source | Should Be 'Windows.Terminal.VisualStudio'
        $json.profiles.defaults.font.size | Should Be 11
        $json.profiles.defaults.startingDirectory | Should Be '%CodeDir%'
        @($json.actions | ForEach-Object { $_.id }) -join ',' | Should Be 'Terminal.CopyToClipboard,User.sendInput.8F63D3A9'
        @($json.keybindings | ForEach-Object { $_.keys }) -join ',' | Should Be 'ctrl+c,shift+enter,ctrl+t'
        $json.schemes[0].name | Should Be 'Custom Scheme'
        $json.themes[0].name | Should Be 'Custom Theme'
    }

    It 'selects the managed action by id and preserves another binding for that action' {
        Write-TerminalUtf8Fixture $settings @'
{
  "actions": [
    {"id":"User.sendInput.8F63D3A9","command":{"action":"old"}},
    {"id":"Other","command":{"action":"keep"}}
  ],
  "keybindings": [
    {"keys":"ctrl+x","id":"User.sendInput.8F63D3A9"},
    {"keys":"shift+enter","id":"Other"},
    {"keys":"ctrl+t","id":"Other"},
    {"keys":"ctrl+shift+t","id":"Terminal.OpenNewTab"},
    {"keys":"SHIFT+ENTER","id":"CaseSensitive"}
  ],
  "custom":"preserve"
}
'@
        Update-JsonSettingsFile $settings $operationsPath | Should Be $true
        $json = Read-TerminalFixture $settings
        @($json.actions).Count | Should Be 2
        $managed = @($json.actions | Where-Object { $_.id -eq 'User.sendInput.8F63D3A9' })
        $managed.Count | Should Be 1
        $managed[0].command.action | Should Be 'sendInput'
        $managed[0].command.input | Should Be ([string][char]27 + "`r")
        @($json.keybindings | Where-Object { $_.keys -eq 'ctrl+x' }).Count | Should Be 1
        @($json.keybindings | Where-Object { $_.keys -ceq 'shift+enter' }).Count | Should Be 1
        @($json.keybindings | Where-Object { $_.keys -ceq 'shift+enter' })[0].id | Should Be 'User.sendInput.8F63D3A9'
        @($json.keybindings | Where-Object { $_.keys -ceq 'ctrl+t' }).Count | Should Be 1
        @($json.keybindings | Where-Object { $_.keys -ceq 'ctrl+t' })[0].id | Should Be 'Terminal.OpenNewTab'
        @($json.keybindings | Where-Object { $_.keys -ceq 'ctrl+shift+t' }).Count | Should Be 1
        @($json.keybindings | Where-Object { $_.keys -ceq 'SHIFT+ENTER' }).Count | Should Be 1
        $json.custom | Should Be 'preserve'
    }

    It 'collapses duplicate managed identities while preserving customized neighbors' {
        Write-TerminalUtf8Fixture $settings '{"actions":[{"id":"User.sendInput.8F63D3A9"},{"id":"x","extra":1},{"id":"User.sendInput.8F63D3A9"}],"keybindings":[],"unknown":{"x":1}}'
        Update-JsonSettingsFile $settings $operationsPath | Should Be $true
        $json = Read-TerminalFixture $settings
        @($json.actions | Where-Object { $_.id -eq 'User.sendInput.8F63D3A9' }).Count | Should Be 1
        @($json.actions | Where-Object { $_.id -eq 'x' })[0].extra | Should Be 1
        $json.unknown.x | Should Be 1
    }
}

Describe 'Windows Terminal component' {
    BeforeAll {
        $script:OriginalLocalAppData = $env:LocalAppData
    }

    BeforeEach {
        $env:LocalAppData = $TestDrive
        $script:family = 'Synthetic.Terminal_' + [Guid]::NewGuid().ToString('N')
        $global:TerminalPackageFamily = $script:family
        $global:TerminalPackageInstalled = $true
        $global:TerminalPackageTargetAvailable = $true
        $global:TerminalInstallSucceeds = $true
        $global:TerminalInstallCalls = 0
        $global:TerminalWarnings = 0
        $global:TerminalWarningMessages = @()
        $global:TerminalHelperFailure = $null
        $global:TerminalLaunchCalls = 0
        $global:TerminalLaunchFailure = $null
        $global:TerminalCreateSettingsOnLaunch = $true
        $script:targetDir = Join-Path $TestDrive "Packages\$script:family\LocalState"
        $script:targetFile = Join-Path $script:targetDir 'settings.json'
        $global:TerminalTargetFile = $script:targetFile
        New-Item -ItemType Directory -Path $script:targetDir -Force | Out-Null
        $script:component = . $componentPath
    }

    AfterAll {
        $env:LocalAppData = $script:OriginalLocalAppData
    }

    It 'declares codedir for full setup while targeted runs still require CodeDir to be configured' {
        @($component.DependsOn) -join ',' | Should Be 'codedir'
    }

    It 'detects false when the package is not installed' {
        $global:TerminalPackageInstalled = $false
        & $component.Detect | Should Be $false
    }

    It 'detects false when the package directory is unavailable' {
        $global:TerminalPackageTargetAvailable = $false
        & $component.Detect | Should Be $false
    }

    It 'detects false for missing settings without creating them' {
        & $component.Detect | Should Be $false
        Test-Path $targetFile | Should Be $false
    }

    It 'detects false for empty settings' {
        [IO.File]::WriteAllBytes($targetFile, [byte[]]@())
        & $component.Detect | Should Be $false
    }

    It 'warns and detects false for malformed settings' {
        Write-TerminalUtf8Fixture $targetFile '{"bad":}'
        & $component.Detect | Should Be $false
        $global:TerminalWarnings | Should Be 1
        $global:TerminalWarningMessages[0] | Should Match ([regex]::Escape($targetFile))
        $global:TerminalWarningMessages[0] | Should Match 'Failed to parse JSON'
    }

    It 'detects a compliant settings fixture' {
        Write-TerminalUtf8Fixture $targetFile '{}'
        Update-JsonSettingsFile $targetFile $operationsPath | Out-Null
        & $component.Detect | Should Be $true
    }

    It 'invokes WinGet and applies settings during install' {
        Write-TerminalUtf8Fixture $targetFile '{}'
        & $component.Install
        $global:TerminalInstallCalls | Should Be 1
        Test-JsonSettingsFile $targetFile $operationsPath | Should Be $true
    }

    It 'throws after install when the package target is unavailable and creates no file' {
        $global:TerminalPackageTargetAvailable = $false
        Get-TerminalExceptionMessage { & $component.Install } | Should Match 'package directory was not found'
        Test-Path $targetFile | Should Be $false
    }

    It 'launches Terminal once to initialize missing settings after install' {
        Remove-Item $targetDir -Recurse -Force
        & $component.Install
        $global:TerminalLaunchCalls | Should Be 1
        Test-JsonSettingsFile $targetFile $operationsPath | Should Be $true
    }

    It 'reports an actionable failure when Terminal cannot initialize missing settings' {
        $global:TerminalLaunchFailure = 'synthetic launch failure'
        Get-TerminalExceptionMessage { & $component.Install } |
            Should Match 'could not be initialized automatically.*synthetic launch failure'
        Test-Path $targetFile | Should Be $false
    }

    It 'throws after install for empty settings and leaves them empty' {
        [IO.File]::WriteAllBytes($targetFile, [byte[]]@())
        Get-TerminalExceptionMessage { & $component.Install } | Should Match 'settings.*are empty.*Delete the file'
        $global:TerminalLaunchCalls | Should Be 0
        (Get-Item $targetFile).Length | Should Be 0
    }

    It 'propagates the JSON settings helper failure' {
        Write-TerminalUtf8Fixture $targetFile '{"bad":}'
        Get-TerminalExceptionMessage { & $component.Install } | Should Match 'Failed to parse JSON'
    }

    It 'propagates a WinGet failure without creating settings' {
        $global:TerminalInstallSucceeds = $false
        Get-TerminalExceptionMessage { & $component.Install } | Should Match 'Failed to install Microsoft.WindowsTerminal'
        Test-Path $targetFile | Should Be $false
    }
}

Describe 'Windows Terminal component discovery' {
    It 'keeps JSON settings commands available after Get-AllComponents returns' {
        $syntheticRepo = Join-Path $TestDrive 'synthetic-repo'
        $syntheticComponents = Join-Path $syntheticRepo 'components'
        $syntheticLib = Join-Path $syntheticRepo 'lib'
        New-Item -ItemType Directory -Path $syntheticComponents, $syntheticLib -Force | Out-Null
        Copy-Item $componentPath (Join-Path $syntheticComponents 'windows-terminal.ps1')
        Copy-Item $jsonModulePath (Join-Path $syntheticLib 'JsonSettings.psm1')

        $command = @"
Import-Module '$componentModulePath' -Force -DisableNameChecking
`$loaded = Get-AllComponents '$syntheticComponents'
if (`$loaded.Id -ne 'windows-terminal') { throw 'Component was not loaded.' }
if (-not (Get-Command Test-JsonSettingsFile -ErrorAction SilentlyContinue)) { throw 'Test command is unavailable.' }
if (-not (Get-Command Update-JsonSettingsFile -ErrorAction SilentlyContinue)) { throw 'Update command is unavailable.' }
"@
        & pwsh.exe -NoProfile -NonInteractive -Command $command
        $LASTEXITCODE | Should Be 0
    }
}
