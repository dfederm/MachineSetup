Import-Module -DisableNameChecking "$PSScriptRoot\Console.psm1"

function Create-RegistryKey()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Path
    )

    $existingKey = Get-Item -Path $Path -ErrorAction Ignore
    if ($existingKey -eq $null)
    {
        Print-Debug "Adding registry key [$Path]"
        New-Item -Path $Path -Name $Name -Force | Out-Null
    }
    else
    {
        Print-Debug "Registry key already exists [$Path]"
    }
}

function Set-RegistryValue()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Path,
        [Parameter(Mandatory)]
        [String] $Name,
        [Parameter(Mandatory)]
        [String] $Data,
        [Parameter(Mandatory)]
        [Microsoft.Win32.RegistryValueKind] $Type
    )

    $existingValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore
    if ($existingValue -eq $null)
    {
        Print-Debug "Adding registry value [$Path] $Name=$Data"
        New-Item -Path $Path -Name $Name -Force | Out-Null
        New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Data | Out-Null
    }
    else
    {
        $existingData = $existingValue.psObject.properties[$Name].Value
        if ($existingData -ne $Data)
        {
            Print-Debug "Setting registry [$Path] $Name=$Data (old data $existingData)"
            Set-ItemProperty -Path $Path -Name $Name -Value $Data
        }
        else
        {
            Print-Debug "Registry already set [$Path] $Name=$Data"
        }
    }
}