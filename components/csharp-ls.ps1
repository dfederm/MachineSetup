@{
    Name        = "C# Language Server"
    Description = "Install csharp-ls dotnet global tool for LSP support"
    Category    = "Dev"
    DependsOn   = @("dotnet-sdk")
    Detect      = {
        $output = dotnet tool list --global 2>$null
        return $output -match "csharp-ls"
    }
    Install     = {
        dotnet tool install --global csharp-ls --add-source https://api.nuget.org/v3/index.json --ignore-failed-sources > $null
    }
}
