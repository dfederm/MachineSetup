function Write-Header()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host ""
    Write-Host -ForegroundColor Cyan $Message
    Write-Host -ForegroundColor DarkGray ("─" * $Message.Length)
}

function Write-Message()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host "  $Message" -ForegroundColor Gray
}

function Write-Debug()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host "    $Message" -ForegroundColor DarkGray
}

function Write-Success()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host "  ✓ " -ForegroundColor Green -NoNewLine
    Write-Host $Message -ForegroundColor Green
}

function Write-Warning()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host "  ⚠ " -ForegroundColor Yellow -NoNewLine
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Error()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host "  ✗ " -ForegroundColor Red -NoNewLine
    Write-Host $Message -ForegroundColor Red
}
