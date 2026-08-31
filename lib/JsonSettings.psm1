#Requires -Version 7.4

function Parse-JsonNode
{
    param (
        [Parameter(Mandatory)]
        [string] $Text,
        [Parameter(Mandatory)]
        [string] $Source
    )

    try
    {
        $options = [System.Text.Json.JsonDocumentOptions]::new()
        $options.CommentHandling = [System.Text.Json.JsonCommentHandling]::Skip
        $options.AllowTrailingCommas = $true
        return ,([System.Text.Json.Nodes.JsonNode]::Parse($Text, $null, $options))
    }
    catch
    {
        throw "Failed to parse JSON '$Source': $($_.Exception.Message)"
    }
}

function Read-StrictUtf8Text
{
    param (
        [Parameter(Mandatory)]
        [string] $Path
    )

    try
    {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $offset = 0
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        {
            $offset = 3
        }

        $encoding = [System.Text.UTF8Encoding]::new($false, $true)
        return @{
            Bytes = $bytes
            Text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset)
        }
    }
    catch
    {
        throw "Failed to read UTF-8 JSON '$Path': $($_.Exception.Message)"
    }
}

function Get-ByteHash
{
    param (
        [Parameter(Mandatory)]
        [byte[]] $Bytes
    )

    return [Convert]::ToBase64String([System.Security.Cryptography.SHA256]::HashData($Bytes))
}

function Get-FileHashValue
{
    param (
        [Parameter(Mandatory)]
        [string] $Path
    )

    try
    {
        return Get-ByteHash ([System.IO.File]::ReadAllBytes($Path))
    }
    catch
    {
        throw "Failed to re-read JSON '$Path': $($_.Exception.Message)"
    }
}

function Get-JsonTypeName
{
    param (
        [AllowNull()]
        [System.Text.Json.Nodes.JsonNode] $Node
    )

    if ($null -eq $Node) { return "null" }
    if ($Node -is [System.Text.Json.Nodes.JsonObject]) { return "object" }
    if ($Node -is [System.Text.Json.Nodes.JsonArray]) { return "array" }

    $element = $Node.GetValue[System.Text.Json.JsonElement]()
    return $element.ValueKind.ToString().ToLowerInvariant()
}

function Get-JsonString
{
    param (
        [AllowNull()]
        [System.Text.Json.Nodes.JsonNode] $Node,
        [Parameter(Mandatory)]
        [string] $Context
    )

    if ($null -eq $Node)
    {
        throw "$Context must be a string."
    }

    try
    {
        return $Node.GetValue[string]()
    }
    catch
    {
        throw "$Context must be a string."
    }
}

function Copy-JsonNode
{
    param (
        [AllowNull()]
        [System.Text.Json.Nodes.JsonNode] $Node
    )

    if ($null -eq $Node) { return $null }
    return ,$Node.DeepClone()
}

function Test-JsonSelectorMatch
{
    param (
        [AllowNull()]
        [System.Text.Json.Nodes.JsonNode] $Candidate,
        [AllowNull()]
        [System.Text.Json.Nodes.JsonNode] $Selector
    )

    if ($Selector -is [System.Text.Json.Nodes.JsonObject])
    {
        if (-not ($Candidate -is [System.Text.Json.Nodes.JsonObject])) { return $false }
        foreach ($property in $Selector)
        {
            if (-not $Candidate.ContainsKey($property.Key)) { return $false }
            if (-not (Test-JsonSelectorMatch $Candidate[$property.Key] $property.Value)) { return $false }
        }
        return $true
    }

    return [System.Text.Json.Nodes.JsonNode]::DeepEquals($Candidate, $Selector)
}

function Get-JsonPath
{
    param (
        [Parameter(Mandatory)]
        [System.Text.Json.Nodes.JsonArray] $Segments,
        [int] $Count = -1
    )

    if ($Count -lt 0) { $Count = $Segments.Count }
    $result = '$'
    for ($index = 0; $index -lt $Count; $index++)
    {
        $segment = Get-JsonString $Segments[$index] "JSON path segment"
        $result += "[$(ConvertTo-Json $segment -Compress)]"
    }
    return $result
}

function Assert-OnlyJsonMembers
{
    param (
        [Parameter(Mandatory)]
        [System.Text.Json.Nodes.JsonObject] $Object,
        [Parameter(Mandatory)]
        [string[]] $Allowed,
        [Parameter(Mandatory)]
        [string] $Context
    )

    foreach ($property in $Object)
    {
        if ($Allowed -cnotcontains $property.Key)
        {
            throw "$Context contains unsupported member '$($property.Key)'."
        }
    }
}

function Assert-JsonOperationManifest
{
    param (
        [AllowNull()]
        [System.Text.Json.Nodes.JsonNode] $Manifest
    )

    if (-not ($Manifest -is [System.Text.Json.Nodes.JsonObject]))
    {
        throw "Operation manifest root must be an object."
    }

    Assert-OnlyJsonMembers $Manifest @("operations") "Operation manifest"
    if (-not $Manifest.ContainsKey("operations"))
    {
        throw "Operation manifest is missing required member 'operations'."
    }

    $operations = $Manifest["operations"]
    if (-not ($operations -is [System.Text.Json.Nodes.JsonArray]))
    {
        throw "Operation manifest member 'operations' must be an array."
    }

    for ($index = 0; $index -lt $operations.Count; $index++)
    {
        $operation = $operations[$index]
        $context = "Operation $index"
        if (-not ($operation -is [System.Text.Json.Nodes.JsonObject]))
        {
            throw "$context must be an object."
        }
        if (-not $operation.ContainsKey("operation"))
        {
            throw "$context is missing required member 'operation'."
        }
        if (-not $operation.ContainsKey("path"))
        {
            throw "$context is missing required member 'path'."
        }

        $operationName = Get-JsonString $operation["operation"] "$context member 'operation'"
        $path = $operation["path"]
        if (-not ($path -is [System.Text.Json.Nodes.JsonArray]) -or $path.Count -eq 0)
        {
            throw "$context member 'path' must be a non-empty array."
        }
        foreach ($segment in $path)
        {
            $segmentValue = Get-JsonString $segment "$context path segments"
            if ($segmentValue.Length -eq 0)
            {
                throw "$context path segments must be non-empty strings."
            }
        }

        if ($operationName -ceq "set")
        {
            Assert-OnlyJsonMembers $operation @("operation", "path", "value") $context
            if (-not $operation.ContainsKey("value"))
            {
                throw "$context is missing required member 'value'."
            }
        }
        elseif ($operationName -ceq "upsert")
        {
            Assert-OnlyJsonMembers $operation @("operation", "path", "match", "value") $context
            if (-not $operation.ContainsKey("match"))
            {
                throw "$context is missing required member 'match'."
            }
            if (-not $operation.ContainsKey("value"))
            {
                throw "$context is missing required member 'value'."
            }
            if ($operation["match"] -is [System.Text.Json.Nodes.JsonObject] -and
                $operation["match"].Count -eq 0)
            {
                throw "$context member 'match' cannot be an empty object."
            }
            if (-not (Test-JsonSelectorMatch $operation["value"] $operation["match"]))
            {
                throw "$context member 'value' must satisfy its 'match' selector."
            }
        }
        elseif ($operationName -ceq "remove")
        {
            if ($operation.ContainsKey("match"))
            {
                Assert-OnlyJsonMembers $operation @("operation", "path", "match") $context
                if ($operation["match"] -is [System.Text.Json.Nodes.JsonObject] -and
                    $operation["match"].Count -eq 0)
                {
                    throw "$context member 'match' cannot be an empty object."
                }
            }
            else
            {
                Assert-OnlyJsonMembers $operation @("operation", "path") $context
            }
        }
        else
        {
            throw "$context has unsupported operation '$operationName'."
        }
    }
}

function Get-JsonParentForMutation
{
    param (
        [Parameter(Mandatory)]
        [System.Text.Json.Nodes.JsonObject] $Root,
        [Parameter(Mandatory)]
        [System.Text.Json.Nodes.JsonArray] $Path,
        [Parameter(Mandatory)]
        [bool] $CreateMissing,
        [Parameter(Mandatory)]
        [int] $OperationIndex
    )

    $current = $Root
    for ($index = 0; $index -lt ($Path.Count - 1); $index++)
    {
        $segment = Get-JsonString $Path[$index] "Operation $OperationIndex path segment"
        if (-not $current.ContainsKey($segment))
        {
            if (-not $CreateMissing) { return $null }
            $current[$segment] = [System.Text.Json.Nodes.JsonObject]::new()
        }

        $child = $current[$segment]
        if (-not ($child -is [System.Text.Json.Nodes.JsonObject]))
        {
            $jsonPath = Get-JsonPath $Path ($index + 1)
            throw "Operation ${OperationIndex}: JSON path $jsonPath must be an object, but is $(Get-JsonTypeName $child)."
        }
        $current = $child
    }

    return ,$current
}

function Invoke-JsonOperations
{
    param (
        [Parameter(Mandatory)]
        [System.Text.Json.Nodes.JsonObject] $Document,
        [Parameter(Mandatory)]
        [System.Text.Json.Nodes.JsonArray] $Operations
    )

    $result = $Document.DeepClone().AsObject()
    for ($operationIndex = 0; $operationIndex -lt $Operations.Count; $operationIndex++)
    {
        $operation = $Operations[$operationIndex].AsObject()
        $path = $operation["path"].AsArray()
        $operationName = Get-JsonString $operation["operation"] "Operation $operationIndex member 'operation'"
        $createMissing = $operationName -ceq "set" -or $operationName -ceq "upsert"
        $parent = Get-JsonParentForMutation $result $path $createMissing $operationIndex
        if ($null -eq $parent) { continue }

        $targetName = Get-JsonString $path[$path.Count - 1] "Operation $operationIndex path segment"
        if ($operationName -ceq "set")
        {
            $parent[$targetName] = Copy-JsonNode $operation["value"]
            continue
        }

        if ($operationName -ceq "upsert")
        {
            if (-not $parent.ContainsKey($targetName))
            {
                $parent[$targetName] = [System.Text.Json.Nodes.JsonArray]::new()
            }

            $target = $parent[$targetName]
            if (-not ($target -is [System.Text.Json.Nodes.JsonArray]))
            {
                throw "Operation ${operationIndex}: JSON path $(Get-JsonPath $path) must be an array, but is $(Get-JsonTypeName $target)."
            }

            $firstMatch = -1
            for ($itemIndex = 0; $itemIndex -lt $target.Count; $itemIndex++)
            {
                if (Test-JsonSelectorMatch $target[$itemIndex] $operation["match"])
                {
                    if ($firstMatch -lt 0)
                    {
                        $firstMatch = $itemIndex
                        $target[$itemIndex] = Copy-JsonNode $operation["value"]
                    }
                    else
                    {
                        $target.RemoveAt($itemIndex)
                        $itemIndex--
                    }
                }
            }
            if ($firstMatch -lt 0)
            {
                $target.Add((Copy-JsonNode $operation["value"]))
            }
            continue
        }

        if ($operation.ContainsKey("match"))
        {
            if (-not $parent.ContainsKey($targetName)) { continue }
            $target = $parent[$targetName]
            if (-not ($target -is [System.Text.Json.Nodes.JsonArray]))
            {
                throw "Operation ${operationIndex}: JSON path $(Get-JsonPath $path) must be an array, but is $(Get-JsonTypeName $target)."
            }

            for ($itemIndex = $target.Count - 1; $itemIndex -ge 0; $itemIndex--)
            {
                if (Test-JsonSelectorMatch $target[$itemIndex] $operation["match"])
                {
                    $target.RemoveAt($itemIndex)
                }
            }
        }
        else
        {
            [void] $parent.Remove($targetName)
        }
    }

    return ,$result
}

function Read-JsonOperationManifest
{
    param (
        [Parameter(Mandatory)]
        [string] $OperationsPath
    )

    $file = Read-StrictUtf8Text $OperationsPath
    $manifest = Parse-JsonNode $file.Text $OperationsPath
    Assert-JsonOperationManifest $manifest
    return ,$manifest["operations"]
}

function Get-JsonSettingsState
{
    param (
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [System.Text.Json.Nodes.JsonArray] $Operations
    )

    $file = Read-StrictUtf8Text $Path
    $document = Parse-JsonNode $file.Text $Path
    if (-not ($document -is [System.Text.Json.Nodes.JsonObject]))
    {
        throw "JSON settings root '$Path' must be an object, but is $(Get-JsonTypeName $document)."
    }

    $updated = Invoke-JsonOperations $document $Operations
    return @{
        Bytes = $file.Bytes
        Hash = Get-ByteHash $file.Bytes
        Updated = $updated
        Changed = -not [System.Text.Json.Nodes.JsonNode]::DeepEquals($document, $updated)
    }
}

function Test-JsonSettingsFile
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [string] $OperationsPath
    )

    $operations = Read-JsonOperationManifest $OperationsPath
    $state = Get-JsonSettingsState $Path $operations
    return -not $state.Changed
}

function Update-JsonSettingsFile
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [string] $OperationsPath
    )

    $operations = Read-JsonOperationManifest $OperationsPath
    $state = Get-JsonSettingsState $Path $operations
    if (-not $state.Changed) { return $false }

    $options = [System.Text.Json.JsonSerializerOptions]::new()
    $options.WriteIndented = $true
    $json = $state.Updated.ToJsonString($options)
    $encoding = [System.Text.UTF8Encoding]::new($false)
    $bytes = $encoding.GetBytes($json + [Environment]::NewLine)
    $directory = Split-Path $Path -Parent
    $fileName = Split-Path $Path -Leaf
    $temporaryPath = Join-Path $directory ".$fileName.machinesetup.$([Guid]::NewGuid().ToString('N')).tmp"
    $backupPath = "$Path.machinesetup.bak"

    try
    {
        [System.IO.File]::WriteAllBytes($temporaryPath, $bytes)
        if ((Get-FileHashValue $Path) -cne $state.Hash)
        {
            throw "JSON settings '$Path' changed after it was read; retry the operation."
        }

        [System.IO.File]::Replace($temporaryPath, $Path, $backupPath, $true)
        return $true
    }
    finally
    {
        if (Test-Path -LiteralPath $temporaryPath)
        {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

Export-ModuleMember -Function Test-JsonSettingsFile, Update-JsonSettingsFile
