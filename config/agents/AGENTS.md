# General Agent Instructions

## Source Control
- Commit only when the user, system or repository instructions, or a skill explicitly call for it.

## Code Style
- When an `.editorconfig`, linter config, or formatter config exists in the project, follow it. Otherwise, follow the standard idiomatic conventions for the language (e.g., Allman-style braces and `IDE0011` "always use braces" for C#, PEP 8 for Python, etc.).

## Comments, commit messages, and PR descriptions

Write these for reviewers and future maintainers who saw none of the session that produced the change. Test: would someone with only the final code and this text find it useful?

- **Default to no comment.** Comment only a non-obvious *why*: a workaround, constraint, subtle invariant, or surprising edge case. Do not restate what code does, annotate obvious lines or standard idioms, or add section-divider or step-narration comments. When in doubt, leave it out; when asked to trim, cut aggressively.
- **Describe the current state, not its history.** Omit "previously…", "changed from…", and "used to…"; Git carries history.
- **Include only the change and its rationale.** Omit development process such as rebases, conflict resolution, review feedback, and abandoned approaches.
- **Omit session context.** What "we discussed", planning or tracking notes, session or task IDs, and tool or agent names mean nothing to readers.
- **Be concise.** One clear line beats a paragraph.
