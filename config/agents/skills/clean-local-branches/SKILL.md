---
name: clean-local-branches
description: Clean up local branches which have been merged into the default branch, and rebase unmerged branches.
---

This skill helps the user clean up local branches that have already been merged into the default branch (e.g., `main` or `master`) and rebases branches which have not.

## Step 1: Pre-flight checks

* Check if the user has any uncommitted changes. If so, prompt the user for how to proceed (e.g., stash changes, commit changes, or abort the operation).
* Note the current branch so you can return to it if needed.

## Step 2: Update default branch

* Determine the default branch (e.g., `main` or `master`).
* Checkout the default branch.
* Run `git fetch --prune` to update remote refs and remove stale remote tracking branches.
* Pull the latest changes.

## Step 3: Rebase all branches and identify merged ones

For each local branch (excluding the default branch and other protected branches like `develop`):

1. `git checkout <branch>`
2. `git rebase <default>`
3. If there are conflicts, abort the rebase (`git rebase --abort`) and note the branch as **Conflict**.
4. After a successful rebase, compare the branch tip to the default branch tip (`git rev-parse HEAD` vs `git rev-parse <default>`). If they match, the branch is **Merged** — all its commits were already applied, so rebase dropped them and the tip landed on the default branch. Otherwise, the branch is **Rebased** (it has commits on top of the default branch).

Also note whether each branch has a remote tracking branch (i.e. `origin/<branch>` exists). This information is needed in Step 5.

Return to the default branch when done.

This approach reliably detects standard merges, squash merges, and cherry-picks, because rebase drops commits whose changes are already present in the default branch. As a bonus, unmerged branches get rebased onto the latest default branch.

## Step 4: Present summary and get confirmation

Present the results in a clear table, for example:

```
| Branch          | Status   | Proposed Action |
|-----------------|----------|-----------------|
| feature/foo     | Merged   | Delete (local + remote) |
| feature/bar     | Merged   | Delete (local only)     |
| bugfix/baz      | Rebased  | Force push              |
| experiment/qux  | Rebased  | Keep (no remote)        |
| hotfix/abc      | Conflict | Keep (needs manual resolution) |
```

Ask the user to confirm which merged branches to delete.

## Step 5: Execute

* **Merged branches**: Delete confirmed branches locally using `git branch -D <branch>`. If the branch also exists on the remote, delete it with `git push origin --delete <branch>`.
* **Rebased branches**: If the branch exists on the remote, force push with `git push --force-with-lease origin <branch>`. If it does not exist on the remote, do nothing (do not push).
* Report any branches that had conflicts and need manual attention.