Import-Module "$PSScriptRoot\Console.psm1"
Import-Module "$PSScriptRoot\Environment.psm1"
Import-Module "$PSScriptRoot\Registry.psm1"
Import-Module "$PSScriptRoot\WinGet.psm1"

function Test-FileDeployment()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable[]] $Mappings
    )

    foreach ($mapping in $Mappings)
    {
        $source = $mapping.Source
        $target = $mapping.Target

        if (-not (Test-Path $source)) { return $false }

        if (Test-Path $source -PathType Container)
        {
            $sourceFiles = Get-ChildItem $source -File -Recurse
            foreach ($file in $sourceFiles)
            {
                $relativePath = $file.FullName.Substring($source.Length)
                $targetFile = Join-Path $target $relativePath
                if (-not (Test-Path $targetFile)) { return $false }
                if ((Get-Content $file.FullName -Raw) -ne (Get-Content $targetFile -Raw)) { return $false }
            }
        }
        else
        {
            if (-not (Test-Path $target)) { return $false }
            if ((Get-Content $source -Raw) -ne (Get-Content $target -Raw)) { return $false }
        }
    }
    return $true
}

function Install-FileDeployment()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable[]] $Mappings
    )

    foreach ($mapping in $Mappings)
    {
        $source = $mapping.Source
        $target = $mapping.Target

        if (Test-Path $source -PathType Container)
        {
            if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
            Copy-Item -Path "$source\*" -Destination $target -Recurse -Force
        }
        else
        {
            $targetDir = Split-Path $target -Parent
            if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
            Copy-Item -Path $source -Destination $target -Force
        }
    }
}

function New-WinGetComponent()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Name,
        [Parameter(Mandatory)]
        [String] $PackageId,
        [String] $Scope
    )

    $component = @{
        Name        = $Name
        Description = "Install $Name via WinGet"
        Category    = "Apps"
        Detect      = { Test-WinGetPackage $PackageId }.GetNewClosure()
        Install     = { if (-not (Install-WinGetPackage $PackageId)) { throw "Failed to install $PackageId" } }.GetNewClosure()
    }
    if ($Scope) { $component["Scope"] = $Scope }
    return $component
}

function New-RegistryComponent()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Name,
        [Parameter(Mandatory)]
        [String] $Description,
        [Parameter(Mandatory)]
        [String] $Category,
        [Parameter(Mandatory)]
        [hashtable[]] $Values,
        [switch] $RestartExplorer
    )

    # Determine if any values need elevation
    $needsElevation = $Values | Where-Object { $_.Path -like "HKLM:*" -or $_.Path -like "Registry::HKEY_*" }

    @{
        Name        = $Name
        Description = $Description
        Category    = $Category
        Detect      = {
            foreach ($val in $Values)
            {
                $params = @{ Path = $val.Path }
                if ($val.Name) { $params.Name = $val.Name }
                if ($val.ContainsKey("Data")) { $params.Data = $val.Data }
                if (-not (Test-RegistryValue @params)) { return $false }
            }
            return $true
        }.GetNewClosure()
        Install     = {
            $changed = $false
            foreach ($val in $Values)
            {
                $params = @{ Path = $val.Path }
                if ($val.Name) { $params.Name = $val.Name }
                if ($val.ContainsKey("Data")) { $params.Data = $val.Data }
                if ($val.Type) { $params.Type = $val.Type }
                if ($needsElevation) { $params.Elevate = $true }
                if (Set-RegistryValue @params) { $changed = $true }
            }
            if ($RestartExplorer -and $changed)
            {
                Stop-Process -Name explorer -Force
            }
        }.GetNewClosure()
    }
}

function Get-AllComponents()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $ComponentsDir
    )

    $components = @()
    $files = Get-ChildItem -Path $ComponentsDir -Filter "*.ps1" | Sort-Object Name

    foreach ($file in $files)
    {
        $componentId = $file.BaseName
        try
        {
            $component = & $file.FullName
            $component["Id"] = $componentId
            $component["FilePath"] = $file.FullName
            if (-not $component.ContainsKey("DependsOn")) { $component["DependsOn"] = @() }
            $components += $component
        }
        catch
        {
            Write-Error "Failed to load component '$componentId': $_"
        }
    }

    return $components
}

function Sort-ComponentsByDependency()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [hashtable[]] $Components
    )

    $lookup = @{}
    foreach ($c in $Components) { $lookup[$c.Id] = $c }

    $sorted = [System.Collections.ArrayList]::new()
    $visited = @{}

    # Iterative topological sort using a stack
    foreach ($c in $Components)
    {
        if ($visited.ContainsKey($c.Id)) { continue }

        $stack = [System.Collections.Stack]::new()
        $stack.Push(@{ Component = $c; DepIndex = 0 })

        while ($stack.Count -gt 0)
        {
            $frame = $stack.Peek()
            $comp = $frame.Component

            if (-not $visited.ContainsKey($comp.Id))
            {
                $visited[$comp.Id] = 'visiting'
            }

            $deps = $comp.DependsOn
            $allDepsProcessed = $true

            while ($frame.DepIndex -lt $deps.Count)
            {
                $depId = $deps[$frame.DepIndex]
                $frame.DepIndex++

                if (-not $lookup.ContainsKey($depId)) { continue }
                if ($visited[$depId] -eq 'done') { continue }
                if ($visited[$depId] -eq 'visiting')
                {
                    throw "Circular dependency detected involving '$depId'"
                }

                $stack.Push(@{ Component = $lookup[$depId]; DepIndex = 0 })
                $allDepsProcessed = $false
                break
            }

            if ($allDepsProcessed)
            {
                $stack.Pop() > $null
                $visited[$comp.Id] = 'done'
                $sorted.Add($comp) > $null
            }
        }
    }

    return $sorted.ToArray()
}

function Invoke-ComponentDetect()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [hashtable] $Component
    )

    try
    {
        $result = & $Component.Detect
        return [bool]$result
    }
    catch
    {
        Write-Debug "Detect failed for '$($Component.Name)': $_"
        return $null
    }
}

function Invoke-ComponentInstall()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [hashtable] $Component
    )

    Write-Header "Installing: $($Component.Name)"
    try
    {
        & $Component.Install
        # Refresh PATH so subsequent components see any new entries (e.g. from WinGet installs)
        Update-PathVariable
        Write-Success "$($Component.Name) completed"
        return $true
    }
    catch
    {
        Write-Error "$($Component.Name) failed: $_"
        return $false
    }
}
