Import-Module -DisableNameChecking "$PSScriptRoot\Console.psm1"

function Set-RegistryValue()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String] $Path,
        [String] $Name = $null,
        [String] $Data = "",
        [Microsoft.Win32.RegistryValueKind] $Type = "String"
    )

    $existingValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore
    if ($existingValue -eq $null)
    {
        Print-Debug "Adding registry value [$Path] $Name=$Data"

        if ($Name)
        {
            New-Item -Path $Path -Name $Name -Force | Out-Null
            New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Data | Out-Null
        }
        else
        {
            New-Item -Path $Path -Value $Data -Force | Out-Null
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
            Print-Debug "Setting registry [$Path] $Name=$Data (old data $existingData)"
            if ($Name)
            {
                Set-ItemProperty -Path $Path -Name $Name -Value $Data
            }
            else
            {
                New-Item -Path $Path -Value $Data -Force | Out-Null
            }

            return $true
        }
        else
        {
            Print-Debug "Registry already set [$Path] $Name=$Data"
            return $false
        }
    }
}