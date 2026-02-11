Import-Module "$PSScriptRoot\Console.psm1"

function Test-WinGetPackage()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $PackageId
    )

    $output = winget list --id $PackageId --exact --accept-source-agreements 2>$null
    return $LASTEXITCODE -eq 0
}

function Install-WinGetPackage()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $PackageId
    )

    Write-Message "Installing $PackageId via WinGet"
    winget install $PackageId --exact --silent --no-upgrade --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null

    # 0x8A150061 = APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED
    if ($LASTEXITCODE -eq 0)
    {
        Write-Success "$PackageId installed successfully"
        return $true
    }
    elseif ($LASTEXITCODE -eq -1978335135)
    {
        Write-Debug "$PackageId already installed"
        return $true
    }
    else
    {
        Write-Error "Failed to install $PackageId (winget exit code $LASTEXITCODE)"
        return $false
    }
}
