@{
    Name        = "Git"
    Description = "Install Git and configure global settings and aliases"
    Category    = "Dev"
    Detect      = {
        if (-not (Test-WinGetPackage "Git.Git")) { return $false }
        $editor = git config --global --get core.editor 2>$null
        $rebase = git config --global --get pull.rebase 2>$null
        return ($editor -eq "code --wait --new-window") -and ($rebase -eq "true")
    }
    Install     = {
        if (-not (Install-WinGetPackage "Git.Git")) { throw "Failed to install Git.Git" }

        git config --global core.editor "code --wait --new-window"
        git config --global core.autocrlf true
        git config --global core.fscache true
        git config --global core.longpaths true
        git config --global fetch.prune true
        git config --global pull.rebase true
        git config --global push.default current
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved zebra
        git config --global alias.amend "commit --amend --date=now --no-edit"
        git config --global alias.sync "pull --rebase origin main"
    }
}
