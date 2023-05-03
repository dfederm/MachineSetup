function Print-Header()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host -ForegroundColor Cyan $Message
}

function Print-Message()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host '  ' -NoNewLine
    Write-Host -ForegroundColor Gray $Message
}

function Print-Debug()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host '    ' -NoNewLine
    Write-Host -ForegroundColor DarkGray $Message
}

function Print-Error()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $Message
    )

    Write-Host '  ' -NoNewLine
    Write-Host -BackgroundColor Red $Message
}