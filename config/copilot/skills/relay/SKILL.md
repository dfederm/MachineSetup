---
name: relay
description: Relay session work back to the brain repo — summarize PRs, decisions, and discoveries.
---

This skill captures what was accomplished in the current session and writes a structured relay entry
to the brain repo's relay directory for later processing. Run this before closing a task session.

## Step 1: Summarize the session

Review the conversation and work done in this session. Identify:
- **Work done**: What was accomplished (code changes, investigations, fixes)
- **PRs**: Any pull requests created or merged, with full URLs
- **Key decisions**: Architecture choices, design trade-offs, approach selections
- **Discoveries**: Failure modes found, behaviors learned, useful technical details
- **Remaining work**: Anything left undone that should be tracked

## Step 2: Determine PR details

For each PR created or merged in this session:
- Include the full URL
- Include the title
- Include a one-line summary of what it does
- Note the status (sent, merged, abandoned, draft)

If you created PRs during this session, you should have the URLs in your conversation history.
If the user mentioned PRs verbally, include those too.

## Step 3: Write the relay entry

Create the relay directory if it doesn't exist:
```powershell
New-Item -ItemType Directory -Path "$env:CodeDir\brain\relay" -Force | Out-Null
```

Generate a filename with the current timestamp:
```powershell
$timestamp = Get-Date -Format "yyyy-MM-ddTHHmmss"
$relayFile = "$env:CodeDir\brain\relay\relay-$timestamp.md"
```

Write a structured markdown file with this format:

```markdown
# Relay — <brief description of work done>

**Session repo:** <repository name>
**Branch:** <branch name if known>
**Timestamp:** <ISO timestamp>

## Work Done

- <bullet summary of each significant piece of work>

## PRs

- [PR XXXXX](url) — <title> (status: sent/merged/draft)

## Decisions & Discoveries

- <key technical decisions made and why>
- <architecture insights, failure modes, or behaviors discovered>

## Remaining Work

- <anything left undone that should be tracked as a todo or added to an existing todo>

<!-- worktree: <current directory path, if it appears to be a worktree> -->
```

### Worktree detection

To determine if the current directory is a worktree (for the cleanup hint):
```powershell
$gitDir = git rev-parse --git-dir 2>$null
if ($gitDir -match "\.git[\\/]worktrees[\\/]") {
    # This is a worktree — include the cleanup hint with the current directory
    $worktreePath = (Get-Location).Path
}
```

Only include the `<!-- worktree: ... -->` comment if the current directory is a worktree.

## Step 4: Confirm to the user

After writing the relay file, tell the user:
- The relay file was written to `<path>`
- Remind them to process it in their brain session: "Run 'process inbox' in your brain session to file these."

## Notes

- Be thorough but concise — the brain session will enrich entries with API lookups and cross-references.
- Include full PR URLs, not just IDs — the brain session needs them for API lookups.
- If you're unsure whether something is worth including, include it. The brain session will filter.
- The `$env:CodeDir` environment variable points to the code directory (e.g., `C:\Code`).
