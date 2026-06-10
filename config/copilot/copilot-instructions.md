# General Copilot Instructions

## Source Control
- Do not commit changes unless given explicit instructions to do so by either the user, system instructions, or a skill's instructions.
- **Commit trailers:** Do NOT add a `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer (or any other automated `Co-authored-by` trailer attributing the commit to Copilot) to commit messages. This applies in all repositories and overrides the CLI's built-in default. If a specific repository's instructions explicitly request such a trailer, those take precedence; otherwise omit it.

## Code Style
- When an `.editorconfig`, linter config, or formatter config exists in the project, follow it. Otherwise, follow the standard idiomatic conventions for the language (e.g., Allman-style braces and `IDE0011` "always use braces" for C#, PEP 8 for Python, etc.).

## Comments, commit messages, and PR descriptions — know your audience

These artifacts are read by **other developers** — reviewers and future maintainers who were not part of the session that produced the change and have no knowledge of how it was developed. Write them for that audience, not for the developer you're actively chatting with. The development conversation is the right place for process detail; the code and the PR are not. Useful test before writing any comment or description: *"Would someone seeing only the final code plus this text — with zero session context — find it helpful, or confusing/irrelevant?"*

- **Explain the current state, not its history.** Comment *why the code is the way it is now* — not what it used to be or how it got here. Cut "previously…", "changed from…", "used to…"; the diff and git history already carry that for anyone who wants it.
- **Leave the development process out.** Reviewers don't care that you rebased, resolved conflicts with an already-merged PR, addressed review feedback, or tried an approach that didn't pan out. Only the final proposed change and its rationale belong in the artifact.
- **Don't carry the conversation into the code.** Context that only makes sense within the development session — what "we discussed," internal planning or tracking notes, session/task identifiers, tool or agent names — means nothing to the reader. Keep it out of comments, commit messages, and PR bodies.
- **Be concise.** Comment only what isn't obvious from the code; one clear line beats a paragraph; delete comments that merely restate what the code says.
