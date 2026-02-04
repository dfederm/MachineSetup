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
        Invoke-Expression $ScriptBlock
    }
    else
    {
        Write-Debug "Requesting elevation"
        $PowershellExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName

        $TempDir = [System.IO.Path]::GetTempPath()
        $TempFileName = [System.IO.Path]::GetRandomFileName() + ".ps1"
        $TempFile = Join-Path $TempDir $TempFileName

        try
        {
            Set-Content -Path $TempFile -Value $ScriptBlock
            Start-Process $PowershellExe -Verb RunAs -ArgumentList "-NoProfile -File `"$TempFile`"" -Wait
        }
        finally
        {
            Remove-Item $TempFile -ErrorAction Ignore
        }
    }
}