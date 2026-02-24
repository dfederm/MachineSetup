---
name: clean-local-branches
description: Clean up local branches which have been merged into the default branch, and optionally rebase unmerged branches.
---

This skill helps the user clean up local branches that have already been merged into the default branch (e.g., `main` or `master`) and optionally rebases branches which have not.

## Step 1: Pre-flight checks

* Check if the user has any uncommitted changes. If so, prompt the user for how to proceed (e.g., stash changes, commit changes, or abort the operation).
* Note the current branch so you can return to it if needed.

## Step 2: Update default branch

* Determine the default branch (e.g., `main` or `master`).
* Checkout the default branch.
* Run `git fetch --prune` to update remote refs and remove stale remote tracking branches.
* Pull the latest changes.

## Step 3: Categorize branches

For each local branch (excluding the default branch and other protected branches like `develop`):

1. **Check if merged**: Use `git merge-tree --write-tree <default> <branch>` to reliably detect both standard and squash merges:
   * Run `git merge-tree --write-tree <default> <branch>`.
   * If the exit code is 0 (no conflicts) AND the output tree hash matches `git rev-parse <default>^{tree}`, the branch's changes are already fully incorporated into the default branch (whether via regular merge, squash merge, or cherry-pick). Mark it as **Merged**.
   * This works because if merging the branch into the default branch would produce the exact same tree, then the branch's changes are already there.
2. **If not merged**: Note the distance from the default branch using `git rev-list --left-right --count <default>...<branch>` (commits ahead/behind).

## Step 4: Present summary and get confirmation

Present the results in a clear table, for example:

```
| Branch          | Status             | Proposed Action |
|-----------------|--------------------|-----------------|
| feature/foo     | Merged             | Delete          |
| feature/bar     | Merged             | Delete          |
| bugfix/baz      | 3 ahead, 0 behind | Keep            |
| experiment/qux  | 12 ahead, 5 behind| Keep            |
```

Ask the user:
1. Confirm which branches to delete.
2. Whether to rebase the unmerged branches onto the default branch.

## Step 5: Execute

* Delete confirmed branches using `git branch -D <branch>`.
* If the user opted in to rebasing, for each unmerged branch:
  * `git checkout <branch>`
  * `git rebase <default-branch>`
  * If there are conflicts, abort the rebase (`git rebase --abort`) and report it.
* Return to the default branch when done.