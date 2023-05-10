Import-Module "$PSScriptRoot\Console.psm1"

function Test-Elevated()
{
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevated()
{
    [CmdletBinding()]
    param (
        [string] $ScriptBlock
    )

    if (Test-Elevated)
    {
        & $ScriptBlock
    }
    else
    {
        Write-Debug "Requesting elevation"
        $PowershellExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        Start-Process $PowershellExe -Verb RunAs -ArgumentList "-Command `"$ScriptBlock`""
    }
}