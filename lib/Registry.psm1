Import-Module "$PSScriptRoot\Console.psm1"
Import-Module "$PSScriptRoot\Elevation.psm1"

function Test-RegistryValue()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Path,
        [String] $Name = $null,
        [String] $Data = ""
    )

    $existingValue = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Ignore
    if ($null -eq $existingValue)
    {
        return $false
    }

    if ($Name)
    {
        return $existingValue.$Name -eq $Data
    }
    else
    {
        return $existingValue."(default)" -eq $Data
    }
}

function Set-RegistryValue()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Path,
        [String] $Name = $null,
        [String] $Data = "",
        [Microsoft.Win32.RegistryValueKind] $Type = "String",
        [switch] $Elevate
    )

    $existingValue = Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Ignore
    if ($null -eq $existingValue)
    {
        Write-Debug "Adding registry value [$Path] $Name=$Data"

        if ($Name)
        {
            $CreateBlock = {
                if (-Not (Test-Path -LiteralPath $Path))
                {
                    New-Item -Path "$Path" -Force | Out-Null
                }

                New-ItemProperty -LiteralPath "$Path" -Name "$Name" -PropertyType $Type -Value "$Data" | Out-Null
            }
        }
        else
        {
            $CreateBlock = {
                New-Item -Path "$Path" -Value "$Data" -Force | Out-Null
            }
        }

        if ($Elevate)
        {
            Invoke-Elevated ($ExecutionContext.InvokeCommand.ExpandString($CreateBlock))
        }
        else
        {
            & $CreateBlock
        }

        return $true
    }
    else
    {
        if ($Name)
        {
            $existingData = $existingValue.$Name
        }
        else
        {
            $existingData = $existingValue."(default)"
        }

        if ($existingData -ne $Data)
        {
            Write-Debug "Setting registry [$Path] $Name=$Data (old data $existingData)"

            if ($Name)
            {
                $UpdateBlock = {
                    Set-ItemProperty -LiteralPath "$Path" -Name "$Name" -Value "$Data"
                }
            }
            else
            {
                $UpdateBlock = {
                    New-Item -Path "$Path" -Value "$Data" -Force | Out-Null
                }
            }

            if ($Elevate)
            {
                Invoke-Elevated ($ExecutionContext.InvokeCommand.ExpandString($UpdateBlock))
            }
            else
            {
                & $UpdateBlock
            }

            return $true
        }
        else
        {
            Write-Debug "Registry already set [$Path] $Name=$Data"
            return $false
        }
    }
}
