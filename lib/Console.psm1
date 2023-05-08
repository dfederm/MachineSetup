function Write-Header()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host -ForegroundColor Cyan $Message
}

function Write-Message()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host '  ' -NoNewLine
    Write-Host -ForegroundColor Gray $Message
}

function Write-Debug()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host '    ' -NoNewLine
    Write-Host -ForegroundColor DarkGray $Message
}

function Write-Error()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host '  ' -NoNewLine
    Write-Host -BackgroundColor Red $Message
}