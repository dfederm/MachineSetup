Import-Module "$PSScriptRoot\Console.psm1"

function Test-Elevated()
{
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevated()
{
    [CmdletBinding()]
    param (
        [string] $ScriptBlock,
        [hashtable] $Variables
    )

    if (Test-Elevated)
    {
        if ($Variables)
        {
            foreach ($kvp in $Variables.GetEnumerator())
            {
                Set-Variable -Name $kvp.Key -Value $kvp.Value -Scope Local
            }
        }
        return Invoke-Expression $ScriptBlock
    }
    else
    {
        Write-Debug "Requesting elevation"
        $PowershellExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName

        $TempDir = [System.IO.Path]::GetTempPath()
        $TempFileName = [System.IO.Path]::GetRandomFileName() + ".ps1"
        $TempFile = Join-Path $TempDir $TempFileName
        $VarsFile = if ($Variables) { "$TempFile.vars.xml" } else { $null }

        try
        {
            if ($Variables)
            {
                $Variables | Export-Clixml -LiteralPath $VarsFile
                $varsFileEscaped = $VarsFile -replace "'", "''"
                $varsImport = @"
`$__elevatedVars = Import-Clixml -LiteralPath '$varsFileEscaped'
foreach (`$__kvp in `$__elevatedVars.GetEnumerator())
{
    Set-Variable -Name `$__kvp.Key -Value `$__kvp.Value
}
"@
            }
            else
            {
                $varsImport = ""
            }

            $wrapper = @"
$varsImport
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
            if ($VarsFile) { Remove-Item $VarsFile -ErrorAction Ignore }
        }
    }
}
