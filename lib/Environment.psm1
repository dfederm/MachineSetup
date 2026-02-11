Import-Module "$PSScriptRoot\Console.psm1"

function Set-EnvironmentVariable()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Name,
        [Parameter(Position = 1, Mandatory)]
        [String] $Value
    )

    $existingValue = [Environment]::GetEnvironmentVariable($Name, "User")
    if ($existingValue -eq $Value)
    {
        Write-Debug "$Name already set to $Value"
    }
    else
    {
        Write-Debug "Setting $Name=$Value"
        [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
        [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    }
}

function Add-PathVariable()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Path
    )

    if (Test-Path $Path)
    {
        # Normalize
        $Path = $Path.TrimEnd('\');

        $existingPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $regex = "^$([regex]::Escape($Path))\\?"
        $matchingPath = $existingPath -split ';' | Where-Object { $_ -Match $regex }
        if ($matchingPath)
        {
            Write-Debug "$Path is already on the Path"
        }
        else
        {
            Write-Debug "Adding $Path to the Path"
            [Environment]::SetEnvironmentVariable("Path", "$existingPath;$Path", "User")
            Update-PathVariable
        }
    }
    else
    {
        Throw "'$Path' does not exist."
    }
}

function Update-PathVariable()
{
    $Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    [Environment]::SetEnvironmentVariable("Path", $Path, "Process")
}
