$repoRoot = Split-Path $PSScriptRoot -Parent
$hookSource = Join-Path $repoRoot 'config\git\hooks'
$cleanupScript = Join-Path $hookSource 'commit-msg'
$gitRoot = Split-Path (Split-Path (Get-Command git).Source -Parent) -Parent
$perl = Join-Path $gitRoot 'usr\bin\perl.exe'
$componentPath = Join-Path $repoRoot 'components\git-hooks.ps1'
$componentModulePath = Join-Path $repoRoot 'lib\Component.psm1'

function Write-CommitMessage
{
    param ([string] $Path, [string] $Message)

    [System.IO.File]::WriteAllBytes($Path, [System.Text.Encoding]::UTF8.GetBytes($Message))
}

function Invoke-Cleanup
{
    param ([string] $Path)

    & $perl $cleanupScript $Path
    if ($LASTEXITCODE -ne 0) { throw "Commit message cleanup failed: $LASTEXITCODE" }
}

Describe 'Copilot commit trailer cleanup' {
    BeforeEach {
        $messagePath = Join-Path $TestDrive 'COMMIT_EDITMSG'
    }

    It 'removes only Copilot bot trailers and retains human and unrelated trailers' {
        $message = "Subject`n`nCo-authored-by: Alice <alice@example.com>`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`nReviewed-by: Bob <bob@example.com>`nCopilot-Session: 123`n"
        Write-CommitMessage $messagePath $message

        Invoke-Cleanup $messagePath

        [System.IO.File]::ReadAllText($messagePath) | Should Be "Subject`n`nCo-authored-by: Alice <alice@example.com>`nReviewed-by: Bob <bob@example.com>`n"
    }

    It 'preserves UTF-8 content and CRLF while removing an all-Copilot trailer block' {
        $message = "Café`r`n`r`nBody`r`n`r`nCo-authored-by: Copilot <Copilot@users.noreply.github.com>`r`nCopilot-Session: abc`r`n"
        Write-CommitMessage $messagePath $message

        Invoke-Cleanup $messagePath

        ([System.IO.File]::ReadAllBytes($messagePath) -join ',') | Should Be ([System.Text.Encoding]::UTF8.GetBytes("Café`r`n`r`nBody`r`n") -join ',')
    }

    It 'removes Copilot trailers separated into paragraphs without losing human trailers' {
        $message = "Subject`n`nCo-authored-by: Human <human@example.com>`n`nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`n`nCopilot-Session: abc`n"
        Write-CommitMessage $messagePath $message

        Invoke-Cleanup $messagePath

        [System.IO.File]::ReadAllText($messagePath) | Should Be "Subject`n`nCo-authored-by: Human <human@example.com>`n"
    }

    It 'removes trailers before editor template comments without changing the comments' {
        $message = "Subject`n`nCopilot-Session: abc`n`n# Please enter the commit message`n# On branch main`n"
        Write-CommitMessage $messagePath $message

        Invoke-Cleanup $messagePath

        [System.IO.File]::ReadAllText($messagePath) | Should Be "Subject`n`n# Please enter the commit message`n# On branch main`n"
    }

    It 'leaves body mentions and a human named Copilot untouched' {
        $message = "Subject`n`nCopilot-Session: mentioned in the body`nSome prose follows.`n`nCo-authored-by: Copilot <human@example.com>`n"
        Write-CommitMessage $messagePath $message
        $timestamp = (Get-Date).AddDays(-1).ToUniversalTime()
        [System.IO.File]::SetLastWriteTimeUtc($messagePath, $timestamp)
        $originalTimestamp = [System.IO.File]::GetLastWriteTimeUtc($messagePath)

        Invoke-Cleanup $messagePath

        [System.IO.File]::ReadAllText($messagePath) | Should Be $message
        [System.IO.File]::GetLastWriteTimeUtc($messagePath) | Should Be $originalTimestamp
    }

    It 'does not change a matching line that is not a trailer block' {
        $message = "Subject`nCopilot-Session: text in the body`n"
        Write-CommitMessage $messagePath $message

        Invoke-Cleanup $messagePath

        [System.IO.File]::ReadAllText($messagePath) | Should Be $message
    }

    It 'is idempotent after removing repeated bot trailers' {
        Write-CommitMessage $messagePath "Subject`n`nCopilot-Session: first`nCopilot-Session: second`n"

        Invoke-Cleanup $messagePath
        $first = [System.IO.File]::ReadAllBytes($messagePath)
        Invoke-Cleanup $messagePath

        ([System.IO.File]::ReadAllBytes($messagePath) -join ',') | Should Be ($first -join ',')
        [System.IO.File]::ReadAllText($messagePath) | Should Be "Subject`n"
    }
}

Describe 'MachineSetup Git hook installation' {
    BeforeEach {
        $case = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $previousProfile = $env:USERPROFILE
        $previousGlobal = $env:GIT_CONFIG_GLOBAL
        $previousNoSystem = $env:GIT_CONFIG_NOSYSTEM
        $env:USERPROFILE = Join-Path $case 'profile'
        $env:GIT_CONFIG_GLOBAL = Join-Path $case 'gitconfig'
        $env:GIT_CONFIG_NOSYSTEM = '1'
        New-Item -ItemType Directory $env:USERPROFILE -Force | Out-Null
        Import-Module $componentModulePath -Force -DisableNameChecking
        $component = & $componentPath
        $hooksPath = Join-Path $env:USERPROFILE '.config\git\machinesetup-hooks'
        $gitRepo = Join-Path $case 'repository'
    }

    AfterEach {
        $env:USERPROFILE = $previousProfile
        $env:GIT_CONFIG_GLOBAL = $previousGlobal
        $env:GIT_CONFIG_NOSYSTEM = $previousNoSystem
    }

    It 'installs idempotently and repairs configuration or file drift' {
        & $component.Detect | Should Be $false
        & $component.Install
        & $component.Detect | Should Be $true
        git config --global --get core.hooksPath | Should Be $hooksPath

        Set-Content (Join-Path $hooksPath 'commit-msg') 'drift'
        & $component.Detect | Should Be $false
        & $component.Install
        & $component.Detect | Should Be $true

        git config --global core.hooksPath (Join-Path $case 'old-hooks')
        & $component.Detect | Should Be $false
        & $component.Install
        & $component.Detect | Should Be $true
    }

    It 'removes bot trailers from a real commit but keeps a human co-author' {
        & $component.Install
        New-Item -ItemType Directory $gitRepo | Out-Null
        git -C $gitRepo init --quiet

        git -C $gitRepo -c user.name=Fixture -c user.email=fixture@example.com commit --quiet --allow-empty -m Subject -m "Co-authored-by: Human <human@example.com>" -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" -m "Copilot-Session: 123"

        $LASTEXITCODE | Should Be 0
        $commitMessage = git -C $gitRepo log -1 --format=%B | Out-String
        $commitMessage | Should Match 'Co-authored-by: Human <human@example.com>'
        $commitMessage | Should Not Match 'Co-authored-by: Copilot'
        $commitMessage | Should Not Match 'Copilot-Session'
    }

    It 'allows a repository-local hooks path to override global cleanup' {
        & $component.Install
        New-Item -ItemType Directory $gitRepo | Out-Null
        git -C $gitRepo init --quiet
        git -C $gitRepo config --local core.hooksPath (Join-Path $case 'other-hooks')

        git -C $gitRepo -c user.name=Fixture -c user.email=fixture@example.com commit --quiet --allow-empty -m Subject -m 'Copilot-Session: bypass'

        $LASTEXITCODE | Should Be 0
        (git -C $gitRepo log -1 --format=%B | Out-String) | Should Match 'Copilot-Session: bypass'
    }

    It 'removes a trailer in an editor-driven Git commit' {
        & $component.Install
        New-Item -ItemType Directory $gitRepo | Out-Null
        git -C $gitRepo init --quiet
        $previousEditor = $env:GIT_EDITOR

        try
        {
            $env:GIT_EDITOR = ':'
            git -C $gitRepo -c user.name=Fixture -c user.email=fixture@example.com commit --quiet --allow-empty --edit -m Subject -m 'Copilot-Session: editor'

            $LASTEXITCODE | Should Be 0
            (git -C $gitRepo log -1 --format=%B | Out-String) | Should Not Match 'Copilot-Session'
        }
        finally
        {
            $env:GIT_EDITOR = $previousEditor
        }
    }

    It 'removes a trailer before editor comments with a configured comment character' {
        & $component.Install
        New-Item -ItemType Directory $gitRepo | Out-Null
        git -C $gitRepo init --quiet
        $previousEditor = $env:GIT_EDITOR

        try
        {
            $env:GIT_EDITOR = ':'
            git -C $gitRepo -c user.name=Fixture -c user.email=fixture@example.com -c 'core.commentChar=;' commit --quiet --allow-empty --edit -m Subject -m 'Copilot-Session: editor'

            $LASTEXITCODE | Should Be 0
            (git -C $gitRepo log -1 --format=%B | Out-String) | Should Not Match 'Copilot-Session'
        }
        finally
        {
            $env:GIT_EDITOR = $previousEditor
        }
    }

    It 'preserves literal hash lines when Git uses a different comment character' {
        & $component.Install
        New-Item -ItemType Directory $gitRepo | Out-Null
        git -C $gitRepo init --quiet

        git -C $gitRepo -c user.name=Fixture -c user.email=fixture@example.com -c 'core.commentChar=;' commit --quiet --allow-empty --cleanup=verbatim -m Subject -m "Copilot-Session: body text`n# explanation"

        $LASTEXITCODE | Should Be 0
        $message = git -C $gitRepo log -1 --format=%B | Out-String
        $message | Should Match 'Copilot-Session: body text'
        $message | Should Match '# explanation'
    }

    It 'preserves literal hash lines when Git keeps comments verbatim' {
        & $component.Install
        New-Item -ItemType Directory $gitRepo | Out-Null
        git -C $gitRepo init --quiet

        git -C $gitRepo -c user.name=Fixture -c user.email=fixture@example.com commit --quiet --allow-empty --cleanup=verbatim -m Subject -m "Copilot-Session: body text`n# explanation"

        $LASTEXITCODE | Should Be 0
        $message = git -C $gitRepo log -1 --format=%B | Out-String
        $message | Should Match 'Copilot-Session: body text'
        $message | Should Match '# explanation'
    }

    It 'allows --no-verify to bypass the commit-msg hook' {
        & $component.Install
        New-Item -ItemType Directory $gitRepo | Out-Null
        git -C $gitRepo init --quiet

        git -C $gitRepo -c user.name=Fixture -c user.email=fixture@example.com commit --quiet --allow-empty --no-verify -m Subject -m 'Copilot-Session: bypass'

        $LASTEXITCODE | Should Be 0
        (git -C $gitRepo log -1 --format=%B | Out-String) | Should Match 'Copilot-Session: bypass'
    }
}
