$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\JsonSettings.psm1'

function Write-Utf8Fixture
{
    param([string] $Path, [string] $Text)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllBytes($Path, $encoding.GetBytes($Text))
}

function Write-Manifest
{
    param([string] $Path, [string] $Operations)
    Write-Utf8Fixture $Path ('{"operations":[' + $Operations + ']}')
}

function Read-JsonFixture
{
    param([string] $Path)
    $encoding = New-Object System.Text.UTF8Encoding($false, $true)
    $text = $encoding.GetString([IO.File]::ReadAllBytes($Path))
    return ($text | ConvertFrom-Json)
}

function Get-FixtureHash
{
    param([string] $Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return [Convert]::ToBase64String($sha.ComputeHash([IO.File]::ReadAllBytes($Path))) }
    finally { $sha.Dispose() }
}

function Get-ExceptionMessage
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

Describe 'JsonSettings manifest validation' {
    BeforeEach {
        Remove-Module JsonSettings -ErrorAction SilentlyContinue
        Import-Module $modulePath -Force
        $settings = Join-Path $TestDrive 'settings.json'
        $manifest = Join-Path $TestDrive 'operations.json'
        Write-Utf8Fixture $settings '{"items":[]}'
    }

    It 'accepts set, upsert, property-remove, and matched-remove operations' {
        Write-Manifest $manifest @'
{"operation":"set","path":["created"],"value":null},
{"operation":"upsert","path":["items"],"match":{"id":"one"},"value":{"id":"one","value":1}},
{"operation":"remove","path":["obsolete"]},
{"operation":"remove","path":["items"],"match":{"id":"gone"}}
'@
        { Update-JsonSettingsFile $settings $manifest } | Should Not Throw
    }

    $invalidManifests = @(
        @{ Name = 'array manifest root'; Json = '[]'; Message = 'manifest root must be an object' },
        @{ Name = 'manifest extra field'; Json = '{"operations":[],"extra":1}'; Message = "unsupported member 'extra'" },
        @{ Name = 'missing operations'; Json = '{}'; Message = "missing required member 'operations'" },
        @{ Name = 'non-array operations'; Json = '{"operations":{}}'; Message = "'operations' must be an array" },
        @{ Name = 'non-object operation'; Json = '{"operations":[1]}'; Message = 'Operation 0 must be an object' },
        @{ Name = 'missing operation name'; Json = '{"operations":[{"path":["x"],"value":1}]}'; Message = "Operation 0.*'operation'" },
        @{ Name = 'missing path'; Json = '{"operations":[{"operation":"set","value":1}]}'; Message = "Operation 0.*'path'" },
        @{ Name = 'unknown operation'; Json = '{"operations":[{"operation":"merge","path":["x"]}]}'; Message = "Operation 0.*unsupported operation 'merge'" },
        @{ Name = 'empty path'; Json = '{"operations":[{"operation":"remove","path":[]}]}'; Message = 'Operation 0.*non-empty array' },
        @{ Name = 'non-string path segment'; Json = '{"operations":[{"operation":"remove","path":[1]}]}'; Message = 'Operation 0 path segments' },
        @{ Name = 'empty path segment'; Json = '{"operations":[{"operation":"remove","path":[""]}]}'; Message = 'Operation 0 path segments' },
        @{ Name = 'set missing value'; Json = '{"operations":[{"operation":"set","path":["x"]}]}'; Message = "Operation 0.*'value'" },
        @{ Name = 'upsert missing match'; Json = '{"operations":[{"operation":"upsert","path":["x"],"value":1}]}'; Message = "Operation 0.*'match'" },
        @{ Name = 'upsert missing value'; Json = '{"operations":[{"operation":"upsert","path":["x"],"match":1}]}'; Message = "Operation 0.*'value'" },
        @{ Name = 'forbidden set field'; Json = '{"operations":[{"operation":"set","path":["x"],"value":1,"match":1}]}'; Message = "Operation 0.*unsupported member 'match'" },
        @{ Name = 'forbidden remove value'; Json = '{"operations":[{"operation":"remove","path":["x"],"value":1}]}'; Message = "Operation 0.*unsupported member 'value'" },
        @{ Name = 'empty upsert selector'; Json = '{"operations":[{"operation":"upsert","path":["x"],"match":{},"value":{}}]}'; Message = 'Operation 0.*empty object' },
        @{ Name = 'empty remove selector'; Json = '{"operations":[{"operation":"remove","path":["x"],"match":{}}]}'; Message = 'Operation 0.*empty object' },
        @{ Name = 'upsert value mismatch'; Json = '{"operations":[{"operation":"set","path":["ok"],"value":1},{"operation":"upsert","path":["x"],"match":{"id":"a"},"value":{"id":"b"}}]}'; Message = "Operation 1.*must satisfy.*'match'" }
    )

    It 'rejects <Name> with operation-aware diagnostics' -TestCases $invalidManifests {
        param($Name, $Json, $Message)
        Write-Utf8Fixture $manifest $Json
        Get-ExceptionMessage { Test-JsonSettingsFile $settings $manifest } | Should Match $Message
    }
}

Describe 'JsonSettings operation behavior' {
    BeforeEach {
        Remove-Module JsonSettings -ErrorAction SilentlyContinue
        Import-Module $modulePath -Force
        $settings = Join-Path $TestDrive 'settings.json'
        $manifest = Join-Path $TestDrive 'operations.json'
    }

    It 'distinguishes explicit null from a missing member' {
        Write-Utf8Fixture $settings '{}'
        Write-Manifest $manifest '{"operation":"set","path":["present"],"value":null}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        ($json.PSObject.Properties.Name -ccontains 'present') -and ($null -eq $json.present) | Should Be $true
    }

    It 'creates set ancestors while preserving siblings' {
        Write-Utf8Fixture $settings '{"profiles":{"sibling":7},"top":"keep"}'
        Write-Manifest $manifest '{"operation":"set","path":["profiles","defaults","startingDirectory"],"value":"code"}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        @($json.profiles.defaults.startingDirectory, $json.profiles.sibling, $json.top) -join '|' | Should Be 'code|7|keep'
    }

    It 'replaces an existing set property while preserving siblings' {
        Write-Utf8Fixture $settings '{"managed":"old","sibling":{"keep":true}}'
        Write-Manifest $manifest '{"operation":"set","path":["managed"],"value":"new"}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        @($json.managed, $json.sibling.keep) -join '|' | Should Be 'new|True'
    }

    It 'appends an upsert value when no item matches and preserves heterogeneous items' {
        Write-Utf8Fixture $settings '{"items":[1,null,"text",{"id":"other"}]}'
        Write-Manifest $manifest '{"operation":"upsert","path":["items"],"match":{"id":"new"},"value":{"id":"new","v":2}}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        @($json.items).Count | Should Be 5
        $json.items[4].id | Should Be 'new'
    }

    It 'replaces the first upsert match in place and collapses duplicate matches' {
        Write-Utf8Fixture $settings '{"items":[{"id":"x","old":1},{"id":"keep"},{"id":"x","old":2}]}'
        Write-Manifest $manifest '{"operation":"upsert","path":["items"],"match":{"id":"x"},"value":{"id":"x","new":true}}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        @($json.items).Count | Should Be 2
        $json.items[0].new | Should Be $true
        $json.items[1].id | Should Be 'keep'
    }

    It 'uses partial recursive object matching and creates nested upsert ancestors' {
        Write-Utf8Fixture $settings '{"other":1}'
        Write-Manifest $manifest '{"operation":"upsert","path":["nested","bindings"],"match":{"command":{"action":"sendInput"}},"value":{"command":{"action":"sendInput","input":"x"},"keys":"k"}}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        $json.nested.bindings[0].command.input | Should Be 'x'
        $json.other | Should Be 1
    }

    It 'uses object-semantic equality regardless of property order' {
        Write-Utf8Fixture $settings '{"items":[{"id":"x","details":{"first":1,"second":2}}]}'
        Write-Manifest $manifest '{"operation":"remove","path":["items"],"match":{"details":{"second":2,"first":1},"id":"x"}}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        @((Read-JsonFixture $settings).items).Count | Should Be 0
    }

    It 'creates an upsert path using an ancestor created by an earlier operation' {
        Write-Utf8Fixture $settings '{}'
        Write-Manifest $manifest '{"operation":"set","path":["nested","created"],"value":true},{"operation":"upsert","path":["nested","items"],"match":{"id":"x"},"value":{"id":"x"}}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        $json.nested.created | Should Be $true
        $json.nested.items[0].id | Should Be 'x'
    }

    $selectorCases = @(
        @{ Name = 'scalar'; Selector = '"x"'; Value = '"x"'; Existing = '["a","x","x"]'; Remaining = 2 },
        @{ Name = 'array'; Selector = '[1,2]'; Value = '[1,2]'; Existing = '[[2,1],[1,2],[1,2]]'; Remaining = 2 },
        @{ Name = 'null'; Selector = 'null'; Value = 'null'; Existing = '[1,null,null]'; Remaining = 2 }
    )
    It 'supports <Name> selectors' -TestCases $selectorCases {
        param($Name, $Selector, $Value, $Existing, $Remaining)
        Write-Utf8Fixture $settings ('{"items":' + $Existing + '}')
        Write-Manifest $manifest ('{"operation":"upsert","path":["items"],"match":' + $Selector + ',"value":' + $Value + '}')
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        @($json.items).Count | Should Be $Remaining
    }

    It 'matches object members case-sensitively' {
        Write-Utf8Fixture $settings '{"items":[{"Id":"x"},{"id":"x"}]}'
        Write-Manifest $manifest '{"operation":"remove","path":["items"],"match":{"id":"x"}}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        $json.items[0].PSObject.Properties.Name -ccontains 'Id' | Should Be $true
    }

    It 'matches arrays in order' {
        Write-Utf8Fixture $settings '{"items":[[1,2],[2,1]]}'
        Write-Manifest $manifest '{"operation":"remove","path":["items"],"match":[1,2]}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        @($json.items[0]) -join ',' | Should Be '2,1'
    }

    It 'removes a property and all matched array entries' {
        Write-Utf8Fixture $settings '{"obsolete":1,"items":[{"id":"x"},{"id":"y"},{"id":"x"}]}'
        Write-Manifest $manifest '{"operation":"remove","path":["obsolete"]},{"operation":"remove","path":["items"],"match":{"id":"x"}}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        ($json.PSObject.Properties.Name -notcontains 'obsolete') -and (@($json.items).Count -eq 1) -and ($json.items[0].id -eq 'y') | Should Be $true
    }

    $removeSelectorCases = @(
        @{ Name = 'scalar'; Selector = '"x"'; Existing = '["x","keep","x"]'; Expected = 'keep' },
        @{ Name = 'array'; Selector = '[1,2]'; Existing = '[[1,2],[2,1],[1,2]]'; Expected = '2,1' },
        @{ Name = 'null'; Selector = 'null'; Existing = '[null,"keep",null]'; Expected = 'keep' }
    )
    It 'removes all duplicate <Name> selector matches' -TestCases $removeSelectorCases {
        param($Name, $Selector, $Existing, $Expected)
        Write-Utf8Fixture $settings ('{"items":' + $Existing + '}')
        Write-Manifest $manifest ('{"operation":"remove","path":["items"],"match":' + $Selector + '}')
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $remaining = @((Read-JsonFixture $settings).items)
        $remaining.Count | Should Be 1
        if ($Name -eq 'array') {
            @($remaining[0]) -join ',' | Should Be $Expected
        }
        else {
            $remaining[0] | Should Be $Expected
        }
    }

    It 'treats removes below absent ancestors as no-ops' {
        Write-Utf8Fixture $settings '{"keep":1}'
        Write-Manifest $manifest '{"operation":"remove","path":["absent","property"]},{"operation":"remove","path":["alsoAbsent","items"],"match":"x"}'
        Test-JsonSettingsFile $settings $manifest | Should Be $true
    }

    It 'applies overlapping operations in manifest order' {
        Write-Utf8Fixture $settings '{}'
        Write-Manifest $manifest '{"operation":"set","path":["a","b"],"value":1},{"operation":"remove","path":["a","b"]},{"operation":"set","path":["a","c"],"value":2}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        ($json.a.PSObject.Properties.Name -notcontains 'b') -and ($json.a.c -eq 2) | Should Be $true
    }

    It 'reports container conflicts with operation index and path without changing the file' {
        Write-Utf8Fixture $settings '{"a":1}'
        Write-Manifest $manifest '{"operation":"set","path":["ok"],"value":1},{"operation":"set","path":["a","b"],"value":2}'
        $before = [IO.File]::ReadAllBytes($settings)
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Match 'Operation 1.*JSON path.*must be an object'
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($settings)) | Should Be ([Convert]::ToBase64String($before))
    }

    It 'rejects a property remove below an incompatible container' {
        Write-Utf8Fixture $settings '{"a":[]}'
        Write-Manifest $manifest '{"operation":"remove","path":["a","value"]}'
        $before = Get-FixtureHash $settings
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Match 'Operation 0.*JSON path.*must be an object'
        Get-FixtureHash $settings | Should Be $before
    }

    It 'rejects a matched remove whose target is not an array' {
        Write-Utf8Fixture $settings '{"items":{}}'
        Write-Manifest $manifest '{"operation":"remove","path":["items"],"match":{"id":"x"}}'
        $before = Get-FixtureHash $settings
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Match 'Operation 0.*JSON path.*must be an array'
        Get-FixtureHash $settings | Should Be $before
    }

    It 'rejects an array target conflict without changing the file' {
        Write-Utf8Fixture $settings '{"items":{}}'
        Write-Manifest $manifest '{"operation":"upsert","path":["items"],"match":"x","value":"x"}'
        $before = Get-FixtureHash $settings
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Match 'Operation 0.*must be an array'
        Get-FixtureHash $settings | Should Be $before
    }
}

Describe 'JsonSettings file safety and JSONC support' {
    BeforeEach {
        Remove-Module JsonSettings -ErrorAction SilentlyContinue
        Import-Module $modulePath -Force
        $settings = Join-Path $TestDrive 'settings.json'
        $manifest = Join-Path $TestDrive 'operations.json'
        Write-Manifest $manifest '{"operation":"set","path":["managed"],"value":"\u00e9\u03bb"}'
    }

    It 'parses line comments, block comments, and trailing commas while retaining comment-like strings' {
        Write-Utf8Fixture $settings @'
{
  // line
  "url": "https://example.test/a//b",
  "literal": "/* not a comment */",
  /* block */
  "array": [1, 2,],
}
'@
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $json = Read-JsonFixture $settings
        $managedValue = [string][char]0x00e9 + [char]0x03bb
        @($json.url, $json.literal, (@($json.array) -join ','), $json.managed) -join '|' |
            Should Be ('https://example.test/a//b|/* not a comment */|1,2|' + $managedValue)
    }

    It 'retains comment markers following an escaped quote inside a string' {
        Write-Utf8Fixture $settings '{"literal":"quote: \" // keep /* too */"}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        (Read-JsonFixture $settings).literal | Should Be 'quote: " // keep /* too */'
    }

    It 'preserves case-distinct and empty unowned object member names during a managed rewrite' {
        Write-Utf8Fixture $settings '{"name":1,"Name":2,"":3}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $text = Get-Content -LiteralPath $settings -Raw
        $text | Should Match '"name"\s*:\s*1'
        $text | Should Match '"Name"\s*:\s*2'
        $text | Should Match '""\s*:\s*3'
    }

    It 'preserves date-like strings and high-precision numbers during a managed rewrite' {
        Write-Utf8Fixture $settings '{"date":"2024-01-01T00:00:00.123456789+03:00","legacyDate":"\/Date(0)\/","fraction":0.1234567890123456789012345678}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $text = Get-Content -LiteralPath $settings -Raw
        $document = [System.Text.Json.JsonDocument]::Parse($text)
        try {
            $document.RootElement.GetProperty('date').GetString() | Should Be '2024-01-01T00:00:00.123456789+03:00'
            $document.RootElement.GetProperty('legacyDate').GetString() | Should Be '/Date(0)/'
        }
        finally {
            $document.Dispose()
        }
        $text | Should Match '"fraction"\s*:\s*0\.1234567890123456789012345678'
    }

    It 'matches equivalent large integer and exponent selectors' {
        Write-Utf8Fixture $settings '{"items":[100000000000000000000,1e20,1]}'
        Write-Manifest $manifest '{"operation":"upsert","path":["items"],"match":1e20,"value":100000000000000000000}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        @((Read-JsonFixture $settings).items).Count | Should Be 2
    }

    $extendedNumbers = @(
        @{ Name = 'large exponent'; Value = '1e100' },
        @{ Name = 'over-precision fraction'; Value = '0.12345678901234567890123456789' },
        @{ Name = 'small exponent'; Value = '1e-29' }
    )
    It 'preserves an unowned <Name> exactly during a managed rewrite' -TestCases $extendedNumbers {
        param($Name, $Value)
        Write-Utf8Fixture $settings ('{"number":' + $Value + '}')
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        (Get-Content -LiteralPath $settings -Raw) | Should Match ('"number"\s*:\s*' + [regex]::Escape($Value))
    }

    It 'rejects JavaScript syntax outside JSONC' {
        Write-Utf8Fixture $settings "{'value':1}"
        $before = Get-FixtureHash $settings
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Not BeNullOrEmpty
        Get-FixtureHash $settings | Should Be $before
    }

    $badDocuments = @(
        @{ Name = 'malformed JSON'; Text = '{"x":}' },
        @{ Name = 'unterminated string'; Text = '{"x":"oops}' },
        @{ Name = 'unterminated block comment'; Text = '{"x":1/*oops}' },
        @{ Name = 'non-object root'; Text = '[1,2]' }
    )
    It 'leaves <Name> unchanged' -TestCases $badDocuments {
        param($Name, $Text)
        Write-Utf8Fixture $settings $Text
        $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($settings))
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Not BeNullOrEmpty
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($settings)) | Should Be $before
    }

    It 'leaves invalid UTF-8 unchanged' {
        $bytes = [byte[]](0x7B,0x22,0x78,0x22,0x3A,0x22,0xC3,0x28,0x22,0x7D)
        [IO.File]::WriteAllBytes($settings, $bytes)
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Match 'UTF-8'
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($settings)) | Should Be ([Convert]::ToBase64String($bytes))
    }

    It 'writes BOM-less UTF-8 and preserves non-ASCII text' {
        $existingValue = [string][char]0x65e5 + [char]0x672c + [char]0x8a9e
        $managedValue = [string][char]0x00e9 + [char]0x03bb
        Write-Utf8Fixture $settings ('{"existing":"' + $existingValue + '"}')
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        $bytes = [IO.File]::ReadAllBytes($settings)
        (($bytes.Length -lt 3) -or -not ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) | Should Be $true
        $json = Read-JsonFixture $settings
        @($json.existing, $json.managed) -join '|' | Should Be ($existingValue + '|' + $managedValue)
    }

    It 'does not write or change timestamp when already compliant' {
        Write-Utf8Fixture $settings '{"managed":"\u00e9\u03bb","other":1}'
        $stamp = [DateTime]::UtcNow.AddHours(-2)
        [IO.File]::SetLastWriteTimeUtc($settings, $stamp)
        $hash = Get-FixtureHash $settings
        Update-JsonSettingsFile $settings $manifest | Should Be $false
        Get-FixtureHash $settings | Should Be $hash
        [IO.File]::GetLastWriteTimeUtc($settings) | Should Be $stamp
    }

    It 'treats formatting and comments as compliant when owned semantics match' {
        Write-Utf8Fixture $settings @'
{
    // Preserve these bytes when no managed change is needed.
    "other": 1,
    "managed": "\u00e9\u03bb",
}
'@
        $before = [IO.File]::ReadAllBytes($settings)
        Test-JsonSettingsFile $settings $manifest | Should Be $true
        Update-JsonSettingsFile $settings $manifest | Should Be $false
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($settings)) |
            Should Be ([Convert]::ToBase64String($before))
    }

    It 'validates the complete manifest before reading the target file' {
        Write-Utf8Fixture $manifest '{"operations":[{"operation":"set","path":["x"]}]}'
        Remove-Item $settings -ErrorAction SilentlyContinue
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Match "Operation 0.*'value'"
    }

    It 'backs up exact prior bytes and refreshes the backup on a later apply' {
        $first = [Text.Encoding]::UTF8.GetBytes('{"one":1}')
        [IO.File]::WriteAllBytes($settings, $first)
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        [Convert]::ToBase64String([IO.File]::ReadAllBytes("$settings.machinesetup.bak")) |
            Should Be ([Convert]::ToBase64String($first))

        $second = [Text.Encoding]::UTF8.GetBytes('{"one":2}')
        [IO.File]::WriteAllBytes($settings, $second)
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        [Convert]::ToBase64String([IO.File]::ReadAllBytes("$settings.machinesetup.bak")) |
            Should Be ([Convert]::ToBase64String($second))
    }

    It 'cleans invocation temporary files after success and failure' {
        Write-Utf8Fixture $settings '{}'
        Update-JsonSettingsFile $settings $manifest | Should Be $true
        @(Get-ChildItem $TestDrive -Filter '.*.machinesetup.*.tmp').Count | Should Be 0

        Write-Utf8Fixture $settings '{"managed":{}}'
        Write-Manifest $manifest '{"operation":"upsert","path":["managed"],"match":"x","value":"x"}'
        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Not BeNullOrEmpty
        @(Get-ChildItem $TestDrive -Filter '.*.machinesetup.*.tmp').Count | Should Be 0
    }

    It 'fails retryably and keeps newer bytes when the target changes before replacement' {
        Write-Utf8Fixture $settings '{}'
        $global:JsonSettingsConcurrentPath = $settings
        $global:JsonSettingsConcurrentBytes = [Text.Encoding]::UTF8.GetBytes('{"newer":true}')
        Mock Get-FileHashValue {
            [IO.File]::WriteAllBytes($global:JsonSettingsConcurrentPath, $global:JsonSettingsConcurrentBytes)
            return 'concurrent-hash'
        } -ModuleName JsonSettings

        Get-ExceptionMessage { Update-JsonSettingsFile $settings $manifest } | Should Match 'changed after it was read; retry'
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($settings)) |
            Should Be ([Convert]::ToBase64String($global:JsonSettingsConcurrentBytes))
        @(Get-ChildItem $TestDrive -Filter '.*.machinesetup.*.tmp').Count | Should Be 0
        Remove-Variable JsonSettingsConcurrentPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable JsonSettingsConcurrentBytes -Scope Global -ErrorAction SilentlyContinue
    }
}
