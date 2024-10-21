param (
    [Parameter(Mandatory, Position=0)]
    [string] $Ide,

    [Parameter(Position=1)]
    [string] $SlnFile = $null
)

if (-not $SlnFile)
{
    Write-Host "Looking for existing sln..."
    $SlnFile = Get-ChildItem -Filter "*.sln" -Name | Select-Object -First 1
    if ($SlnFile -ne "")
    {
        Write-Host "Found $SlnFile"

        # Check if it's part of source control. If not, regenerate it.
        & git ls-files --error-unmatch $SlnFile >$null 2>&1
        if ($LastExitCode -ne 0)
        {
            Write-Host "Sln was not part of source control. Running slngen to regenerate it..."
            & slngen --launch false --solutionfile $SlnFile >$null 2>&1
        }
    }
    else
    {
        Write-Host "Did not find a sln. Running slngen to generate sln..."
        & slngen --launch false >$null 2>&1
    }
}
else
{
    if (-not (Test-Path $SlnFile))
    {
        Write-Error "File doesn't exist: $SlnFile"
        Exit 1;
    }
}

Write-Host "Launching: $Ide $SlnFile"
& $Ide $SlnFile
