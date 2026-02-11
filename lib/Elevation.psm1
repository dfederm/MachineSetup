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
        return Invoke-Expression $ScriptBlock
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
            $wrapper = @"
`$result = & { $ScriptBlock }
if (`$result) { exit 0 } else { exit 1 }
"@
            Set-Content -Path $TempFile -Value $wrapper
            $proc = Start-Process $PowershellExe -Verb RunAs -ArgumentList "-NoProfile -File `"$TempFile`"" -Wait -PassThru
            return $proc.ExitCode -eq 0
        }
        finally
        {
            Remove-Item $TempFile -ErrorAction Ignore
        }
    }
}
