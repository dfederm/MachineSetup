@{
    Name        = "Git Config (Work)"
    Description = "Enable WAM integration for Git (promptless auth)"
    Category    = "Dev"
    Scope       = "work"
    DependsOn   = @("git")
    Detect      = {
        $credType = git config --global --get credential.azreposCredentialType 2>$null
        $useBroker = git config --global --get credential.msauthUseBroker 2>$null
        $useDefault = git config --global --get credential.msauthUseDefaultAccount 2>$null
        return ($credType -eq "oauth") -and ($useBroker -eq "true") -and ($useDefault -eq "true")
    }
    Install     = {
        # See: https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/windows-broker.md
        git config --global credential.azreposCredentialType oauth
        git config --global credential.msauthUseBroker true
        git config --global credential.msauthUseDefaultAccount true
    }
}
