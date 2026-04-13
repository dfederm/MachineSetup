@{
    Name        = "YAML Language Server"
    Description = "Install yaml-language-server for LSP support"
    Category    = "Dev"
    DependsOn   = @("nodejs")
    Detect      = {
        $output = npm list --global yaml-language-server 2>$null
        return $LASTEXITCODE -eq 0
    }
    Install     = {
        npm install --global yaml-language-server > $null
    }
}
