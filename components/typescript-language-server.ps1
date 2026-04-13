@{
    Name        = "TypeScript Language Server"
    Description = "Install typescript-language-server for LSP support"
    Category    = "Dev"
    DependsOn   = @("nodejs")
    Detect      = {
        $output = npm list --global typescript-language-server 2>$null
        return $LASTEXITCODE -eq 0
    }
    Install     = {
        npm install --global typescript-language-server > $null
    }
}
