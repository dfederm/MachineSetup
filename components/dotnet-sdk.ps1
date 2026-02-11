@{
    Name        = ".NET SDK"
    Description = "Install .NET SDK and SlnGen global tool"
    Category    = "Dev"
    Detect      = {
        if (-not (Test-WinGetPackage "Microsoft.DotNet.SDK.10")) { return $false }
        $output = dotnet tool list --global 2>$null
        return $output -match "microsoft.visualstudio.slngen.tool"
    }
    Install     = {
        if (-not (Install-WinGetPackage "Microsoft.DotNet.SDK.10")) { throw "Failed to install Microsoft.DotNet.SDK.10" }

        dotnet tool install --global Microsoft.VisualStudio.SlnGen.Tool --add-source https://api.nuget.org/v3/index.json --ignore-failed-sources > $null
    }
}
