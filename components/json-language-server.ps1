@{
    Name        = "JSON Language Server"
    Description = "Install vscode-json-language-server for LSP support"
    Category    = "Dev"
    DependsOn   = @("nodejs")
    Detect      = {
        $output = npm list --global vscode-langservers-extracted 2>$null
        return $LASTEXITCODE -eq 0
    }
    Install     = {
        npm install --global vscode-langservers-extracted > $null
    }
}
